function [dwellTime_s, info] = calculate_adaptive_dwell_time( ...
    priorityScore, ...
    uncertaintyScore, ...
    mode, ...
    cfg)
%CALCULATE_ADAPTIVE_DWELL_TIME Calculate adaptive receiver dwell time.
%
% AVOLITE Golden Reference
%
% Inputs:
%   priorityScore      : priority score [0,1]
%   uncertaintyScore   : uncertainty score [0,1]
%   mode               : EXPLORE / EXPLOIT / BALANCED
%   cfg                : AVOLITE configuration
%
% Output:
%   dwellTime_s : selected dwell time [s]
%   info        : dwell-time diagnostics
%
% Baseline design:
%   EXPLOIT   -> longer dwell for important known emitters
%   EXPLORE   -> shorter dwell to cover more frequencies
%   BALANCED  -> intermediate adaptive dwell
%
% The result is always constrained to:
%
%   minimumDwellTime_s <= dwellTime_s <= maximumDwellTime_s

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(priorityScore) || ...
        ~isscalar(priorityScore) || ...
        ~isreal(priorityScore) || ...
        ~isfinite(priorityScore)

    error( ...
        'calculate_adaptive_dwell_time:InvalidPriority', ...
        'priorityScore must be a finite real numeric scalar.');

end

if ~isnumeric(uncertaintyScore) || ...
        ~isscalar(uncertaintyScore) || ...
        ~isreal(uncertaintyScore) || ...
        ~isfinite(uncertaintyScore)

    error( ...
        'calculate_adaptive_dwell_time:InvalidUncertainty', ...
        'uncertaintyScore must be a finite real numeric scalar.');

end

if priorityScore < 0 || priorityScore > 1

    error( ...
        'calculate_adaptive_dwell_time:PriorityOutOfRange', ...
        'priorityScore must be in [0,1].');

end

if uncertaintyScore < 0 || uncertaintyScore > 1

    error( ...
        'calculate_adaptive_dwell_time:UncertaintyOutOfRange', ...
        'uncertaintyScore must be in [0,1].');

end

if ~(mode == "EXPLORE" || ...
        mode == "EXPLOIT" || ...
        mode == "BALANCED")

    error( ...
        'calculate_adaptive_dwell_time:InvalidMode', ...
        'mode must be EXPLORE, EXPLOIT, or BALANCED.');

end

if ~isstruct(cfg)

    error( ...
        'calculate_adaptive_dwell_time:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% REQUIRED SCHEDULER CONFIGURATION
% =============================================================

requiredFields = { ...
    'defaultDwellTime_s'
    'minimumDwellTime_s'
    'maximumDwellTime_s'};

for k = 1:numel(requiredFields)

    fieldName = requiredFields{k};

    if ~isfield(cfg.scheduler,fieldName)

        error( ...
            'calculate_adaptive_dwell_time:MissingConfiguration', ...
            'Missing scheduler configuration field: %s', ...
            fieldName);

    end

end

%% ============================================================
% READ CONFIGURATION
% =============================================================

defaultDwellTime_s = ...
    cfg.scheduler.defaultDwellTime_s;

minimumDwellTime_s = ...
    cfg.scheduler.minimumDwellTime_s;

maximumDwellTime_s = ...
    cfg.scheduler.maximumDwellTime_s;

%% ============================================================
% CONFIGURATION VALIDATION
% =============================================================

dwellConfiguration = [ ...
    defaultDwellTime_s
    minimumDwellTime_s
    maximumDwellTime_s];

if any(~isfinite(dwellConfiguration)) || ...
        any(dwellConfiguration <= 0)

    error( ...
        'calculate_adaptive_dwell_time:InvalidDwellConfiguration', ...
        'Dwell-time configuration values must be positive and finite.');

end

if minimumDwellTime_s > maximumDwellTime_s

    error( ...
        'calculate_adaptive_dwell_time:InvalidDwellLimits', ...
        'Minimum dwell time cannot exceed maximum dwell time.');

end

if defaultDwellTime_s < minimumDwellTime_s || ...
        defaultDwellTime_s > maximumDwellTime_s

    error( ...
        'calculate_adaptive_dwell_time:DefaultDwellOutOfRange', ...
        'Default dwell time must lie between minimum and maximum.');

end

%% ============================================================
% NORMALIZED DEFAULT POSITION
% ============================================================

defaultPosition = ...
    (defaultDwellTime_s - minimumDwellTime_s) / ...
    (maximumDwellTime_s - minimumDwellTime_s);

%% ============================================================
% MODE-DEPENDENT DWELL POSITION
% ============================================================

switch mode

    case "EXPLOIT"

        % Important known emitters receive longer observation.

        dwellPosition = ...
            defaultPosition + ...
            0.40 .* priorityScore;

        % High uncertainty slightly reduces exploitation dwell.

        dwellPosition = ...
            dwellPosition - ...
            0.10 .* uncertaintyScore;

    case "EXPLORE"

        % Exploration favors shorter dwell to scan more candidates.

        dwellPosition = ...
            defaultPosition - ...
            0.40 .* uncertaintyScore;

        % High priority prevents dwell from becoming unnecessarily
        % short even during exploration.

        dwellPosition = ...
            dwellPosition + ...
            0.15 .* priorityScore;

    case "BALANCED"

        dwellPosition = ...
            defaultPosition + ...
            0.20 .* priorityScore - ...
            0.10 .* uncertaintyScore;

end

%% ============================================================
% CLAMP NORMALIZED POSITION
% =============================================================

dwellPosition = ...
    min(max(dwellPosition,0),1);

%% ============================================================
% CONVERT TO PHYSICAL DWELL TIME
% =============================================================

dwellTime_s = ...
    minimumDwellTime_s + ...
    dwellPosition .* ...
    (maximumDwellTime_s - minimumDwellTime_s);

%% ============================================================
% FINAL PHYSICAL LIMIT
% =============================================================

dwellTime_s = ...
    min(max( ...
        dwellTime_s, ...
        minimumDwellTime_s), ...
        maximumDwellTime_s);

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.priorityScore = ...
    priorityScore;

info.uncertaintyScore = ...
    uncertaintyScore;

info.mode = ...
    mode;

info.defaultDwellTime_s = ...
    defaultDwellTime_s;

info.minimumDwellTime_s = ...
    minimumDwellTime_s;

info.maximumDwellTime_s = ...
    maximumDwellTime_s;

info.defaultPosition = ...
    defaultPosition;

info.dwellPosition = ...
    dwellPosition;

info.dwellTime_s = ...
    dwellTime_s;

info.method = ...
    "deterministic_adaptive_dwell";

end