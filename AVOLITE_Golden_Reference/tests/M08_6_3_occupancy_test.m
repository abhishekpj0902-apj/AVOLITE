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

%% ============================================================
% CONTROLLED MULTI-TONE SIGNAL
% ============================================================

A1 = 0.25;
A2 = 0.20;

f1 = 5e6;
f2 = -10e6;

x = ...
    A1 .* exp(1j*2*pi*f1*t) + ...
    A2 .* exp(1j*2*pi*f2*t);

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
% DETECTION INFORMATION
% =============================================================

numberOfBins = ...
    numel(detection.mask);

numberOfDetectedBins = ...
    sum(detection.mask);

measuredOccupancy = ...
    numberOfDetectedBins / numberOfBins;

%% ============================================================
% PRINT RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('M08.6.3 SPECTRAL OCCUPANCY VERIFICATION\n');
fprintf('============================================\n');

fprintf('\nSpectrum:\n');

fprintf('FFT size              = %d\n', ...
    fftInfo.fftSize);

fprintf('Frequency resolution  = %.9f Hz\n', ...
    fftInfo.frequencyResolution_Hz);

fprintf('Total spectrum bins   = %d\n', ...
    numberOfBins);

fprintf('\nDetection:\n');

fprintf('Detected bins         = %d\n', ...
    numberOfDetectedBins);

fprintf('Detection fraction    = %.12f\n', ...
    cfarInfo.detectionFraction);

fprintf('\nEnvironment state:\n');

fprintf('Spectral occupancy    = %.12f\n', ...
    environmentState.spectralOccupancy);

fprintf('Detection rate        = %.12f\n', ...
    environmentState.detectionRate);

fprintf('Ground truth used     = %d\n', ...
    info.groundTruthUsed);

fprintf('\nDetected frequencies:\n');

disp(detection.detectedFrequencies_Hz);

%% ============================================================
% INTERNAL CONSISTENCY CHECK
% =============================================================

occupancyDifference = ...
    abs( ...
        environmentState.spectralOccupancy - ...
        measuredOccupancy);

fprintf('Occupancy difference  = %.12e\n', ...
    occupancyDifference);

if occupancyDifference < 1e-12

    fprintf('\nSpectral occupancy verification = PASS\n');

else

    fprintf('\nSpectral occupancy verification = REVIEW\n');

end

%% ============================================================
% DETECTION RATE CONSISTENCY
% =============================================================

detectionRateDifference = ...
    abs( ...
        environmentState.detectionRate - ...
        cfarInfo.detectionFraction);

fprintf('Detection-rate difference = %.12e\n', ...
    detectionRateDifference);

if detectionRateDifference < 1e-12

    fprintf('Detection-rate verification = PASS\n');

else

    fprintf('Detection-rate verification = REVIEW\n');

end

fprintf('============================================\n');