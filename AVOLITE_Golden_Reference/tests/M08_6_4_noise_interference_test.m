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

signalFrequency_Hz = 5e6;

noiseAmplitudes = [ ...
    0.001 ...
    0.005 ...
    0.010 ...
    0.025 ...
    0.050];

rng(cfg.random.seed);

%% ============================================================
% RESULTS
% =============================================================

numberOfCases = ...
    numel(noiseAmplitudes);

results = struct();

results.noiseAmplitude = ...
    zeros(numberOfCases,1);

results.receivedPower_W = ...
    zeros(numberOfCases,1);

results.measuredNoisePower_W = ...
    zeros(numberOfCases,1);

results.measuredNoisePower_dBm = ...
    zeros(numberOfCases,1);

results.measuredSNR_dB = ...
    zeros(numberOfCases,1);

results.interferencePower_W = ...
    zeros(numberOfCases,1);

results.detectedBins = ...
    zeros(numberOfCases,1);

%% ============================================================
% TEST LOOP
% =============================================================

for caseIndex = 1:numberOfCases

    noiseAmplitude = ...
        noiseAmplitudes(caseIndex);

    %% --------------------------------------------------------
    % CLEAN SIGNAL
    % ---------------------------------------------------------

    xClean = ...
        signalAmplitude .* ...
        exp(1j * 2*pi*signalFrequency_Hz*t);

    %% --------------------------------------------------------
    % ADDITIVE COMPLEX NOISE
    % ---------------------------------------------------------

    noise = ...
        sqrt(noiseAmplitude^2 / 2) .* ...
        (randn(N,1) + 1j*randn(N,1));

    %% --------------------------------------------------------
    % RECEIVED SIGNAL
    % ---------------------------------------------------------

    x = ...
        xClean + noise;

    %% --------------------------------------------------------
    % FFT
    % ---------------------------------------------------------

    [spectrum, fftInfo] = ...
        compute_fft_spectrum( ...
            x, ...
            Fs, ...
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

    [environmentState, info] = ...
        calculate_environment_state( ...
            x, ...
            Fs, ...
            spectrum, ...
            detection, ...
            cfg);

    %% --------------------------------------------------------
    % DIRECT NOISE REFERENCE
    % ---------------------------------------------------------

    directNoisePower_W = ...
        mean(abs(noise).^2);

    directSNR_dB = ...
        10 * log10( ...
            signalAmplitude^2 / ...
            directNoisePower_W);

    %% --------------------------------------------------------
    % STORE RESULTS
    % ---------------------------------------------------------

    results.noiseAmplitude(caseIndex) = ...
        noiseAmplitude;

    results.receivedPower_W(caseIndex) = ...
        environmentState.receivedPower_W;

    results.measuredNoisePower_W(caseIndex) = ...
        directNoisePower_W;

    results.measuredNoisePower_dBm(caseIndex) = ...
        10 * log10(directNoisePower_W / 1e-3);

    results.measuredSNR_dB(caseIndex) = ...
        directSNR_dB;

    results.interferencePower_W(caseIndex) = ...
        environmentState.interferencePower_W;

    results.detectedBins(caseIndex) = ...
        cfarInfo.detectedCellCount;

end

%% ============================================================
% DISPLAY RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.6.4 NOISE / INTERFERENCE CHARACTERIZATION\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('%12s %18s %18s %16s %16s %12s\n', ...
    'Noise Amp', ...
    'RX Power [W]', ...
    'Noise Power [W]', ...
    'Noise [dBm]', ...
    'SNR [dB]', ...
    'Detections');

fprintf('%s\n', ...
    repmat('-',1,110));

for k = 1:numberOfCases

    fprintf('%12.5f %18.9e %18.9e %16.6f %16.6f %12d\n', ...
        results.noiseAmplitude(k), ...
        results.receivedPower_W(k), ...
        results.measuredNoisePower_W(k), ...
        results.measuredNoisePower_dBm(k), ...
        results.measuredSNR_dB(k), ...
        results.detectedBins(k));

end

fprintf('\n');
fprintf('Expected signal power = %.12e W\n', ...
    signalAmplitude^2);

fprintf('============================================================\n');

%% ============================================================
% CHARACTERIZATION CHECKS
% =============================================================

fprintf('\nCharacterization checks:\n');

%% Noise power should increase approximately quadratically
% with the specified complex-noise amplitude.

noisePowerRatioExpected = ...
    (noiseAmplitudes(end) / noiseAmplitudes(1))^2;

noisePowerRatioMeasured = ...
    results.measuredNoisePower_W(end) / ...
    results.measuredNoisePower_W(1);

fprintf('\nNoise-power scaling:\n');

fprintf('Expected ratio = %.6f\n', ...
    noisePowerRatioExpected);

fprintf('Measured ratio = %.6f\n', ...
    noisePowerRatioMeasured);

noiseScalingError = ...
    abs(noisePowerRatioMeasured - ...
        noisePowerRatioExpected) / ...
    noisePowerRatioExpected;

fprintf('Relative scaling error = %.6f %%\n', ...
    100 * noiseScalingError);

%% SNR should decrease as noise increases.

snrTrend = ...
    diff(results.measuredSNR_dB);

fprintf('\nSNR progression:\n');

disp(results.measuredSNR_dB);

if all(snrTrend < 0)

    fprintf('SNR monotonic decrease = PASS\n');

else

    fprintf('SNR monotonic decrease = REVIEW\n');

end

%% Received power should remain close to signal power plus noise.

expectedTotalPower = ...
    signalAmplitude^2 + ...
    results.measuredNoisePower_W;

relativeTotalPowerError = ...
    abs(results.receivedPower_W - ...
        expectedTotalPower) ./ ...
    expectedTotalPower;

fprintf('\nMaximum total-power relative error = %.6f %%\n', ...
    100 * max(relativeTotalPowerError));

if max(relativeTotalPowerError) < 0.02

    fprintf('Total-power characterization = PASS\n');

else

    fprintf('Total-power characterization = REVIEW\n');

end

fprintf('\n');
fprintf('NOTE:\n');
fprintf(['CFAR noisePowerEstimate is intentionally not used as ' ...
    'the direct time-domain noise-power reference in this test.\n']);

fprintf(['The purpose is to characterize the relationship between ' ...
    'known injected noise and the environment-state observations.\n']);

fprintf('============================================================\n');