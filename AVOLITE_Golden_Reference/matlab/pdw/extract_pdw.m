function [pdw, info] = extract_pdw( ...
    detection, spectrum, sampleRate_Hz, cfg, varargin)
%EXTRACT_PDW Extract pulse descriptor words from detections.
%
% AVOLITE Golden Reference
%
% Inputs:
%   detection      : output structure from apply_cfar_detection()
%   spectrum       : output structure from compute_fft_spectrum()
%   sampleRate_Hz  : signal sample rate [Hz]
%   cfg            : AVOLITE configuration
%
% Optional:
%   varargin{1}    : pulse observation start time [s]
%
% Outputs:
%   pdw            : PDW structure
%   info           : PDW extraction diagnostics
%
% Extracted fields:
%
%   ToA
%   centre frequency
%   amplitude
%   pulse width
%   PRI
%   SNR
%   detection status
%
% Important:
%   This first Golden Reference implementation extracts
%   frequency-domain detection descriptors.
%
%   Pulse width and PRI require temporal pulse observations.
%   When temporal information is unavailable, those fields
%   are returned as NaN rather than inferred from unrelated
%   information.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isstruct(detection)

    error( ...
        'extract_pdw:InvalidDetection', ...
        'detection must be a structure.');

end

if ~isstruct(spectrum)

    error( ...
        'extract_pdw:InvalidSpectrum', ...
        'spectrum must be a structure.');

end

if ~isscalar(sampleRate_Hz) || ...
        ~isnumeric(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'extract_pdw:InvalidSampleRate', ...
        'sampleRate_Hz must be a positive finite scalar.');

end

if ~isstruct(cfg)

    error( ...
        'extract_pdw:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% REQUIRED DETECTION FIELDS
% =============================================================

requiredDetectionFields = { ...
    'detectedIndices', ...
    'detectedFrequencies_Hz', ...
    'detectedMagnitude'};

for k = 1:numel(requiredDetectionFields)

    fieldName = requiredDetectionFields{k};

    if ~isfield(detection,fieldName)

        error( ...
            'extract_pdw:MissingDetectionField', ...
            'Missing detection field: %s', ...
            fieldName);

    end

end

%% ============================================================
% OPTIONAL OBSERVATION TIME
% =============================================================

observationStartTime_s = 0;

if ~isempty(varargin)

    observationStartTime_s = varargin{1};

    if ~isscalar(observationStartTime_s) || ...
            ~isnumeric(observationStartTime_s) || ...
            ~isfinite(observationStartTime_s)

        error( ...
            'extract_pdw:InvalidObservationTime', ...
            'Observation start time must be a finite scalar.');

    end

end

%% ============================================================
% DETECTION DATA
% =============================================================

detectedIndices = ...
    detection.detectedIndices(:);

detectedFrequencies_Hz = ...
    detection.detectedFrequencies_Hz(:);

detectedMagnitude = ...
    detection.detectedMagnitude(:);

numberOfDetections = ...
    numel(detectedIndices);

if numel(detectedFrequencies_Hz) ~= numberOfDetections || ...
        numel(detectedMagnitude) ~= numberOfDetections

    error( ...
        'extract_pdw:DetectionSizeMismatch', ...
        'Detection fields must have equal lengths.');

end

%% ============================================================
% CONFIGURATION
% =============================================================

if ~isfield(cfg,'pdw') || ...
        ~isstruct(cfg.pdw)

    error( ...
        'extract_pdw:MissingConfiguration', ...
        'PDW configuration is missing.');

end

%% ============================================================
% FFT-BASED TIME RESOLUTION
% ============================================================

fftSamplePeriod_s = ...
    1 / sampleRate_Hz;

%% ============================================================
% TIME OF ARRIVAL
% ============================================================
%
% A frequency-domain detection does not contain an exact
% pulse arrival time.
%
% For this first Golden Reference implementation, ToA is
% associated with the observation start time.
%
% Later temporal pulse extraction will replace this with
% sample-accurate ToA.

ToA_s = ...
    observationStartTime_s * ...
    ones(numberOfDetections,1);

%% ============================================================
% CENTRE FREQUENCY
% ============================================================

centreFrequency_Hz = ...
    detectedFrequencies_Hz;

%% ============================================================
% AMPLITUDE
% ============================================================

amplitude = ...
    detectedMagnitude;

%% ============================================================
% PULSE WIDTH
% ============================================================
%
% Not available from a single FFT detection.
%
% Do not infer PW from FFT bin width.

pulseWidth_s = ...
    nan(numberOfDetections,1);

%% ============================================================
% PRI
% ============================================================
%
% PRI requires multiple temporal pulse arrivals.
%
% It cannot be reliably obtained from one independent
% frequency-domain detection.

PRI_s = ...
    nan(numberOfDetections,1);

%% ============================================================
% SNR
% ============================================================

if isfield(detection,'noisePowerEstimate')

    noisePowerEstimate = ...
        detection.noisePowerEstimate( ...
            detectedIndices);

    noisePowerEstimate = ...
        noisePowerEstimate(:);

    detectedPower = ...
        detectedMagnitude.^2;

    validNoise = ...
        isfinite(noisePowerEstimate) & ...
        noisePowerEstimate > 0;

    SNR_linear = ...
        nan(numberOfDetections,1);

    SNR_linear(validNoise) = ...
        detectedPower(validNoise) ./ ...
        noisePowerEstimate(validNoise);

    SNR_dB = ...
        nan(numberOfDetections,1);

    SNR_dB(validNoise) = ...
        10*log10(SNR_linear(validNoise));

else

    noisePowerEstimate = ...
        nan(numberOfDetections,1);

    SNR_linear = ...
        nan(numberOfDetections,1);

    SNR_dB = ...
        nan(numberOfDetections,1);

end

%% ============================================================
% DETECTION STATUS
% ============================================================

detectionStatus = ...
    true(numberOfDetections,1);

%% ============================================================
% PDW INDEX
% ============================================================

PDW_ID = ...
    (1:numberOfDetections).';

%% ============================================================
% CREATE PDW STRUCTURE
% =============================================================

pdw = struct();

pdw.PDW_ID = ...
    PDW_ID;

pdw.ToA_s = ...
    ToA_s;

pdw.centreFrequency_Hz = ...
    centreFrequency_Hz;

pdw.amplitude = ...
    amplitude;

pdw.pulseWidth_s = ...
    pulseWidth_s;

pdw.PRI_s = ...
    PRI_s;

pdw.SNR_linear = ...
    SNR_linear;

pdw.SNR_dB = ...
    SNR_dB;

pdw.detectionStatus = ...
    detectionStatus;

pdw.fftBin = ...
    detectedIndices;

%% ============================================================
% INFORMATION STRUCTURE
% =============================================================

info = struct();

info.numberOfPDWs = ...
    numberOfDetections;

info.sampleRate_Hz = ...
    sampleRate_Hz;

info.samplePeriod_s = ...
    fftSamplePeriod_s;

info.observationStartTime_s = ...
    observationStartTime_s;

info.ToAAvailable = ...
    true;

info.frequencyAvailable = ...
    true;

info.amplitudeAvailable = ...
    true;

info.pulseWidthAvailable = ...
    false;

info.PRIAvailable = ...
    false;

info.SNRAvailable = ...
    any(isfinite(SNR_dB));

info.temporalPulseExtractionRequired = ...
    true;

info.temporalFeaturesDeferred = ...
    ["pulseWidth_s","PRI_s"];

end