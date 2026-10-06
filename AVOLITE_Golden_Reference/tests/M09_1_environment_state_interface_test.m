clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

%% ============================================================
% TEST SIGNAL
% =============================================================

sampleRate_Hz = cfg.receiver.adcSampleRate_Hz;

numberOfSamples = 4096;

signalAmplitude = 0.25;

signalFrequency_Hz = 5e6;

n = (0:numberOfSamples-1).';

x = signalAmplitude .* ...
    exp(1j * 2*pi * signalFrequency_Hz / sampleRate_Hz .* n);

%% ============================================================
% FFT
% =============================================================

[spectrum, fftInfo] = ...
    compute_fft_spectrum( ...
        x, ...
        sampleRate_Hz, ...
        cfg);

%% ============================================================
% CFAR
% =============================================================

[detection, cfarInfo] = ...
    apply_cfar_detection( ...
        spectrum, ...
        cfg);

%% ============================================================
% ENVIRONMENT STATE
% =============================================================

[environmentState, info] = ...
    calculate_environment_state( ...
        x, ...
        sampleRate_Hz, ...
        spectrum, ...
        detection, ...
        cfg);

%% ============================================================
% EXPECTED ENVIRONMENT-STATE FIELDS
% =============================================================

requiredEnvironmentFields = { ...
    'receivedPower_W', ...
    'receivedPower_dBm', ...
    'noisePower_W', ...
    'noisePower_dBm', ...
    'SNR_linear', ...
    'SNR_dB', ...
    'interferencePower_W', ...
    'interferencePower_dBm', ...
    'spectralOccupancy', ...
    'detectionRate', ...
    'falseAlarmRate'};

%% ============================================================
% EXPECTED DIAGNOSTIC FIELDS
% =============================================================

requiredInfoFields = { ...
    'sampleRate_Hz', ...
    'signalLength_samples', ...
    'numberOfSpectrumBins', ...
    'numberOfValidBins', ...
    'numberOfDetectedBins', ...
    'falseAlarmRateAvailable', ...
    'groundTruthUsed', ...
    'configuredCFAR_Pfa', ...
    'spectralPowerDefinition', ...
    'absoluteReceivedPowerSource'};

%% ============================================================
% CHECK ENVIRONMENT-STATE FIELDS
% =============================================================

missingEnvironmentFields = {};

for k = 1:numel(requiredEnvironmentFields)

    fieldName = requiredEnvironmentFields{k};

    if ~isfield(environmentState, fieldName)

        missingEnvironmentFields{end+1} = ...
            fieldName; %#ok<SAGROW>

    end

end

%% ============================================================
% CHECK DIAGNOSTIC FIELDS
% =============================================================

missingInfoFields = {};

for k = 1:numel(requiredInfoFields)

    fieldName = requiredInfoFields{k};

    if ~isfield(info, fieldName)

        missingInfoFields{end+1} = ...
            fieldName; %#ok<SAGROW>

    end

end

%% ============================================================
% PRINT ENVIRONMENT-STATE FIELDS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.1 ENVIRONMENT-STATE INTERFACE VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Environment-state fields:\n');

environmentFieldNames = ...
    fieldnames(environmentState);

for k = 1:numel(environmentFieldNames)

    fprintf('  %s\n', ...
        environmentFieldNames{k});

end

%% ============================================================
% PRINT DIAGNOSTIC FIELDS
% =============================================================

fprintf('\n');

fprintf('Diagnostic fields:\n');

infoFieldNames = ...
    fieldnames(info);

for k = 1:numel(infoFieldNames)

    fprintf('  %s\n', ...
        infoFieldNames{k});

end

%% ============================================================
% PRINT VALUES
% =============================================================

fprintf('\n');
fprintf('Environment-state values:\n\n');

fprintf('Received power          = %.12e W\n', ...
    environmentState.receivedPower_W);

fprintf('Received power          = %.9f dBm\n', ...
    environmentState.receivedPower_dBm);

fprintf('Noise power             = %.12e W\n', ...
    environmentState.noisePower_W);

fprintf('Noise power             = %.9f dBm\n', ...
    environmentState.noisePower_dBm);

fprintf('SNR                     = %.12e linear\n', ...
    environmentState.SNR_linear);

fprintf('SNR                     = %.9f dB\n', ...
    environmentState.SNR_dB);

fprintf('Interference power      = %.12e W\n', ...
    environmentState.interferencePower_W);

fprintf('Interference power      = %.9f dBm\n', ...
    environmentState.interferencePower_dBm);

fprintf('Spectral occupancy      = %.12f\n', ...
    environmentState.spectralOccupancy);

fprintf('Detection rate          = %.12f\n', ...
    environmentState.detectionRate);

fprintf('False-alarm rate        = %.12f\n', ...
    environmentState.falseAlarmRate);

