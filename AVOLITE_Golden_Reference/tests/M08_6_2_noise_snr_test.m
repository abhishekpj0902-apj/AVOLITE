clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

cfg = config_AVOLITE();

%% ============================================================
% TEST PARAMETERS
% =============================================================

Fs = cfg.receiver.adcSampleRate_Hz;

N = cfg.dsp.fftSize;

t = (0:N-1).' / Fs;

signalAmplitude = 0.25;

noiseAmplitude = 0.025;

signalFrequency_Hz = 5e6;

rng(cfg.random.seed);

%% ============================================================
% CLEAN SIGNAL
% =============================================================

xClean = ...
    signalAmplitude .* ...
    exp(1j * 2*pi * signalFrequency_Hz * t);

%% ============================================================
% COMPLEX ADDITIVE NOISE
% =============================================================

noise = ...
    sqrt(noiseAmplitude^2 / 2) .* ...
    (randn(N,1) + 1j*randn(N,1));

%% ============================================================
% RECEIVED SIGNAL
% =============================================================

x = ...
    xClean + noise;

%% ============================================================
% EXPECTED POWERS
% =============================================================

expectedSignalPower_W = ...
    signalAmplitude^2;

expectedNoisePower_W = ...
    noiseAmplitude^2;

expectedTotalPower_W = ...
    expectedSignalPower_W + ...
    expectedNoisePower_W;

expectedSNR_linear = ...
    expectedSignalPower_W / ...
    expectedNoisePower_W;

expectedSNR_dB = ...
    10 * log10(expectedSNR_linear);

%% ============================================================
% FFT
% =============================================================

[spectrum, fftInfo] = ...
    compute_fft_spectrum( ...
        x, ...
        Fs, ...
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
        Fs, ...
        spectrum, ...
        detection, ...
        cfg);

%% ============================================================
% DIRECT VERIFICATION VALUES
% =============================================================

measuredTotalPower_W = ...
    mean(abs(x).^2);

measuredNoisePower_W = ...
    mean(abs(noise).^2);

measuredSNR_linear = ...
    expectedSignalPower_W / ...
    measuredNoisePower_W;

measuredSNR_dB = ...
    10 * log10(measuredSNR_linear);

%% ============================================================
% PRINT RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('M08.6.2 NOISE / SNR VERIFICATION\n');
fprintf('============================================\n');

fprintf('\nExpected values:\n');

fprintf('Expected signal power = %.12e W\n', ...
    expectedSignalPower_W);

fprintf('Expected noise power  = %.12e W\n', ...
    expectedNoisePower_W);

fprintf('Expected total power  = %.12e W\n', ...
    expectedTotalPower_W);

fprintf('Expected SNR          = %.6f dB\n', ...
    expectedSNR_dB);

fprintf('\nMeasured values:\n');

fprintf('Measured total power  = %.12e W\n', ...
    measuredTotalPower_W);

fprintf('Measured noise power  = %.12e W\n', ...
    measuredNoisePower_W);

fprintf('Measured SNR          = %.6f dB\n', ...
    measuredSNR_dB);

fprintf('\nEnvironment state:\n');

fprintf('Environment RX power  = %.12e W\n', ...
    environmentState.receivedPower_W);

fprintf('CFAR noise estimate   = %.12e W\n', ...
    environmentState.noisePower_W);

fprintf('Environment SNR       = %.6f dB\n', ...
    environmentState.SNR_dB);

fprintf('\nCFAR:\n');

fprintf('Detected cells        = %d\n', ...
    cfarInfo.detectedCellCount);

fprintf('Configured Pfa        = %.12e\n', ...
    cfarInfo.probabilityOfFalseAlarm);

fprintf('============================================\n');

%% ============================================================
% VERIFICATION
% =============================================================

relativePowerError = ...
    abs(measuredTotalPower_W - expectedTotalPower_W) / ...
    expectedTotalPower_W;

relativeNoiseError = ...
    abs(measuredNoisePower_W - expectedNoisePower_W) / ...
    expectedNoisePower_W;

snrError_dB = ...
    abs(measuredSNR_dB - expectedSNR_dB);

fprintf('\nVerification metrics:\n');

fprintf('Total power relative error = %.6f %%\n', ...
    100 * relativePowerError);

fprintf('Noise power relative error  = %.6f %%\n', ...
    100 * relativeNoiseError);

fprintf('SNR error                   = %.6f dB\n', ...
    snrError_dB);

%% ============================================================
% BASIC NUMERICAL CHECKS
% =============================================================

if relativePowerError < 0.02

    fprintf('Total power verification    = PASS\n');

else

    fprintf('Total power verification    = REVIEW\n');

end

if relativeNoiseError < 0.05

    fprintf('Noise power verification    = PASS\n');

else

    fprintf('Noise power verification    = REVIEW\n');

end

if snrError_dB < 0.25

    fprintf('SNR verification             = PASS\n');

else

    fprintf('SNR verification             = REVIEW\n');

end

fprintf('\n');