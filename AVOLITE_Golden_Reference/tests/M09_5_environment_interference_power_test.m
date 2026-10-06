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

signalAmplitudes = [ ...
    0.001 ...
    0.010 ...
    0.025 ...
    0.050 ...
    0.100 ...
    0.250];

noiseAmplitude = 0.025;

numberOfCases = ...
    numel(signalAmplitudes);

rng(cfg.random.seed);

%% ============================================================
% RESULT ARRAYS
% =============================================================

receivedPower_W = zeros(numberOfCases,1);
noisePower_W = zeros(numberOfCases,1);

expectedInterferencePower_W = zeros(numberOfCases,1);
measuredInterferencePower_W = zeros(numberOfCases,1);

expectedInterferencePower_dBm = zeros(numberOfCases,1);
measuredInterferencePower_dBm = zeros(numberOfCases,1);

detectedBins = zeros(numberOfCases,1);

%% ============================================================
% TEST LOOP
% =============================================================

for caseIndex = 1:numberOfCases

    signalAmplitude = ...
        signalAmplitudes(caseIndex);

    n = (0:numberOfSamples-1).';

    signal = ...
        signalAmplitude .* ...
        exp(1j * ...
        2*pi*signalFrequency_Hz/sampleRate_Hz .* n);

    noise = ...
        sqrt(noiseAmplitude^2 / 2) .* ...
        ( ...
            randn(numberOfSamples,1) + ...
            1j * randn(numberOfSamples,1) ...
        );

    x = signal + noise;

    %% --------------------------------------------------------
    % SPECTRUM
    % ---------------------------------------------------------

    [spectrum, ~] = ...
        compute_fft_spectrum( ...
            x, ...
            sampleRate_Hz, ...
            cfg);

    %% --------------------------------------------------------
    % CFAR
    % ---------------------------------------------------------

    [detection, ~] = ...
        apply_cfar_detection( ...
            spectrum, ...
            cfg);

    %% --------------------------------------------------------
    % ENVIRONMENT STATE
    % ---------------------------------------------------------

    [environmentState, ~] = ...
        calculate_environment_state( ...
            x, ...
            sampleRate_Hz, ...
            spectrum, ...
            detection, ...
            cfg);

    %% --------------------------------------------------------
    % CURRENT IMPLEMENTATION REFERENCE
    % ---------------------------------------------------------

    receivedPower = ...
        environmentState.receivedPower_W;

    noisePower = ...
        environmentState.noisePower_W;

    %% --------------------------------------------------------
    % EXPECTED INTERFERENCE
    %
    % Current implementation:
    %
    % interferencePower_W =
    %     max(receivedPower_W - noisePower_W, 0)
    % ---------------------------------------------------------

    expectedInterference = ...
        max(receivedPower - noisePower, 0);

    expectedInterference_dBm = ...
        10 * log10(expectedInterference / 1e-3);

    %% --------------------------------------------------------
    % STORE
    % ---------------------------------------------------------

    receivedPower_W(caseIndex) = ...
        receivedPower;

    noisePower_W(caseIndex) = ...
        noisePower;

    expectedInterferencePower_W(caseIndex) = ...
        expectedInterference;

    measuredInterferencePower_W(caseIndex) = ...
        environmentState.interferencePower_W;

    expectedInterferencePower_dBm(caseIndex) = ...
        expectedInterference_dBm;

    measuredInterferencePower_dBm(caseIndex) = ...
        environmentState.interferencePower_dBm;

    detectedBins(caseIndex) = ...
        sum(detection.mask);

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.5 ENVIRONMENT INTERFERENCE-POWER VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('Samples per case  = %d\n', ...
    numberOfSamples);

fprintf('Noise amplitude   = %.6f V\n', ...
    noiseAmplitude);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %18s %18s %18s %18s %12s\n', ...
    'Signal Amp', ...
    'RX Power [W]', ...
    'Noise [W]', ...
    'Expected Intf [W]', ...
    'Measured Intf [W]', ...
    'Detections');

