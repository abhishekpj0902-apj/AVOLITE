function [detection, info] = apply_cfar_detection( ...
    spectrum, cfg)
%APPLY_CFAR_DETECTION CA-CFAR detection on FFT spectrum.
%
% AVOLITE Golden Reference
%
% Inputs:
%   spectrum : output structure from compute_fft_spectrum()
%   cfg      : AVOLITE configuration
%
% Outputs:
%   detection : detection results
%   info      : detector diagnostics
%
% Processing:
%
%   FFT magnitude
%       |
%       v
%   CA-CFAR noise estimation
%       |
%       v
%   Detection threshold
%       |
%       v
%   Detection mask
%
% CA-CFAR is applied independently to each valid FFT cell.
%
% Configuration:
%
%   cfg.detection.probabilityOfFalseAlarm
%   cfg.detection.referenceCells
%   cfg.detection.guardCells
%
% The FFT spectrum is assumed to contain:
%
%   spectrum.magnitude
%   spectrum.frequency_Hz

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isstruct(spectrum)

    error( ...
        'apply_cfar_detection:InvalidSpectrum', ...
        'spectrum must be a structure.');

end

if ~isfield(spectrum,'magnitude')

    error( ...
        'apply_cfar_detection:MissingMagnitude', ...
        'spectrum.magnitude is missing.');

end

if ~isfield(spectrum,'frequency_Hz')

    error( ...
        'apply_cfar_detection:MissingFrequency', ...
        'spectrum.frequency_Hz is missing.');

end

if ~isnumeric(spectrum.magnitude) || ...
        isempty(spectrum.magnitude)

    error( ...
        'apply_cfar_detection:InvalidMagnitude', ...
        'spectrum.magnitude must be a non-empty numeric array.');

end

if ~isnumeric(spectrum.frequency_Hz) || ...
        isempty(spectrum.frequency_Hz)

    error( ...
        'apply_cfar_detection:InvalidFrequency', ...
        'spectrum.frequency_Hz must be a non-empty numeric array.');

end

%% ============================================================
% CONFIGURATION VALIDATION
% =============================================================

if ~isstruct(cfg)

    error( ...
        'apply_cfar_detection:InvalidConfiguration', ...
        'cfg must be a structure.');

end

if ~isfield(cfg,'detection') || ...
        ~isstruct(cfg.detection)

    error( ...
        'apply_cfar_detection:MissingConfiguration', ...
        'Detection configuration is missing.');

end

detCfg = cfg.detection;

%% ============================================================
% PROBABILITY OF FALSE ALARM
% =============================================================

if ~isfield(detCfg,'probabilityOfFalseAlarm')

    error( ...
        'apply_cfar_detection:MissingPFA', ...
        'Probability of false alarm is missing.');

end

Pfa = detCfg.probabilityOfFalseAlarm;

if ~isscalar(Pfa) || ...
        ~isnumeric(Pfa) || ...
        ~isfinite(Pfa) || ...
        Pfa <= 0 || ...
        Pfa >= 1

    error( ...
        'apply_cfar_detection:InvalidPFA', ...
        'Probability of false alarm must be between zero and one.');

end

%% ============================================================
% REFERENCE CELLS
% =============================================================

if ~isfield(detCfg,'referenceCells')

    error( ...
        'apply_cfar_detection:MissingReferenceCells', ...
        'Reference-cell configuration is missing.');

end

referenceCells = detCfg.referenceCells;

if ~isscalar(referenceCells) || ...
        ~isnumeric(referenceCells) || ...
        ~isfinite(referenceCells) || ...
        referenceCells < 1 || ...
        referenceCells ~= floor(referenceCells)

    error( ...
        'apply_cfar_detection:InvalidReferenceCells', ...
        'Reference-cell count must be a positive integer.');

end

%% ============================================================
% GUARD CELLS
% =============================================================

if ~isfield(detCfg,'guardCells')

    error( ...
        'apply_cfar_detection:MissingGuardCells', ...
        'Guard-cell configuration is missing.');

end

guardCells = detCfg.guardCells;

if ~isscalar(guardCells) || ...
        ~isnumeric(guardCells) || ...
        ~isfinite(guardCells) || ...
        guardCells < 0 || ...
        guardCells ~= floor(guardCells)

    error( ...
        'apply_cfar_detection:InvalidGuardCells', ...
        'Guard-cell count must be a non-negative integer.');

