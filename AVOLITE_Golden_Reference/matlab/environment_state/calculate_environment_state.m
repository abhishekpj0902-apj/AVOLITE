function [environmentState, info] = calculate_environment_state( ...
    x, ...
    sampleRate_Hz, ...
    spectrum, ...
    detection, ...
    cfg)

%CALCULATE_ENVIRONMENT_STATE Calculate RF environment-state features.
%
% AVOLITE Golden Reference
%
% Inputs:
%   x               : complex receiver/DSP time-domain signal
%   sampleRate_Hz   : signal sample rate [Hz]
%   spectrum        : output of compute_fft_spectrum()
%   detection       : output of apply_cfar_detection()
%   cfg             : AVOLITE configuration
%
% Outputs:
%   environmentState : calculated environment-state features
%   info             : diagnostics
%
% Features:
%   receivedPower_W
%   receivedPower_dBm
%   noisePower_W
%   noisePower_dBm
%   SNR_linear
%   SNR_dB
%   interferencePower_W
%   interferencePower_dBm
%   spectralOccupancy
%   detectionRate
%   falseAlarmRate
%
% IMPORTANT:
%   This function does not use emitter ground truth.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(x) || isempty(x)

    error( ...
        'calculate_environment_state:InvalidSignal', ...
        'x must be a non-empty numeric signal.');

end

if ~isscalar(sampleRate_Hz) || ...
        ~isnumeric(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'calculate_environment_state:InvalidSampleRate', ...
        'sampleRate_Hz must be positive and finite.');

end

if ~isstruct(spectrum)

    error( ...
        'calculate_environment_state:InvalidSpectrum', ...
        'spectrum must be a structure.');

end

if ~isstruct(detection)

    error( ...
        'calculate_environment_state:InvalidDetection', ...
        'detection must be a structure.');

end

