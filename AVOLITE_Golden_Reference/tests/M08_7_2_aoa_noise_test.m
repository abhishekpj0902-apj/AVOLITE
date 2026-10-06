clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

cfg = config_AVOLITE();

%% ============================================================
% ARRAY
% =============================================================

geometry = create_ula_geometry(cfg);

%% ============================================================
% TEST PARAMETERS
% =============================================================

frequency_Hz = cfg.antenna.referenceFrequency_Hz;

testAngles_deg = [-60 -30 0 30 60];

numberOfSamples = 10000;

signalAmplitude = 1.0;

noiseAmplitudes = [0.01 0.05 0.10];

rng(cfg.random.seed);

%% ============================================================
% RESULTS
% =============================================================

numberOfAngles = numel(testAngles_deg);
numberOfNoiseCases = numel(noiseAmplitudes);

estimatedAngles_deg = ...
    zeros(numberOfAngles, numberOfNoiseCases);

angleErrors_deg = ...
    zeros(numberOfAngles, numberOfNoiseCases);

%% ============================================================
% TEST LOOP
% =============================================================

for noiseCase = 1:numberOfNoiseCases

    noiseAmplitude = noiseAmplitudes(noiseCase);

    for angleCase = 1:numberOfAngles

        trueAngle_deg = testAngles_deg(angleCase);

        trueAngle_rad = deg2rad(trueAngle_deg);

        %% ----------------------------------------------------
        % BASEBAND SIGNAL
        % -----------------------------------------------------

        x_waveform = ...
            signalAmplitude * ones(numberOfSamples, 1);

        %% ----------------------------------------------------
        % ARRAY STEERING
        % -----------------------------------------------------

        x_array_clean = ...
            apply_ula_steering( ...
                x_waveform, ...
                geometry, ...
                frequency_Hz, ...
                trueAngle_rad);

        %% ----------------------------------------------------
        % COMPLEX ARRAY NOISE
        % -----------------------------------------------------

        noise = ...
            sqrt(noiseAmplitude^2 / 2) .* ...
            ( ...
                randn(size(x_array_clean)) + ...
                1j * randn(size(x_array_clean)) ...
            );

        %% ----------------------------------------------------
        % NOISY ARRAY SIGNAL
        % -----------------------------------------------------

        x_array = ...
            x_array_clean + noise;

        %% ----------------------------------------------------
        % AOA ESTIMATION
        % -----------------------------------------------------

        [estimatedAngle_deg, ~] = ...
            estimate_ula_aoa( ...
                x_array, ...
                frequency_Hz, ...
                geometry, ...
                cfg);

        %% ----------------------------------------------------
        % STORE RESULTS
        % -----------------------------------------------------

        estimatedAngles_deg( ...
            angleCase, noiseCase) = ...
            estimatedAngle_deg;

        angleErrors_deg( ...
            angleCase, noiseCase) = ...
            estimatedAngle_deg - trueAngle_deg;

    end

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.7.2 ULA AOA NOISE VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Array elements       = %d\n', ...
    geometry.numberOfElements);

fprintf('RF frequency         = %.6f GHz\n', ...
    frequency_Hz / 1e9);

fprintf('Samples per case     = %d\n', ...
    numberOfSamples);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %12s %20s %20s\n', ...
    'True AoA', ...
    'Noise Amp', ...
    'Estimated AoA', ...
    'Error');

fprintf('%s\n', ...
    repmat('-', 1, 70));

for noiseCase = 1:numberOfNoiseCases

    for angleCase = 1:numberOfAngles

        fprintf( ...
            '%12.3f %12.5f %20.9f %20.9f\n', ...
            testAngles_deg(angleCase), ...
            noiseAmplitudes(noiseCase), ...
            estimatedAngles_deg(angleCase, noiseCase), ...
            angleErrors_deg(angleCase, noiseCase));

    end

    fprintf('%s\n', ...
        repmat('-', 1, 70));

end

%% ============================================================
% RMS ERROR BY NOISE LEVEL
% =============================================================

fprintf('\n');
fprintf('RMS AoA error by noise amplitude:\n');

for noiseCase = 1:numberOfNoiseCases

    rmsError_deg = ...
        sqrt(mean( ...
            angleErrors_deg(:, noiseCase).^2));

    maximumError_deg = ...
        max(abs( ...
            angleErrors_deg(:, noiseCase)));

    fprintf( ...
        'Noise = %.5f : RMS error = %.9f deg, max error = %.9f deg\n', ...
        noiseAmplitudes(noiseCase), ...
        rmsError_deg, ...
        maximumError_deg);

end

%% ============================================================
% OVERALL CHARACTERIZATION
% =============================================================

overallRMS_deg = ...
    sqrt(mean(angleErrors_deg(:).^2));

overallMaximumError_deg = ...
    max(abs(angleErrors_deg(:)));

fprintf('\n');
fprintf('Overall RMS AoA error     = %.9f deg\n', ...
    overallRMS_deg);

fprintf('Overall maximum AoA error = %.9f deg\n', ...
    overallMaximumError_deg);

fprintf('Ground truth used internally by estimator = 0\n');

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.7.2 CHARACTERIZATION COMPLETE\n');
fprintf('============================================================\n');