clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

cfg = config_AVOLITE();

geometry = create_ula_geometry(cfg);

%% ============================================================
% TEST PARAMETERS
% =============================================================

testFrequencies_Hz = [ ...
    8e9 ...
    9e9 ...
    10e9 ...
    11e9 ...
    12e9];

testAngles_deg = [-60 -30 0 30 60];

numberOfSamples = 10000;

signalAmplitude = 1.0;

rng(cfg.random.seed);

numberOfFrequencies = numel(testFrequencies_Hz);
numberOfAngles = numel(testAngles_deg);

estimatedAngles_deg = ...
    zeros(numberOfAngles, numberOfFrequencies);

angleErrors_deg = ...
    zeros(numberOfAngles, numberOfFrequencies);

%% ============================================================
% TEST LOOP
% =============================================================

for frequencyCase = 1:numberOfFrequencies

    frequency_Hz = ...
        testFrequencies_Hz(frequencyCase);

    for angleCase = 1:numberOfAngles

        trueAngle_deg = ...
            testAngles_deg(angleCase);

        trueAngle_rad = ...
            deg2rad(trueAngle_deg);

        %% ----------------------------------------------------
        % BASEBAND SIGNAL
        % -----------------------------------------------------

        x_waveform = ...
            signalAmplitude * ones(numberOfSamples, 1);

        %% ----------------------------------------------------
        % APPLY ACTUAL FREQUENCY-DEPENDENT STEERING
        % -----------------------------------------------------

        x_array = ...
            apply_ula_steering( ...
                x_waveform, ...
                geometry, ...
                frequency_Hz, ...
                trueAngle_rad);

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
            angleCase, frequencyCase) = ...
            estimatedAngle_deg;

        angleErrors_deg( ...
            angleCase, frequencyCase) = ...
            estimatedAngle_deg - trueAngle_deg;

    end

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.7.3 ULA AOA FREQUENCY SENSITIVITY VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Array elements       = %d\n', ...
    geometry.numberOfElements);

fprintf('Reference frequency  = %.6f GHz\n', ...
    cfg.antenna.referenceFrequency_Hz / 1e9);

fprintf('Samples per case     = %d\n', ...
    numberOfSamples);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %12s %20s %20s\n', ...
    'Frequency', ...
    'True AoA', ...
    'Estimated AoA', ...
    'Error');

fprintf('%s\n', ...
    repmat('-', 1, 70));

for frequencyCase = 1:numberOfFrequencies

    for angleCase = 1:numberOfAngles

        fprintf( ...
            '%12.3f %12.3f %20.9f %20.9f\n', ...
            testFrequencies_Hz(frequencyCase) / 1e9, ...
            testAngles_deg(angleCase), ...
            estimatedAngles_deg(angleCase, frequencyCase), ...
            angleErrors_deg(angleCase, frequencyCase));

    end

    fprintf('%s\n', ...
        repmat('-', 1, 70));

end

%% ============================================================
% ERROR BY FREQUENCY
% =============================================================

fprintf('\n');
fprintf('AoA error by frequency:\n');

for frequencyCase = 1:numberOfFrequencies

    rmsError_deg = ...
        sqrt(mean( ...
            angleErrors_deg(:, frequencyCase).^2));

    maximumError_deg = ...
        max(abs( ...
            angleErrors_deg(:, frequencyCase)));

    fprintf( ...
        'Frequency = %.3f GHz : RMS error = %.9f deg, max error = %.9f deg\n', ...
        testFrequencies_Hz(frequencyCase) / 1e9, ...
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
fprintf('M08.7.3 CHARACTERIZATION COMPLETE\n');
fprintf('============================================================\n');