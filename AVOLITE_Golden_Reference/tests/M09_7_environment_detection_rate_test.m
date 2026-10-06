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
    0.005 ...
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

validBins = zeros(numberOfCases,1);
detectedBins = zeros(numberOfCases,1);

expectedDetectionRate = zeros(numberOfCases,1);
measuredDetectionRate = zeros(numberOfCases,1);

detectionRateError = zeros(numberOfCases,1);

falseAlarmRate = nan(numberOfCases,1);

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
    % VALID SPECTRUM BINS
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
    % EXPECTED DETECTION RATE
    % ---------------------------------------------------------

    expectedRate = ...
        numberOfDetectedBins / numberOfValidBins;

    %% --------------------------------------------------------
    % STORE
    % ---------------------------------------------------------

    validBins(caseIndex) = ...
        numberOfValidBins;

    detectedBins(caseIndex) = ...
        numberOfDetectedBins;

    expectedDetectionRate(caseIndex) = ...
        expectedRate;

    measuredDetectionRate(caseIndex) = ...
        environmentState.detectionRate;

    detectionRateError(caseIndex) = ...
        environmentState.detectionRate - expectedRate;

    falseAlarmRate(caseIndex) = ...
        environmentState.falseAlarmRate;

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.7 ENVIRONMENT DETECTION-RATE VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('FFT size          = %d\n', ...
    cfg.dsp.fftSize);

fprintf('Samples per case  = %d\n', ...
    numberOfSamples);

fprintf('Noise amplitude   = %.6f V\n', ...
    noiseAmplitude);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %12s %12s %18s %18s %14s\n', ...
    'Signal Amp', ...
    'Valid Bins', ...
    'Detected', ...
    'Expected Rate', ...
    'Measured Rate', ...
    'False Alarm');

fprintf('%s\n', ...
    repmat('-', 1, 105));

for caseIndex = 1:numberOfCases

    fprintf( ...
        '%12.5f %12d %12d %18.9f %18.9f %14s\n', ...
        signalAmplitudes(caseIndex), ...
        validBins(caseIndex), ...
        detectedBins(caseIndex), ...
        expectedDetectionRate(caseIndex), ...
        measuredDetectionRate(caseIndex), ...
        formatNaN(falseAlarmRate(caseIndex)));

end

%% ============================================================
% MAXIMUM ERROR
% =============================================================

maximumDetectionRateError = ...
    max(abs(detectionRateError));

%% ============================================================
% RANGE CHECK
% =============================================================

detectionRateRangePass = ...
    all( ...
        measuredDetectionRate >= 0 & ...
        measuredDetectionRate <= 1);

%% ============================================================
% FALSE-ALARM AVAILABILITY
% =============================================================

falseAlarmUnavailablePass = ...
    all(isnan(falseAlarmRate));

%% ============================================================
% DETECTION-RATE MONOTONICITY
% =============================================================

% Do not impose a strict monotonicity requirement.
% CFAR detects spectrum bins, not physical targets, and
% leakage/noise realization can change the number of
% detected bins.

%% ============================================================
% PRINT
% =============================================================

fprintf('\n');

fprintf('Maximum detection-rate error = %.12e\n', ...
    maximumDetectionRateError);

fprintf('Detection-rate range [0,1]   = %s\n', ...
    passFailText(detectionRateRangePass));

fprintf('False-alarm unavailable      = %s\n', ...
    passFailText(falseAlarmUnavailablePass));

%% ============================================================
% DOMAIN INTERPRETATION
% =============================================================

fprintf('\n');

fprintf('============================================================\n');
fprintf('DETECTION-RATE INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['Current detectionRate represents the fraction of valid ', ...
         'spectrum bins marked as detected by CFAR.\n']);

fprintf('\n');

fprintf('    detectionRate = detected valid bins / valid bins\n');

fprintf('\n');

fprintf(['This is an observation-level detection fraction and ', ...
         'is not yet a conventional target-level probability ', ...
         'of detection (Pd).\n']);

fprintf(['False-alarm rate remains unavailable because this test ', ...
         'does not provide target-absent ground truth labels.\n']);

%% ============================================================
% VERIFICATION RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.7 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

detectionRateConsistencyPass = ...
    maximumDetectionRateError <= 1e-12;

fprintf('Detection-rate consistency = %s\n', ...
    passFailText(detectionRateConsistencyPass));

fprintf('Detection-rate range       = %s\n', ...
    passFailText(detectionRateRangePass));

fprintf('False-alarm availability   = %s\n', ...
    passFailText(falseAlarmUnavailablePass));

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    detectionRateConsistencyPass && ...
    detectionRateRangePass && ...
    falseAlarmUnavailablePass;

fprintf('\n');

if overallPass

    fprintf('M09.7 RESULT = PASS\n');

else

    fprintf('M09.7 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.7 ENVIRONMENT DETECTION-RATE VERIFICATION COMPLETE\n');
fprintf('============================================================\n');

%% ============================================================
% LOCAL FUNCTIONS
% =============================================================

function text = passFailText(value)

    if value
        text = 'PASS';
    else
        text = 'FAIL';
    end

end

function text = formatNaN(value)

    if isnan(value)
        text = 'NaN';
    else
        text = sprintf('%.6f', value);
    end

end