end

%% ============================================================
% SPECTRUM VECTOR
% ============================================================

magnitude = spectrum.magnitude(:);

frequency_Hz = spectrum.frequency_Hz(:);

N = numel(magnitude);

if numel(frequency_Hz) ~= N

    error( ...
        'apply_cfar_detection:SizeMismatch', ...
        'Magnitude and frequency vectors must have equal length.');

end

%% ============================================================
% CA-CFAR PARAMETERS
% ============================================================
%
% Two-sided reference cells:
%
%   left  = referenceCells
%   right = referenceCells
%
% Total reference cells:
%
%   Nref = 2 * referenceCells
%
% For exponentially distributed noise power, the
% CA-CFAR threshold scaling factor is:
%
%   alpha = Nref * (Pfa^(-1/Nref) - 1)
%
% The detector operates on POWER, not amplitude.

Nref = 2 * referenceCells;

alpha = ...
    Nref * ...
    (Pfa^(-1/Nref) - 1);

%% ============================================================
% PREALLOCATE
% =============================================================

noisePowerEstimate = ...
    nan(N,1);

thresholdPower = ...
    nan(N,1);

thresholdMagnitude = ...
    nan(N,1);

detectionMask = ...
    false(N,1);

%% ============================================================
% POWER SPECTRUM
% =============================================================

powerSpectrum = ...
    magnitude.^2;

%% ============================================================
% VALID CFAR RANGE
% =============================================================

edgeCells = ...
    referenceCells + guardCells;

firstCUT = ...
    edgeCells + 1;

lastCUT = ...
    N - edgeCells;

%% ============================================================
% CA-CFAR PROCESSING
% =============================================================

for cut = firstCUT:lastCUT

    leftReferenceIndices = ...
        (cut - guardCells - referenceCells) : ...
        (cut - guardCells - 1);

    rightReferenceIndices = ...
        (cut + guardCells + 1) : ...
        (cut + guardCells + referenceCells);

    referenceIndices = ...
        [leftReferenceIndices, rightReferenceIndices];

    referencePower = ...
        powerSpectrum(referenceIndices);

    estimatedNoisePower = ...
        mean(referencePower);

    threshold = ...
        alpha * estimatedNoisePower;

    noisePowerEstimate(cut) = ...
        estimatedNoisePower;

    thresholdPower(cut) = ...
        threshold;

    thresholdMagnitude(cut) = ...
        sqrt(threshold);

    detectionMask(cut) = ...
        powerSpectrum(cut) > threshold;

end

%% ============================================================
% DETECTED CELLS
% =============================================================

detectedIndices = ...
    find(detectionMask);

detectedFrequencies_Hz = ...
    frequency_Hz(detectedIndices);

detectedMagnitude = ...
    magnitude(detectedIndices);

detectedPower = ...
    powerSpectrum(detectedIndices);

%% ============================================================
% OUTPUT DETECTION STRUCTURE
% =============================================================

detection = struct();

detection.mask = ...
    detectionMask;

detection.detectedIndices = ...
    detectedIndices;

detection.detectedFrequencies_Hz = ...
    detectedFrequencies_Hz;

detection.detectedMagnitude = ...
    detectedMagnitude;

detection.detectedPower = ...
    detectedPower;

detection.noisePowerEstimate = ...
    noisePowerEstimate;

detection.thresholdPower = ...
    thresholdPower;

detection.thresholdMagnitude = ...
    thresholdMagnitude;

%% ============================================================
% INFORMATION STRUCTURE
% =============================================================

info = struct();

info.method = ...
    "CA-CFAR";

info.probabilityOfFalseAlarm = ...
    Pfa;

info.referenceCellsPerSide = ...
    referenceCells;

info.guardCellsPerSide = ...
    guardCells;

info.totalReferenceCells = ...
    Nref;

info.thresholdScalingFactor = ...
    alpha;

info.inputBins = ...
    N;

info.validCUTFirstIndex = ...
    firstCUT;

info.validCUTLastIndex = ...
    lastCUT;

info.validCUTCount = ...
    max(0,lastCUT-firstCUT+1);

info.detectedCellCount = ...
    numel(detectedIndices);

info.detectionFraction = ...
    sum(detectionMask) / N;

end