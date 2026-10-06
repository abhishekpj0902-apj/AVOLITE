function [receiverConfig, info] = calculate_adaptive_receiver_config( ...
    priorityScore, ...
    uncertaintyScore, ...
    mode, ...
    cfg)
%CALCULATE_ADAPTIVE_RECEIVER_CONFIG Select adaptive receiver settings.
%
% AVOLITE Golden Reference
%
% Inputs:
%   priorityScore    : emitter priority [0,1]
%   uncertaintyScore : emitter uncertainty [0,1]
%   mode             : EXPLORE / EXPLOIT / BALANCED
%   cfg              : AVOLITE configuration
%
% Outputs:
%   receiverConfig   : selected receiver configuration
%   info             : calculation diagnostics
%
% Baseline policy:
%   EXPLOIT   -> higher gain, narrower bandwidth
%   EXPLORE   -> lower gain, wider bandwidth
%   BALANCED  -> intermediate configuration
%
% Receiver limits are taken from the existing AVOLITE configuration.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(priorityScore) || ...
        ~isscalar(priorityScore) || ...
        ~isreal(priorityScore) || ...
        ~isfinite(priorityScore)

    error( ...
        'calculate_adaptive_receiver_config:InvalidPriority', ...
        'priorityScore must be a finite real numeric scalar.');

end

if ~isnumeric(uncertaintyScore) || ...
        ~isscalar(uncertaintyScore) || ...
        ~isreal(uncertaintyScore) || ...
        ~isfinite(uncertaintyScore)

    error( ...
        'calculate_adaptive_receiver_config:InvalidUncertainty', ...
        'uncertaintyScore must be a finite real numeric scalar.');

end

if priorityScore < 0 || priorityScore > 1

    error( ...
        'calculate_adaptive_receiver_config:PriorityOutOfRange', ...
        'priorityScore must be in [0,1].');

end

if uncertaintyScore < 0 || uncertaintyScore > 1

    error( ...
        'calculate_adaptive_receiver_config:UncertaintyOutOfRange', ...
        'uncertaintyScore must be in [0,1].');

end

if ~(mode == "EXPLORE" || ...
        mode == "EXPLOIT" || ...
        mode == "BALANCED")

    error( ...
        'calculate_adaptive_receiver_config:InvalidMode', ...
        'mode must be EXPLORE, EXPLOIT, or BALANCED.');

end

