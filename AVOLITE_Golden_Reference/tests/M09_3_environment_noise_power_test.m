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

expectedNoisePower_W = ...
    zeros(numberOfCases,1);

measuredTimeDomainNoisePower_W = ...
    zeros(numberOfCases,1);

cfarNoisePower_W = ...
    zeros(numberOfCases,1);

environmentNoisePower_W = ...
    zeros(numberOfCases,1);

environmentSNR_dB = ...
    zeros(numberOfCases,1);

detectedBins = ...
    zeros(numberOfCases,1);

%% ============================================================
% TEST LOOP
% =============================================================

for caseIndex = 1:numberOfCases

    noiseAmplitude = ...
        noiseAmplitudes(caseIndex);

    %% --------------------------------------------------------
    % COMPLEX WHITE NOISE
    % ---------------------------------------------------------

    x = ...
        sqrt(noiseAmplitude^2 / 2) .* ...
        ( ...
            randn(numberOfSamples,1) + ...
            1j * randn(numberOfSamples,1) ...
        );

    %% --------------------------------------------------------
    % KNOWN TIME-DOMAIN POWER
    % ---------------------------------------------------------

    expectedPower = ...
        noiseAmplitude^2;

    measuredTimeDomainPower = ...
        mean(abs(x).^2);

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
    % CFAR NOISE ESTIMATE
    % ---------------------------------------------------------

    finiteNoise = ...
        detection.noisePowerEstimate( ...
            isfinite(detection.noisePowerEstimate) & ...
            detection.noisePowerEstimate >= 0);

    if isempty(finiteNoise)

        cfarNoise = NaN;

    else

        cfarNoise = ...
            mean(finiteNoise);

    end

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
    % STORE
    % ---------------------------------------------------------

    expectedNoisePower_W(caseIndex) = ...
        expectedPower;

    measuredTimeDomainNoisePower_W(caseIndex) = ...
        measuredTimeDomainPower;

    cfarNoisePower_W(caseIndex) = ...
        cfarNoise;

    environmentNoisePower_W(caseIndex) = ...
        environmentState.noisePower_W;

    environmentSNR_dB(caseIndex) = ...
        environmentState.SNR_dB;

    detectedBins(caseIndex) = ...
        sum(detection.mask);

end

%% ============================================================
% PRINT HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.3 ENVIRONMENT NOISE-POWER CHARACTERIZATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('Samples per case  = %d\n', ...
    numberOfSamples);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %20s %20s %20s %20s %12s\n', ...
    'Noise Amp', ...
    'Expected [W]', ...
    'Measured [W]', ...
    'CFAR [W]', ...
    'Environment [W]', ...
    'Detections');

fprintf('%s\n', ...
    repmat('-', 1, 120));

for caseIndex = 1:numberOfCases

    fprintf( ...
        '%12.5f %20.12e %20.12e %20.12e %20.12e %12d\n', ...
        noiseAmplitudes(caseIndex), ...
        expectedNoisePower_W(caseIndex), ...
        measuredTimeDomainNoisePower_W(caseIndex), ...
        cfarNoisePower_W(caseIndex), ...
        environmentNoisePower_W(caseIndex), ...
        detectedBins(caseIndex));

end

%% ============================================================
% TIME-DOMAIN NOISE VERIFICATION
% =============================================================

timeDomainRelativeError = ...
    abs( ...
        measuredTimeDomainNoisePower_W - ...
        expectedNoisePower_W) ./ ...
    expectedNoisePower_W;

maximumTimeDomainRelativeError = ...
    max(timeDomainRelativeError);

%% ============================================================
% ENVIRONMENT / CFAR CONSISTENCY
% =============================================================

environmentCfarDifference = ...
    environmentNoisePower_W - ...
    cfarNoisePower_W;

maximumEnvironmentCfarDifference = ...
    max(abs(environmentCfarDifference));

%% ============================================================
% NOISE SCALING
% =============================================================

if numberOfCases >= 2

    expectedScalingRatio = ...
        expectedNoisePower_W(end) / ...
        expectedNoisePower_W(1);

    measuredScalingRatio = ...
        environmentNoisePower_W(end) / ...
        environmentNoisePower_W(1);

    scalingRelativeError = ...
        abs( ...
            measuredScalingRatio - ...
            expectedScalingRatio) / ...
        expectedScalingRatio;

else

    expectedScalingRatio = NaN;
    measuredScalingRatio = NaN;
    scalingRelativeError = NaN;

end

%% ============================================================
% MONOTONICITY
% =============================================================

environmentNoiseMonotonic = ...
    all(diff(environmentNoisePower_W) >= 0);

%% ============================================================
% PRINT ANALYSIS
% =============================================================

fprintf('\n');

fprintf('Maximum time-domain noise-power relative error = %.9f %%\n', ...
    100 * maximumTimeDomainRelativeError);

fprintf('Maximum environment-vs-CFAR difference         = %.12e W\n', ...
    maximumEnvironmentCfarDifference);

fprintf('\n');

fprintf('Expected noise-power scaling ratio = %.9f\n', ...
    expectedScalingRatio);

fprintf('Measured environment scaling ratio = %.9f\n', ...
    measuredScalingRatio);

fprintf('Scaling relative error             = %.9f %%\n', ...
    100 * scalingRelativeError);

fprintf('\n');

fprintf('Environment noise monotonicity = %s\n', ...
    passFailText(environmentNoiseMonotonic));

%% ============================================================
% IMPORTANT DOMAIN IDENTIFICATION
% =============================================================

fprintf('\n');

fprintf('============================================================\n');
fprintf('DOMAIN INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['Expected/Measured noise power is the direct time-domain ', ...
         'physical reference.\n']);

fprintf(['Environment noise power is derived from the CFAR ', ...
         'noisePowerEstimate field.\n']);

fprintf(['Therefore the two quantities are characterized separately ', ...
         'and are not assumed numerically equal.\n']);

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.3 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Time-domain noise-power characterization = %s\n', ...
    passFailText( ...
        maximumTimeDomainRelativeError < 0.02));

fprintf('Environment noise monotonicity            = %s\n', ...
    passFailText(environmentNoiseMonotonic));

fprintf('CFAR/environment consistency              = %s\n', ...
    passFailText( ...
        maximumEnvironmentCfarDifference == 0));

fprintf('\n');

fprintf(['NOTE: No physical equivalence between the ', ...
         'time-domain noise power and CFAR noise estimate ', ...
         'is asserted by this test.\n']);

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.3 NOISE-POWER CHARACTERIZATION COMPLETE\n');
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