if ~isstruct(cfg)

    error( ...
        'calculate_environment_state:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% REQUIRED SPECTRUM FIELDS
% =============================================================

requiredSpectrumFields = { ...
    'frequency_Hz', ...
    'magnitude', ...
    'magnitudeNormalized'};

for k = 1:numel(requiredSpectrumFields)

    fieldName = requiredSpectrumFields{k};

    if ~isfield(spectrum, fieldName)

        error( ...
            'calculate_environment_state:MissingSpectrumField', ...
            'Missing spectrum field: %s', ...
            fieldName);

    end

end

%% ============================================================
% REQUIRED DETECTION FIELDS
% =============================================================

requiredDetectionFields = { ...
    'mask', ...
    'noisePowerEstimate'};

for k = 1:numel(requiredDetectionFields)

    fieldName = requiredDetectionFields{k};

    if ~isfield(detection, fieldName)

        error( ...
            'calculate_environment_state:MissingDetectionField', ...
            'Missing detection field: %s', ...
            fieldName);

    end

end

%% ============================================================
% SIGNAL VECTOR
% =============================================================

x = x(:);

N = numel(x);

%% ============================================================
% RECEIVED POWER
% =============================================================

receivedPower_W = ...
    mean(abs(x).^2);

if receivedPower_W > 0

    receivedPower_dBm = ...
        10 * log10(receivedPower_W / 1e-3);

else

    receivedPower_dBm = -Inf;

end

%% ============================================================
% SPECTRUM
% =============================================================

spectrumMagnitude = ...
    spectrum.magnitude(:);

spectrumMagnitudeNormalized = ...
    spectrum.magnitudeNormalized(:);

numberOfSpectrumBins = ...
    numel(spectrumMagnitude);

if numel(spectrumMagnitudeNormalized) ~= ...
        numberOfSpectrumBins

    error( ...
        'calculate_environment_state:SpectrumSizeMismatch', ...
        ['spectrum.magnitude and ' ...
         'spectrum.magnitudeNormalized must have ' ...
         'the same number of elements.']);

end

%% ============================================================
% DERIVED SPECTRAL POWER
% ============================================================

%
% The FFT module provides normalized magnitude rather than
% an explicit power field.
%
% Therefore:
%
%   spectral power = |normalized magnitude|^2
%
% This quantity is used for spectral occupancy calculations.

spectrumPower = ...
    abs(spectrumMagnitudeNormalized).^2;

%% ============================================================
% DETECTION MASK
% =============================================================

detectionMask = ...
    logical(detection.mask(:));

if numel(detectionMask) ~= ...
        numberOfSpectrumBins

    error( ...
        'calculate_environment_state:DetectionMaskSizeMismatch', ...
        ['Detection mask and spectrum size do not match. ' ...
         'Detection bins = %d, spectrum bins = %d.'], ...
        numel(detectionMask), ...
        numberOfSpectrumBins);

end

%% ============================================================
% NOISE POWER
% =============================================================

noisePowerVector = ...
    detection.noisePowerEstimate(:);

finiteNoise = ...
    noisePowerVector( ...
        isfinite(noisePowerVector) & ...
        noisePowerVector >= 0);

if isempty(finiteNoise)

    noisePower_W = NaN;

else

    noisePower_W = ...
        mean(finiteNoise);

end

if isfinite(noisePower_W) && ...
        noisePower_W > 0

    noisePower_dBm = ...
        10 * log10(noisePower_W / 1e-3);

else

    noisePower_dBm = -Inf;

end

%% ============================================================
% SNR
% =============================================================

if isfinite(noisePower_W) && ...
        noisePower_W > 0

    SNR_linear = ...
        receivedPower_W / noisePower_W;

    SNR_dB = ...
        10 * log10(SNR_linear);

else

    SNR_linear = NaN;

    SNR_dB = NaN;

end

%% ============================================================
% INTERFERENCE POWER
% ============================================================

%
% Initial Golden Reference definition:
%
%   interference power =
%   received power - estimated noise power
%
% Negative values are limited to zero.

if isfinite(noisePower_W)

    interferencePower_W = ...
        max(receivedPower_W - noisePower_W, 0);

else

    interferencePower_W = NaN;

end

if isfinite(interferencePower_W) && ...
        interferencePower_W > 0

    interferencePower_dBm = ...
        10 * log10(interferencePower_W / 1e-3);

else

    interferencePower_dBm = -Inf;

end

%% ============================================================
% VALID SPECTRUM BINS
% =============================================================

validSpectrumMask = ...
    isfinite(spectrumPower) & ...
    spectrumPower >= 0;

numberOfValidBins = ...
    sum(validSpectrumMask);

%% ============================================================
% SPECTRAL OCCUPANCY
% =============================================================

if numberOfValidBins > 0

    spectralOccupancy = ...
        sum(detectionMask(validSpectrumMask)) / ...
        numberOfValidBins;

else

    spectralOccupancy = NaN;

end

%% ============================================================
% DETECTION RATE
% =============================================================

%
% Observation-level definition:
%
%   detected valid bins / valid spectrum bins
%
% This is not a statistical Pd estimate.

if numberOfValidBins > 0

    detectionRate = ...
        sum(detectionMask(validSpectrumMask)) / ...
        numberOfValidBins;

else

    detectionRate = NaN;

end

%% ============================================================
% FALSE ALARM RATE
% =============================================================

%
% A measured false-alarm rate requires target-absent
% ground-truth trials.
%
% The current observation does not contain such labels.
%
% Therefore no false-alarm measurement is invented here.

falseAlarmRate = NaN;

%% ============================================================
% BUILD ENVIRONMENT STATE
% =============================================================

environmentState = struct();

environmentState.receivedPower_W = ...
    receivedPower_W;

environmentState.receivedPower_dBm = ...
    receivedPower_dBm;

environmentState.noisePower_W = ...
    noisePower_W;

environmentState.noisePower_dBm = ...
    noisePower_dBm;

environmentState.SNR_linear = ...
    SNR_linear;

environmentState.SNR_dB = ...
    SNR_dB;

environmentState.interferencePower_W = ...
    interferencePower_W;

environmentState.interferencePower_dBm = ...
    interferencePower_dBm;

environmentState.spectralOccupancy = ...
    spectralOccupancy;

environmentState.detectionRate = ...
    detectionRate;

environmentState.falseAlarmRate = ...
    falseAlarmRate;

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.sampleRate_Hz = ...
    sampleRate_Hz;

info.signalLength_samples = ...
    N;

info.numberOfSpectrumBins = ...
    numberOfSpectrumBins;

info.numberOfValidBins = ...
    numberOfValidBins;

info.numberOfDetectedBins = ...
    sum(detectionMask(validSpectrumMask));

info.falseAlarmRateAvailable = ...
    false;

info.groundTruthUsed = ...
    false;

%% ============================================================
% CONFIGURED CFAR PFA
% =============================================================

if isfield(cfg, 'detection') && ...
        isfield(cfg.detection, 'probabilityOfFalseAlarm')

    info.configuredCFAR_Pfa = ...
        cfg.detection.probabilityOfFalseAlarm;

else

    info.configuredCFAR_Pfa = NaN;

end

%% ============================================================
% SPECTRAL POWER DEFINITION
% =============================================================

info.spectralPowerDefinition = ...
    "abs(spectrum.magnitudeNormalized).^2";

info.absoluteReceivedPowerSource = ...
    "mean(abs(x).^2)";

end