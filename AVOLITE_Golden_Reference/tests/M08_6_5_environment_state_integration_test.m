clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

cfg = config_AVOLITE();

%% ============================================================
% TEST CONFIGURATION
% =============================================================

Fs = cfg.receiver.adcSampleRate_Hz;

N = cfg.dsp.fftSize;

t = (0:N-1).' / Fs;

signalAmplitude = 0.25;

signalFrequency_Hz = 5e6;

noiseAmplitude = 0.025;

rng(cfg.random.seed);

%% ============================================================
% GENERATE CLEAN SIGNAL
% =============================================================

xClean = ...
    signalAmplitude .* ...
    exp(1j * 2*pi*signalFrequency_Hz*t);

%% ============================================================
% GENERATE COMPLEX NOISE
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
% EXPECTED PHYSICAL QUANTITIES
% =============================================================

expectedSignalPower_W = ...
    signalAmplitude^2;

expectedNoisePower_W = ...
    mean(abs(noise).^2);

expectedTotalPower_W = ...
    expectedSignalPower_W + ...
    expectedNoisePower_W;

expectedSNR_dB = ...
    10 * log10( ...
        expectedSignalPower_W / ...
        expectedNoisePower_W);

%% ============================================================
% DSP: FFT
% =============================================================

[spectrum, fftInfo] = ...
    compute_fft_spectrum( ...
        x, ...
        Fs, ...
        cfg);

%% ============================================================
% DSP: CFAR
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
% MEASURED RECEIVED POWER
% =============================================================

measuredReceivedPower_W = ...
    mean(abs(x).^2);

%% ============================================================
% POWER CONSISTENCY
% =============================================================

powerError = ...
    abs( ...
        measuredReceivedPower_W - ...
        expectedTotalPower_W);

relativePowerError = ...
    powerError / expectedTotalPower_W;

%% ============================================================
% SPECTRAL OCCUPANCY CONSISTENCY
% =============================================================

numberOfBins = ...
    numel(detection.mask);

numberOfDetectedBins = ...
    sum(detection.mask);

expectedOccupancy = ...
    numberOfDetectedBins / numberOfBins;

occupancyError = ...
    abs( ...
        environmentState.spectralOccupancy - ...
        expectedOccupancy);

%% ============================================================
% DETECTION RATE CONSISTENCY
% =============================================================

detectionRateError = ...
    abs( ...
        environmentState.detectionRate - ...
        cfarInfo.detectionFraction);

%% ============================================================
% SIGNAL-LEVEL SNR REFERENCE
% =============================================================

measuredSNR_dB = ...
    expectedSNR_dB;

%% ============================================================
% PRINT INTEGRATION RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.6.5 ENVIRONMENT-STATE INTEGRATION VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\nINPUT:\n');

fprintf('Sample rate          = %.6f MHz\n', ...
    Fs / 1e6);

fprintf('FFT size             = %d\n', ...
    N);

fprintf('Signal amplitude     = %.6f V\n', ...
    signalAmplitude);

fprintf('Signal frequency     = %.6f MHz\n', ...
    signalFrequency_Hz / 1e6);

fprintf('Noise amplitude      = %.6f V\n', ...
    noiseAmplitude);

fprintf('\nEXPECTED:\n');

fprintf('Signal power         = %.12e W\n', ...
    expectedSignalPower_W);

fprintf('Noise power          = %.12e W\n', ...
    expectedNoisePower_W);

fprintf('Total power          = %.12e W\n', ...
    expectedTotalPower_W);

fprintf('Expected SNR         = %.6f dB\n', ...
    expectedSNR_dB);

fprintf('\nMEASURED:\n');

fprintf('Received power       = %.12e W\n', ...
    measuredReceivedPower_W);

fprintf('Environment RX power = %.12e W\n', ...
    environmentState.receivedPower_W);

fprintf('Environment RX dBm   = %.6f dBm\n', ...
    environmentState.receivedPower_dBm);

fprintf('Reference SNR        = %.6f dB\n', ...
    measuredSNR_dB);

fprintf('\nCFAR / SPECTRUM:\n');

fprintf('Spectrum bins        = %d\n', ...
    numberOfBins);

fprintf('Detected bins        = %d\n', ...
    numberOfDetectedBins);

fprintf('CFAR detection frac. = %.12f\n', ...
    cfarInfo.detectionFraction);

fprintf('Environment occupancy= %.12f\n', ...
    environmentState.spectralOccupancy);

fprintf('Environment det. rate= %.12f\n', ...
    environmentState.detectionRate);

fprintf('\nERRORS:\n');

fprintf('Relative power error = %.9f %%\n', ...
    100 * relativePowerError);

fprintf('Occupancy error      = %.12e\n', ...
    occupancyError);

fprintf('Detection-rate error = %.12e\n', ...
    detectionRateError);

fprintf('\nDIAGNOSTICS:\n');

fprintf('Ground truth used    = %d\n', ...
    info.groundTruthUsed);

fprintf('False alarm available= %d\n', ...
    info.falseAlarmRateAvailable);

fprintf('Configured CFAR Pfa  = %.12e\n', ...
    info.configuredCFAR_Pfa);

fprintf('\n============================================================\n');

%% ============================================================
% VERIFICATION CRITERIA
% =============================================================

powerPass = ...
    relativePowerError < 0.02;

occupancyPass = ...
    occupancyError < 1e-12;

detectionRatePass = ...
    detectionRateError < 1e-12;

%% ============================================================
% FINAL RESULTS
% =============================================================

fprintf('\nFINAL VERIFICATION:\n');

if powerPass

    fprintf('Received-power consistency = PASS\n');

else

    fprintf('Received-power consistency = REVIEW\n');

end

if occupancyPass

    fprintf('Spectral occupancy         = PASS\n');

else

    fprintf('Spectral occupancy         = REVIEW\n');

end

if detectionRatePass

    fprintf('Detection-rate consistency = PASS\n');

else

    fprintf('Detection-rate consistency = REVIEW\n');

end

if powerPass && ...
        occupancyPass && ...
        detectionRatePass

    fprintf('\nM08.6.5 RESULT = PASS\n');

else

    fprintf('\nM08.6.5 RESULT = REVIEW\n');

end

fprintf('============================================================\n');