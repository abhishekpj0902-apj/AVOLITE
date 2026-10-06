function [pdwComplete, info] = merge_pdw_features( ...
    temporalPulses, spectralPdw, cfg)
%MERGE_PDW_FEATURES Combine temporal and spectral PDW features.
%
% AVOLITE Golden Reference
%
% Inputs:
%   temporalPulses : output of extract_temporal_pulses()
%   spectralPdw    : output of extract_pdw()
%   cfg            : AVOLITE configuration
%
% Outputs:
%   pdwComplete    : combined PDW structure
%   info           : integration diagnostics
%
% Combined fields:
%   PDW_ID
%   ToA_s
%   centreFrequency_Hz
%   pulseWidth_s
%   PRI_s
%   amplitude
%   SNR_linear
%   SNR_dB
%   detectionStatus
%   fftBin
%
% Association model:
%   Ordered observation association.
%
% Important:
%   This function does not use emitter ground truth.
%
%   It expects the caller to provide temporal and spectral
%   observations that have already been associated.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isstruct(temporalPulses)

    error( ...
        'merge_pdw_features:InvalidTemporalInput', ...
        'temporalPulses must be a structure.');

end

if ~isstruct(spectralPdw)

    error( ...
        'merge_pdw_features:InvalidSpectralInput', ...
        'spectralPdw must be a structure.');

end

