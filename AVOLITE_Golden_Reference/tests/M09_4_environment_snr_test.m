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

signalAmplitude = 0.25;

signalFrequency_Hz = 5e6;

noiseAmplitudes = [ ...
    0.001 ...
    0.005 ...
    0.010 ...
    0.025 ...
    0.050];

numberOfCases = ...
    numel(noiseAmplitudes);

rng(cfg.random.seed);

%% ============================================================
% RESULTS
% =============================================================

receivedPower_W = ...
    zeros(numberOfCases,1);

cfarNoisePower_W = ...
    zeros(numberOfCases,1);

environmentSNR_linear = ...
    zeros(numberOfCases,1);

environmentSNR_dB = ...
    zeros(numberOfCases,1);

calculatedSNR_linear = ...
    zeros(numberOfCases,1);

calculatedSNR_dB = ...
    zeros(numberOfCases,1);

physicalNoisePower_W = ...
    zeros(numberOfCases,1);

physicalReferenceSNR_dB = ...
    zeros(numberOfCases,1);

%% ============================================================
% TEST LOOP
% =============================================================

for caseIndex = 1:numberOfCases

    noiseAmplitude = ...
        noiseAmplitudes(caseIndex);

    n = ...
        (0:numberOfSamples-1).';

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
    % PHYSICAL REFERENCE
    % ---------------------------------------------------------

    signalPowerReference_W = ...
        signalAmplitude^2;

    physicalNoisePower = ...
        noiseAmplitude^2;

    physicalSNR_linear = ...
        signalPowerReference_W / physicalNoisePower;

    physicalSNR_dB = ...
        10 * log10(physicalSNR_linear);

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
    % CURRENT ENVIRONMENT-STATE DEFINITION
    % ---------------------------------------------------------

    receivedPower = ...
        environmentState.receivedPower_W;

    cfarNoisePower = ...
        environmentState.noisePower_W;

    calculatedLinear = ...
        receivedPower / cfarNoisePower;

    calculatedDB = ...
        10 * log10(calculatedLinear);

    %% --------------------------------------------------------
    % STORE
    % ---------------------------------------------------------

    receivedPower_W(caseIndex) = ...
        receivedPower;

    cfarNoisePower_W(caseIndex) = ...
        cfarNoisePower;

    environmentSNR_linear(caseIndex) = ...
        environmentState.SNR_linear;

    environmentSNR_dB(caseIndex) = ...
        environmentState.SNR_dB;

    calculatedSNR_linear(caseIndex) = ...
        calculatedLinear;

    calculatedSNR_dB(caseIndex) = ...
        calculatedDB;

    physicalNoisePower_W(caseIndex) = ...
        physicalNoisePower;

    physicalReferenceSNR_dB(caseIndex) = ...
        physicalSNR_dB;

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.4 ENVIRONMENT SNR VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Signal amplitude = %.6f V\n', ...
    signalAmplitude);

fprintf('Signal frequency = %.6f MHz\n', ...
    signalFrequency_Hz / 1e6);

fprintf('Samples per case = %d\n', ...
    numberOfSamples);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%10s %18s %18s %18s %18s %18s\n', ...
    'Noise Amp', ...
    'RX Power [W]', ...
    'CFAR Noise [W]', ...
    'Env SNR [dB]', ...
    'Calc SNR [dB]', ...
    'Physical SNR [dB]');

fprintf('%s\n', ...
    repmat('-', 1, 115));

for caseIndex = 1:numberOfCases

    fprintf( ...
        '%10.5f %18.9e %18.9e %18.6f %18.6f %18.6f\n', ...
        noiseAmplitudes(caseIndex), ...
        receivedPower_W(caseIndex), ...
        cfarNoisePower_W(caseIndex), ...
        environmentSNR_dB(caseIndex), ...
        calculatedSNR_dB(caseIndex), ...
        physicalReferenceSNR_dB(caseIndex));

end

%% ============================================================
% INTERNAL CONSISTENCY ERRORS
% =============================================================

linearError = ...
    environmentSNR_linear - ...
    calculatedSNR_linear;

dBError = ...
    environmentSNR_dB - ...
    calculatedSNR_dB;

maximumLinearError = ...
    max(abs(linearError));

maximumDBError = ...
    max(abs(dBError));

%% ============================================================
% SNR MONOTONICITY
% =============================================================

environmentSNRMonotonic = ...
    all(diff(environmentSNR_dB) < 0);

physicalSNRMonotonic = ...
    all(diff(physicalReferenceSNR_dB) < 0);

%% ============================================================
% PRINT
% =============================================================

fprintf('\n');

fprintf('Maximum SNR-linear consistency error = %.12e\n', ...
    maximumLinearError);

fprintf('Maximum SNR-dB consistency error     = %.12e dB\n', ...
    maximumDBError);

fprintf('Environment SNR strictly decreases   = %s\n', ...
    passFailText(environmentSNRMonotonic));

fprintf('Physical reference SNR decreases     = %s\n', ...
    passFailText(physicalSNRMonotonic));

%% ============================================================
% DOMAIN INTERPRETATION
% =============================================================

fprintf('\n');

fprintf('============================================================\n');
fprintf('SNR DOMAIN INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['Environment SNR is calculated using the current ', ...
         'environment-state noisePower_W field.\n']);

fprintf(['That field is derived from CFAR noisePowerEstimate, ', ...
         'not the injected physical noise power.\n']);

fprintf(['Physical reference SNR is shown separately and is ', ...
         'not used as the environment-state verification target.\n']);

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.4 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

snrLinearPass = ...
    maximumLinearError <= 1e-12;

snrDBPass = ...
    maximumDBError <= 1e-12;

fprintf('SNR linear internal consistency = %s\n', ...
    passFailText(snrLinearPass));

fprintf('SNR dB internal consistency     = %s\n', ...
    passFailText(snrDBPass));

fprintf('Environment SNR monotonicity    = %s\n', ...
    passFailText(environmentSNRMonotonic));

fprintf('Physical SNR monotonicity       = %s\n', ...
    passFailText(physicalSNRMonotonic));

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    snrLinearPass && ...
    snrDBPass && ...
    environmentSNRMonotonic && ...
    physicalSNRMonotonic;

fprintf('\n');

if overallPass

    fprintf('M09.4 RESULT = PASS\n');

else

    fprintf('M09.4 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.4 ENVIRONMENT SNR VERIFICATION COMPLETE\n');
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