fprintf('%s\n', ...
    repmat('-', 1, 115));

for caseIndex = 1:numberOfCases

    fprintf( ...
        '%12.5f %18.9e %18.9e %18.9e %18.9e %12d\n', ...
        signalAmplitudes(caseIndex), ...
        receivedPower_W(caseIndex), ...
        noisePower_W(caseIndex), ...
        expectedInterferencePower_W(caseIndex), ...
        measuredInterferencePower_W(caseIndex), ...
        detectedBins(caseIndex));

end

%% ============================================================
% POWER CONSISTENCY
% =============================================================

powerError_W = ...
    measuredInterferencePower_W - ...
    expectedInterferencePower_W;

maximumPowerError_W = ...
    max(abs(powerError_W));

%% ============================================================
% dBm CONSISTENCY
% =============================================================

dbmFiniteMask = ...
    isfinite(expectedInterferencePower_dBm) & ...
    isfinite(measuredInterferencePower_dBm);

if any(dbmFiniteMask)

    dbmError = ...
        measuredInterferencePower_dBm(dbmFiniteMask) - ...
        expectedInterferencePower_dBm(dbmFiniteMask);

    maximumDBmError = ...
        max(abs(dbmError));

else

    maximumDBmError = 0;

end

%% ============================================================
% CLAMPING VERIFICATION
% =============================================================

clampMask = ...
    receivedPower_W <= noisePower_W;

clampPass = ...
    all(measuredInterferencePower_W(clampMask) == 0);

%% ============================================================
% NON-NEGATIVITY
% =============================================================

nonNegativePass = ...
    all(measuredInterferencePower_W >= 0);

%% ============================================================
% MONOTONICITY
% =============================================================

% For this test, the low-signal cases may be dominated by
% noise/CFAR estimation. Therefore no arbitrary monotonicity
% requirement is imposed on interference power.

%% ============================================================
% PRINT NUMERICAL RESULTS
% =============================================================

fprintf('\n');

fprintf('Maximum interference-power error = %.12e W\n', ...
    maximumPowerError_W);

fprintf('Maximum interference dBm error  = %.12e dB\n', ...
    maximumDBmError);

fprintf('Number of clamped cases          = %d\n', ...
    sum(clampMask));

fprintf('Clamp behavior                   = %s\n', ...
    passFailText(clampPass));

fprintf('Non-negative interference        = %s\n', ...
    passFailText(nonNegativePass));

%% ============================================================
% DOMAIN INTERPRETATION
% =============================================================

fprintf('\n');

fprintf('============================================================\n');
fprintf('INTERFERENCE DOMAIN INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['Interference power is verified against the current ', ...
         'environment-state definition:\n']);

fprintf('\n');

fprintf('    interferencePower_W = max(receivedPower_W - noisePower_W, 0)\n');

fprintf('\n');

fprintf(['The noisePower_W quantity is the current CFAR-domain ', ...
         'noise estimate.\n']);

fprintf(['Therefore this test verifies implementation consistency ', ...
         'and non-negative clamping.\n']);

fprintf(['It does not claim that the resulting interference power ', ...
         'is a calibrated physical RF interference power.\n']);

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.5 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

powerPass = ...
    maximumPowerError_W <= 1e-12;

dbmPass = ...
    maximumDBmError <= 1e-12;

fprintf('Interference power consistency = %s\n', ...
    passFailText(powerPass));

fprintf('Interference dBm consistency   = %s\n', ...
    passFailText(dbmPass));

fprintf('Clamping behavior              = %s\n', ...
    passFailText(clampPass));

fprintf('Non-negative interference      = %s\n', ...
    passFailText(nonNegativePass));

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    powerPass && ...
    dbmPass && ...
    clampPass && ...
    nonNegativePass;

fprintf('\n');

if overallPass

    fprintf('M09.5 RESULT = PASS\n');

else

    fprintf('M09.5 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.5 ENVIRONMENT INTERFERENCE-POWER VERIFICATION COMPLETE\n');
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