if ~isstruct(cfg)

    error( ...
        'merge_pdw_features:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% REQUIRED TEMPORAL FIELDS
% =============================================================

requiredTemporalFields = { ...
    'pulseID', ...
    'ToA_s', ...
    'pulseWidth_s', ...
    'amplitude', ...
    'PRI_s'};

for k = 1:numel(requiredTemporalFields)

    fieldName = ...
        requiredTemporalFields{k};

    if ~isfield( ...
            temporalPulses, ...
            fieldName)

        error( ...
            'merge_pdw_features:MissingTemporalField', ...
            'Missing temporal field: %s', ...
            fieldName);

    end

end

%% ============================================================
% REQUIRED SPECTRAL FIELDS
% =============================================================

requiredSpectralFields = { ...
    'PDW_ID', ...
    'centreFrequency_Hz', ...
    'SNR_linear', ...
    'SNR_dB', ...
    'detectionStatus', ...
    'fftBin'};

for k = 1:numel(requiredSpectralFields)

    fieldName = ...
        requiredSpectralFields{k};

    if ~isfield( ...
            spectralPdw, ...
            fieldName)

        error( ...
            'merge_pdw_features:MissingSpectralField', ...
            'Missing spectral field: %s', ...
            fieldName);

    end

end

%% ============================================================
% CONVERT TO COLUMN VECTORS
% =============================================================

temporalID = ...
    temporalPulses.pulseID(:);

temporalToA_s = ...
    temporalPulses.ToA_s(:);

temporalPulseWidth_s = ...
    temporalPulses.pulseWidth_s(:);

temporalPRI_s = ...
    temporalPulses.PRI_s(:);

temporalAmplitude = ...
    temporalPulses.amplitude(:);

spectralID = ...
    spectralPdw.PDW_ID(:);

spectralFrequency_Hz = ...
    spectralPdw.centreFrequency_Hz(:);

spectralSNR_linear = ...
    spectralPdw.SNR_linear(:);

spectralSNR_dB = ...
    spectralPdw.SNR_dB(:);

spectralDetectionStatus = ...
    spectralPdw.detectionStatus(:);

spectralFFTBin = ...
    spectralPdw.fftBin(:);

%% ============================================================
% NUMBER OF OBSERVATIONS
% =============================================================

numberTemporal = ...
    numel(temporalID);

numberSpectral = ...
    numel(spectralID);

%% ============================================================
% SIZE CONSISTENCY
% ============================================================

temporalFieldLengths = [ ...
    numel(temporalToA_s), ...
    numel(temporalPulseWidth_s), ...
    numel(temporalPRI_s), ...
    numel(temporalAmplitude)];

if any( ...
        temporalFieldLengths ~= numberTemporal)

    error( ...
        'merge_pdw_features:TemporalSizeMismatch', ...
        'Temporal PDW fields have inconsistent lengths.');

end

spectralFieldLengths = [ ...
    numel(spectralFrequency_Hz), ...
    numel(spectralSNR_linear), ...
    numel(spectralSNR_dB), ...
    numel(spectralDetectionStatus), ...
    numel(spectralFFTBin)];

if any( ...
        spectralFieldLengths ~= numberSpectral)

    error( ...
        'merge_pdw_features:SpectralSizeMismatch', ...
        'Spectral PDW fields have inconsistent lengths.');

end

%% ============================================================
% ASSOCIATION COUNT CHECK
% ============================================================
%
% The merge function intentionally does not perform
% multi-emitter association.
%
% The caller must provide one spectral observation for
% every temporal observation.

if numberTemporal ~= numberSpectral

    error( ...
        'merge_pdw_features:CountMismatch', ...
        ['Temporal observations (%d) and spectral ' ...
         'observations (%d) do not match.'], ...
        numberTemporal, ...
        numberSpectral);

end

numberOfPDWs = ...
    numberTemporal;

%% ============================================================
% EMPTY CASE
% =============================================================

if numberOfPDWs == 0

    pdwComplete = struct( ...
        'PDW_ID', {}, ...
        'ToA_s', {}, ...
        'centreFrequency_Hz', {}, ...
        'pulseWidth_s', {}, ...
        'PRI_s', {}, ...
        'amplitude', {}, ...
        'SNR_linear', {}, ...
        'SNR_dB', {}, ...
        'detectionStatus', {}, ...
        'fftBin', {});

    info = struct();

    info.numberOfPDWs = 0;

    info.associationMethod = ...
        "ordered_observation";

    info.associationValid = ...
        true;

    info.temporalObservationCount = ...
        0;

    info.spectralObservationCount = ...
        0;

    info.frequencyAvailable = ...
        false;

    info.temporalFeaturesAvailable = ...
        false;

    info.PRIAvailable = ...
        false;

    info.SNRAvailable = ...
        false;

    return;

end

%% ============================================================
% ID ASSOCIATION CHECK
% ============================================================
%
% Ordered association means:
%
% temporal pulse 1 <-> spectral PDW 1
% temporal pulse 2 <-> spectral PDW 2
% ...
%
% The IDs must therefore match exactly.

if ~isequal( ...
        temporalID, ...
        spectralID)

    error( ...
        'merge_pdw_features:IDMismatch', ...
        ['Temporal and spectral PDW IDs do not match. ' ...
         'Ordered association cannot be performed.']);

end

%% ============================================================
% BUILD COMPLETE PDW
% =============================================================

pdwComplete = struct();

pdwComplete.PDW_ID = ...
    temporalID;

pdwComplete.ToA_s = ...
    temporalToA_s;

pdwComplete.centreFrequency_Hz = ...
    spectralFrequency_Hz;

pdwComplete.pulseWidth_s = ...
    temporalPulseWidth_s;

pdwComplete.PRI_s = ...
    temporalPRI_s;

pdwComplete.amplitude = ...
    temporalAmplitude;

pdwComplete.SNR_linear = ...
    spectralSNR_linear;

pdwComplete.SNR_dB = ...
    spectralSNR_dB;

pdwComplete.detectionStatus = ...
    spectralDetectionStatus;

pdwComplete.fftBin = ...
    spectralFFTBin;

%% ============================================================
% FINAL FIELD-LENGTH VALIDATION
% =============================================================

fieldNames = ...
    fieldnames(pdwComplete);

associationValid = ...
    true;

for k = 1:numel(fieldNames)

    fieldData = ...
        pdwComplete.(fieldNames{k});

    if numel(fieldData) ~= ...
            numberOfPDWs

        associationValid = ...
            false;

        break;

    end

end

%% ============================================================
% FEATURE AVAILABILITY
% =============================================================

frequencyAvailable = ...
    all(isfinite( ...
        pdwComplete.centreFrequency_Hz));

temporalFeaturesAvailable = ...
    all(isfinite( ...
        pdwComplete.ToA_s)) && ...
    all(isfinite( ...
        pdwComplete.pulseWidth_s));

if numberOfPDWs >= 2

    PRIAvailable = ...
        all(isfinite( ...
            pdwComplete.PRI_s(2:end)));

else

    PRIAvailable = ...
        false;

end

SNRAvailable = ...
    all(isfinite( ...
        pdwComplete.SNR_dB));

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.numberOfPDWs = ...
    numberOfPDWs;

info.associationMethod = ...
    "ordered_observation";

info.associationValid = ...
    associationValid;

info.temporalObservationCount = ...
    numberTemporal;

info.spectralObservationCount = ...
    numberSpectral;

info.frequencyAvailable = ...
    frequencyAvailable;

info.temporalFeaturesAvailable = ...
    temporalFeaturesAvailable;

info.PRIAvailable = ...
    PRIAvailable;

info.SNRAvailable = ...
    SNRAvailable;

end