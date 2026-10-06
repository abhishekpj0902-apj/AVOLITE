clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

sampleRate_Hz = ...
    cfg.receiver.adcSampleRate_Hz;

numberOfSamples = 4096;

signalFrequency_Hz = 5e6;

noiseAmplitude = 0.025;

signalAmplitudes = [ ...
    0.000 ...
    0.010 ...
    0.025 ...
    0.050 ...
    0.100 ...
    0.250];

numberOfCases = ...
    numel(signalAmplitudes);

rng(cfg.random.seed);

%% ============================================================
% RESULT ARRAYS
% =============================================================

totalBins = zeros(numberOfCases,1);
validBins = zeros(numberOfCases,1);
detectedBins = zeros(numberOfCases,1);

expectedOccupancy = zeros(numberOfCases,1);
measuredOccupancy = zeros(numberOfCases,1);

occupancyError = zeros(numberOfCases,1);

detectionRate = zeros(numberOfCases,1);

%% ============================================================
% TEST LOOP
% =============================================================

for caseIndex = 1:numberOfCases

    signalAmplitude = ...
        signalAmplitudes(caseIndex);

    n = (0:numberOfSamples-1).';

    %% --------------------------------------------------------
    % SIGNAL
    % ---------------------------------------------------------

    signal = ...
        signalAmplitude .* ...
        exp(1j * ...
        2*pi*signalFrequency_Hz/sampleRate_Hz .* n);

    %% --------------------------------------------------------
    % NOISE
    % ---------------------------------------------------------

    noise = ...
        sqrt(noiseAmplitude^2 / 2) .* ...
        ( ...
            randn(numberOfSamples,1) + ...
            1j * randn(numberOfSamples,1) ...
        );

    x = signal + noise;

    %% --------------------------------------------------------
    % FFT
    % ---------------------------------------------------------

    [spectrum, ~] = ...
        compute_fft_spectrum( ...
            x, ...
            sampleRate_Hz, ...
            cfg);

    %% --------------------------------------------------------
    % CFAR
    % ---------------------------------------------------------

    [detection, cfarInfo] = ...
        apply_cfar_detection( ...
            spectrum, ...
            cfg);

    %% --------------------------------------------------------
    % ENVIRONMENT STATE
    % ---------------------------------------------------------

    [environmentState, envInfo] = ...
        calculate_environment_state( ...
            x, ...
            sampleRate_Hz, ...
            spectrum, ...
            detection, ...
            cfg);

    %% --------------------------------------------------------
    % VALID BIN COUNT
    % ---------------------------------------------------------

    validMask = ...
        isfinite(spectrum.frequency_Hz) & ...
        isfinite(spectrum.magnitudeNormalized) & ...
        spectrum.magnitudeNormalized >= 0;

    numberOfValidBins = ...
        sum(validMask);

    numberOfDetectedBins = ...
        sum(detection.mask(validMask));

    %% --------------------------------------------------------
    % EXPECTED OCCUPANCY
    % ---------------------------------------------------------

    expected = ...
        numberOfDetectedBins / numberOfValidBins;

    %% --------------------------------------------------------
    % STORE
    % ---------------------------------------------------------

    totalBins(caseIndex) = ...
        numel(spectrum.frequency_Hz);

    validBins(caseIndex) = ...
        numberOfValidBins;

    detectedBins(caseIndex) = ...
        numberOfDetectedBins;

    expectedOccupancy(caseIndex) = ...
        expected;

    measuredOccupancy(caseIndex) = ...
        environmentState.spectralOccupancy;

    occupancyError(caseIndex) = ...
        environmentState.spectralOccupancy - expected;

    detectionRate(caseIndex) = ...
        environmentState.detectionRate;

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.6 ENVIRONMENT SPECTRAL-OCCUPANCY VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('FFT size          = %d\n', ...
    cfg.dsp.fftSize);

fprintf('Samples            = %d\n', ...
    numberOfSamples);

fprintf('Noise amplitude   = %.6f V\n', ...
    noiseAmplitude);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %12s %12s %16s %16s %16s\n', ...
    'Signal Amp', ...
    'Total Bins', ...
    'Detected', ...
    'Expected Occ.', ...
    'Measured Occ.', ...
    'Detection Rate');

fprintf('%s\n', ...
    repmat('-', 1, 105));

for caseIndex = 1:numberOfCases

    fprintf( ...
        '%12.5f %12d %12d %16.9f %16.9f %16.9f\n', ...
        signalAmplitudes(caseIndex), ...
        totalBins(caseIndex), ...
        detectedBins(caseIndex), ...
        expectedOccupancy(caseIndex), ...
        measuredOccupancy(caseIndex), ...
        detectionRate(caseIndex));

end

%% ============================================================
% ERROR
% =============================================================

maximumOccupancyError = ...
    max(abs(occupancyError));

%% ============================================================
% DETECTION-RATE CONSISTENCY
% =============================================================

detectionRateError = ...
    detectionRate - measuredOccupancy;

maximumDetectionRateError = ...
    max(abs(detectionRateError));

%% ============================================================
% RANGE CHECK
% =============================================================

occupancyRangePass = ...
    all(measuredOccupancy >= 0 & ...
        measuredOccupancy <= 1);

%% ============================================================
% PRINT
% =============================================================

fprintf('\n');

fprintf('Maximum occupancy error       = %.12e\n', ...
    maximumOccupancyError);

fprintf('Maximum detection-rate error  = %.12e\n', ...
    maximumDetectionRateError);

fprintf('Occupancy range [0,1]         = %s\n', ...
    passFailText(occupancyRangePass));

%% ============================================================
% DOMAIN INTERPRETATION
% =============================================================

fprintf('\n');

fprintf('============================================================\n');
fprintf('SPECTRAL-OCCUPANCY INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['Occupancy is currently defined from the CFAR detection ', ...
         'mask and valid spectrum bins.\n']);

fprintf('\n');

fprintf('    spectralOccupancy = detected valid bins / valid bins\n');

fprintf('\n');

fprintf(['This test verifies the implementation definition and ', ...
         'does not impose an external occupancy requirement.\n']);

fprintf(['Detection rate is also expected to match the same ', ...
         'observation-level detection fraction in the current ', ...
         'environment-state implementation.\n']);

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.6 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

occupancyConsistencyPass = ...
    maximumOccupancyError <= 1e-12;

detectionRateConsistencyPass = ...
    maximumDetectionRateError <= 1e-12;

fprintf('Spectral occupancy consistency = %s\n', ...
    passFailText(occupancyConsistencyPass));

fprintf('Detection-rate consistency     = %s\n', ...
    passFailText(detectionRateConsistencyPass));

fprintf('Occupancy range                = %s\n', ...
    passFailText(occupancyRangePass));

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    occupancyConsistencyPass && ...
    detectionRateConsistencyPass && ...
    occupancyRangePass;

fprintf('\n');

if overallPass

    fprintf('M09.6 RESULT = PASS\n');

else

    fprintf('M09.6 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.6 ENVIRONMENT SPECTRAL-OCCUPANCY VERIFICATION COMPLETE\n');
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