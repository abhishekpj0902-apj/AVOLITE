clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

cfg = config_AVOLITE();

geometry = create_ula_geometry(cfg);

%% ============================================================
% TEST GRID
% =============================================================

frequency_GHz = 8:0.25:12;

angles_deg = -80:5:80;

numberOfSamples = 10000;

signalAmplitude = 1.0;

numberOfFrequencies = numel(frequency_GHz);
numberOfAngles = numel(angles_deg);

estimatedAngles_deg = ...
    zeros(numberOfAngles, numberOfFrequencies);

angleErrors_deg = ...
    zeros(numberOfAngles, numberOfFrequencies);

%% ============================================================
% TEST
% =============================================================

for frequencyCase = 1:numberOfFrequencies

    frequency_Hz = ...
        frequency_GHz(frequencyCase) * 1e9;

    for angleCase = 1:numberOfAngles

        trueAngle_deg = ...
            angles_deg(angleCase);

        trueAngle_rad = ...
            deg2rad(trueAngle_deg);

        x_waveform = ...
            signalAmplitude * ones(numberOfSamples, 1);

        x_array = ...
            apply_ula_steering( ...
                x_waveform, ...
                geometry, ...
                frequency_Hz, ...
                trueAngle_rad);

        [estimatedAngle_deg, ~] = ...
            estimate_ula_aoa( ...
                x_array, ...
                frequency_Hz, ...
                geometry, ...
                cfg);

        estimatedAngles_deg( ...
            angleCase, frequencyCase) = ...
            estimatedAngle_deg;

        angleErrors_deg( ...
            angleCase, frequencyCase) = ...
            estimatedAngle_deg - trueAngle_deg;

    end

end

%% ============================================================
% ERROR SUMMARY
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.7.4 ULA AOA AMBIGUITY MAP\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Array elements       = %d\n', ...
    geometry.numberOfElements);

fprintf('Reference frequency  = %.3f GHz\n', ...
    cfg.antenna.referenceFrequency_Hz / 1e9);

fprintf('Element spacing      = %.12f m\n', ...
    geometry.elementSpacing_m);

fprintf('Frequency range      = %.2f to %.2f GHz\n', ...
    min(frequency_GHz), ...
    max(frequency_GHz));

fprintf('Angle range          = %.1f to %.1f deg\n', ...
    min(angles_deg), ...
    max(angles_deg));

%% ============================================================
% PER-FREQUENCY SUMMARY
% =============================================================

fprintf('\n');
fprintf('%12s %20s %20s\n', ...
    'Frequency', ...
    'RMS Error [deg]', ...
    'Max Error [deg]');

fprintf('%s\n', ...
    repmat('-', 1, 60));

for frequencyCase = 1:numberOfFrequencies

    rmsError_deg = ...
        sqrt(mean( ...
            angleErrors_deg(:, frequencyCase).^2));

    maximumError_deg = ...
        max(abs( ...
            angleErrors_deg(:, frequencyCase)));

    fprintf( ...
        '%12.3f %20.9f %20.9f\n', ...
        frequency_GHz(frequencyCase), ...
        rmsError_deg, ...
        maximumError_deg);

end

%% ============================================================
% GLOBAL SUMMARY
% =============================================================

overallRMS_deg = ...
    sqrt(mean(angleErrors_deg(:).^2));

overallMaximumError_deg = ...
    max(abs(angleErrors_deg(:)));

fprintf('\n');

fprintf('Overall RMS error     = %.9f deg\n', ...
    overallRMS_deg);

fprintf('Overall maximum error = %.9f deg\n', ...
    overallMaximumError_deg);

fprintf('\n');

%% ============================================================
% SAVE NUMERICAL RESULTS
% =============================================================

results.frequency_GHz = frequency_GHz;

results.angles_deg = angles_deg;

results.estimatedAngles_deg = ...
    estimatedAngles_deg;

results.angleErrors_deg = ...
    angleErrors_deg;

results.elementSpacing_m = ...
    geometry.elementSpacing_m;

results.referenceFrequency_Hz = ...
    cfg.antenna.referenceFrequency_Hz;

save( ...
    'M08_7_4_aoa_ambiguity_map_results.mat', ...
    'results');

fprintf('Results saved to:\n');
fprintf('M08_7_4_aoa_ambiguity_map_results.mat\n');

fprintf('\n');

fprintf('============================================================\n');
fprintf('M08.7.4 CHARACTERIZATION COMPLETE\n');
fprintf('============================================================\n');