%% ============================================================
% BASIC RANGE CHECKS
% =============================================================

receivedPowerFinite = ...
    isfinite(environmentState.receivedPower_W);

receivedPowerNonnegative = ...
    environmentState.receivedPower_W >= 0;

occupancyValid = ...
    isnan(environmentState.spectralOccupancy) || ...
    (environmentState.spectralOccupancy >= 0 && ...
     environmentState.spectralOccupancy <= 1);

detectionRateValid = ...
    isnan(environmentState.detectionRate) || ...
    (environmentState.detectionRate >= 0 && ...
     environmentState.detectionRate <= 1);

falseAlarmIsUndefined = ...
    isnan(environmentState.falseAlarmRate);

%% ============================================================
% DIAGNOSTIC CONSISTENCY
% =============================================================

sampleRatePass = ...
    info.sampleRate_Hz == sampleRate_Hz;

signalLengthPass = ...
    info.signalLength_samples == numberOfSamples;

spectrumBinPass = ...
    info.numberOfSpectrumBins == ...
    numel(spectrum.magnitude);

validBinPass = ...
    info.numberOfValidBins >= 0 && ...
    info.numberOfValidBins <= ...
    info.numberOfSpectrumBins;

detectedBinPass = ...
    info.numberOfDetectedBins >= 0 && ...
    info.numberOfDetectedBins <= ...
    info.numberOfValidBins;

groundTruthIsolationPass = ...
    info.groundTruthUsed == false;

falseAlarmAvailabilityPass = ...
    info.falseAlarmRateAvailable == false;

%% ============================================================
% REQUIRED FIELD RESULTS
% =============================================================

environmentFieldsPass = ...
    isempty(missingEnvironmentFields);

infoFieldsPass = ...
    isempty(missingInfoFields);

%% ============================================================
% PRINT CHECKS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.1 INTERFACE CHECK RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Environment-state fields      = %s\n', ...
    passFailText(environmentFieldsPass));

fprintf('Diagnostic fields              = %s\n', ...
    passFailText(infoFieldsPass));

fprintf('Received power finite          = %s\n', ...
    passFailText(receivedPowerFinite));

fprintf('Received power nonnegative     = %s\n', ...
    passFailText(receivedPowerNonnegative));

fprintf('Spectral occupancy range       = %s\n', ...
    passFailText(occupancyValid));

fprintf('Detection-rate range           = %s\n', ...
    passFailText(detectionRateValid));

fprintf('False-alarm currently undefined= %s\n', ...
    passFailText(falseAlarmIsUndefined));

fprintf('Sample-rate diagnostic         = %s\n', ...
    passFailText(sampleRatePass));

fprintf('Signal-length diagnostic       = %s\n', ...
    passFailText(signalLengthPass));

fprintf('Spectrum-bin diagnostic        = %s\n', ...
    passFailText(spectrumBinPass));

fprintf('Valid-bin diagnostic           = %s\n', ...
    passFailText(validBinPass));

fprintf('Detected-bin diagnostic        = %s\n', ...
    passFailText(detectedBinPass));

fprintf('Ground-truth isolation         = %s\n', ...
    passFailText(groundTruthIsolationPass));

fprintf('False-alarm availability flag  = %s\n', ...
    passFailText(falseAlarmAvailabilityPass));

%% ============================================================
% DISPLAY MISSING FIELDS
% =============================================================

if ~isempty(missingEnvironmentFields)

    fprintf('\n');
    fprintf('Missing environment-state fields:\n');

    for k = 1:numel(missingEnvironmentFields)

        fprintf('  %s\n', ...
            missingEnvironmentFields{k});

    end

end

if ~isempty(missingInfoFields)

    fprintf('\n');
    fprintf('Missing diagnostic fields:\n');

    for k = 1:numel(missingInfoFields)

        fprintf('  %s\n', ...
            missingInfoFields{k});

    end

end

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    environmentFieldsPass && ...
    infoFieldsPass && ...
    receivedPowerFinite && ...
    receivedPowerNonnegative && ...
    occupancyValid && ...
    detectionRateValid && ...
    falseAlarmIsUndefined && ...
    sampleRatePass && ...
    signalLengthPass && ...
    spectrumBinPass && ...
    validBinPass && ...
    detectedBinPass && ...
    groundTruthIsolationPass && ...
    falseAlarmAvailabilityPass;

fprintf('\n');

if overallPass

    fprintf('M09.1 RESULT = PASS\n');

else

    fprintf('M09.1 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.1 ENVIRONMENT-STATE INTERFACE VERIFICATION COMPLETE\n');
fprintf('============================================================\n');

%% ============================================================
% LOCAL FUNCTION
% =============================================================

function text = passFailText(value)

    if value

        text = 'PASS';

    else

        text = 'FAIL';

    end

end