if ~isstruct(cfg)

    error( ...
        'calculate_adaptive_receiver_config:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% REQUIRED CONFIGURATION
% =============================================================

requiredFields = { ...
    'gain_dB'
    'rfFilterBandwidth_Hz'
    'ifFilterBandwidth_Hz'};

for k = 1:numel(requiredFields)

    fieldName = requiredFields{k};

    if ~isfield(cfg.receiver,fieldName)

        error( ...
            'calculate_adaptive_receiver_config:MissingConfiguration', ...
            'Missing receiver configuration field: %s', ...
            fieldName);

    end

end

%% ============================================================
% BASELINE LIMITS
% ============================================================
%
% These limits are scheduler design limits, not additional
% project requirements.

baseGain_dB = cfg.receiver.gain_dB;

baseRFBandwidth_Hz = ...
    cfg.receiver.rfFilterBandwidth_Hz;

baseIFBandwidth_Hz = ...
    cfg.receiver.ifFilterBandwidth_Hz;

minimumGain_dB = max(0,baseGain_dB - 20);
maximumGain_dB = baseGain_dB + 20;

minimumRFBandwidth_Hz = ...
    max(1,baseRFBandwidth_Hz / 4);

maximumRFBandwidth_Hz = ...
    baseRFBandwidth_Hz * 2;

minimumIFBandwidth_Hz = ...
    max(1,baseIFBandwidth_Hz / 4);

maximumIFBandwidth_Hz = ...
    baseIFBandwidth_Hz * 2;

%% ============================================================
% MODE-DEPENDENT NORMALIZED SETTINGS
% ============================================================

switch mode

    case "EXPLOIT"

        % High priority encourages gain.
        % Low uncertainty permits narrower filtering.

        gainPosition = ...
            0.50 + ...
            0.50 * priorityScore;

        bandwidthPosition = ...
            0.50 - ...
            0.40 * (1 - uncertaintyScore);

        receiverMode = "TRACK";

    case "EXPLORE"

        % Exploration favors wider bandwidth and moderate gain.

        gainPosition = ...
            0.50 - ...
            0.30 * uncertaintyScore + ...
            0.10 * priorityScore;

        bandwidthPosition = ...
            0.50 + ...
            0.50 * uncertaintyScore;

        receiverMode = "SEARCH";

    case "BALANCED"

        gainPosition = ...
            0.50 + ...
            0.25 * priorityScore - ...
            0.10 * uncertaintyScore;

        bandwidthPosition = ...
            0.50 + ...
            0.20 * uncertaintyScore - ...
            0.10 * priorityScore;

        receiverMode = "ADAPTIVE";

end

%% ============================================================
% CLAMP NORMALIZED SETTINGS
% =============================================================

gainPosition = ...
    min(max(gainPosition,0),1);

bandwidthPosition = ...
    min(max(bandwidthPosition,0),1);

%% ============================================================
% MAP TO PHYSICAL SETTINGS
% =============================================================

gain_dB = ...
    minimumGain_dB + ...
    gainPosition * ...
    (maximumGain_dB - minimumGain_dB);

rfFilterBandwidth_Hz = ...
    minimumRFBandwidth_Hz + ...
    bandwidthPosition * ...
    (maximumRFBandwidth_Hz - minimumRFBandwidth_Hz);

% Keep IF bandwidth coupled to RF bandwidth while remaining
% within the configured scheduler limits.

bandwidthRatio = ...
    baseIFBandwidth_Hz / baseRFBandwidth_Hz;

if ~isfinite(bandwidthRatio) || bandwidthRatio <= 0

    bandwidthRatio = 0.5;

end

ifBandwidth_Hz = ...
    rfFilterBandwidth_Hz * bandwidthRatio;

ifBandwidth_Hz = ...
    min(max( ...
        ifBandwidth_Hz, ...
        minimumIFBandwidth_Hz), ...
        maximumIFBandwidth_Hz);

%% ============================================================
% FINAL SAFETY LIMITS
% =============================================================

gain_dB = ...
    min(max(gain_dB,minimumGain_dB),maximumGain_dB);

rfFilterBandwidth_Hz = ...
    min(max( ...
        rfFilterBandwidth_Hz, ...
        minimumRFBandwidth_Hz), ...
        maximumRFBandwidth_Hz);

ifBandwidth_Hz = ...
    min(max( ...
        ifBandwidth_Hz, ...
        minimumIFBandwidth_Hz), ...
        maximumIFBandwidth_Hz);

%% ============================================================
% OUTPUT STRUCTURE
% =============================================================

receiverConfig = struct();

receiverConfig.gain_dB = ...
    gain_dB;

receiverConfig.rfFilterBandwidth_Hz = ...
    rfFilterBandwidth_Hz;

receiverConfig.ifFilterBandwidth_Hz = ...
    ifBandwidth_Hz;

receiverConfig.mode = ...
    receiverMode;

%% ============================================================
% DIAGNOSTICS
% ============================================================

info = struct();

info.priorityScore = ...
    priorityScore;

info.uncertaintyScore = ...
    uncertaintyScore;

info.schedulerMode = ...
    mode;

info.gainPosition = ...
    gainPosition;

info.bandwidthPosition = ...
    bandwidthPosition;

info.minimumGain_dB = ...
    minimumGain_dB;

info.maximumGain_dB = ...
    maximumGain_dB;

info.minimumRFBandwidth_Hz = ...
    minimumRFBandwidth_Hz;

info.maximumRFBandwidth_Hz = ...
    maximumRFBandwidth_Hz;

info.minimumIFBandwidth_Hz = ...
    minimumIFBandwidth_Hz;

info.maximumIFBandwidth_Hz = ...
    maximumIFBandwidth_Hz;

info.method = ...
    "deterministic_adaptive_receiver_configuration";

end