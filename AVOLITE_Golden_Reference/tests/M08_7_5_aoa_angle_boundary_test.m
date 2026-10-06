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

% Frequencies selected around the previously observed boundary
testFrequencies_GHz = [ ...
    10.00 ...
    10.10 ...
    10.20 ...
    10.25 ...
    10.30 ...
    10.50 ...
    11.00 ...
    11.50 ...
    12.00];

% Fine angular grid
testAngles_deg = -90:0.1:90;

numberOfSamples = 10000;

signalAmplitude = 1.0;

numberOfFrequencies = ...
    numel(testFrequencies_GHz);

numberOfAngles = ...
    numel(testAngles_deg);

%% ============================================================
% RESULT ARRAYS
% =============================================================

estimatedAngles_deg = ...
    zeros(numberOfAngles, numberOfFrequencies);

angleErrors_deg = ...
    zeros(numberOfAngles, numberOfFrequencies);

validMask = ...
    false(numberOfAngles, numberOfFrequencies);

%% ============================================================
% TEST LOOP
% =============================================================

for frequencyCase = 1:numberOfFrequencies

    frequency_Hz = ...
        testFrequencies_GHz(frequencyCase) * 1e9;

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
        % ARRAY STEERING
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
        % ERROR
        % -----------------------------------------------------

        error_deg = ...
            estimatedAngle_deg - trueAngle_deg;

        estimatedAngles_deg( ...
            angleCase, frequencyCase) = ...
            estimatedAngle_deg;

        angleErrors_deg( ...
            angleCase, frequencyCase) = ...
            error_deg;

        %% ----------------------------------------------------
        % VALIDITY
        %
        % No project accuracy requirement is imposed here.
        %
        % This is a characterization threshold used only to
        % identify the continuous unambiguous region.
        % -----------------------------------------------------

        validMask( ...
            angleCase, frequencyCase) = ...
            abs(error_deg) <= 1e-6;

    end

end

%% ============================================================
% SUMMARY
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.7.5 ULA AOA ANGLE-AMBIGUITY BOUNDARY\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Array elements       = %d\n', ...
    geometry.numberOfElements);

fprintf('Reference frequency  = %.3f GHz\n', ...
    cfg.antenna.referenceFrequency_Hz / 1e9);

fprintf('Element spacing      = %.12f m\n', ...
    geometry.elementSpacing_m);

fprintf('Angle resolution     = %.3f deg\n', ...
    testAngles_deg(2) - testAngles_deg(1));

%% ============================================================
% DETERMINE CONTINUOUS VALID REGION AROUND ZERO
% =============================================================

boundaryNegative_deg = ...
    nan(1, numberOfFrequencies);

boundaryPositive_deg = ...
    nan(1, numberOfFrequencies);

for frequencyCase = 1:numberOfFrequencies

    centerIndex = ...
        find(testAngles_deg == 0, 1);

    %% --------------------------------------------------------
    % Positive-angle boundary
    % ---------------------------------------------------------

    positiveIndices = ...
        centerIndex:numberOfAngles;

    positiveValid = ...
        validMask(positiveIndices, frequencyCase);

    firstInvalid = ...
        find(~positiveValid, 1, 'first');

    if isempty(firstInvalid)

        boundaryPositive_deg(frequencyCase) = ...
            max(testAngles_deg);

    else

        invalidIndex = ...
            positiveIndices(firstInvalid);

        boundaryPositive_deg(frequencyCase) = ...
            testAngles_deg(invalidIndex - 1);

    end

    %% --------------------------------------------------------
    % Negative-angle boundary
    % ---------------------------------------------------------

    negativeIndices = ...
        centerIndex:-1:1;

    negativeValid = ...
        validMask(negativeIndices, frequencyCase);

    firstInvalid = ...
        find(~negativeValid, 1, 'first');

    if isempty(firstInvalid)

        boundaryNegative_deg(frequencyCase) = ...
            min(testAngles_deg);

    else

        invalidIndex = ...
            negativeIndices(firstInvalid);

        boundaryNegative_deg(frequencyCase) = ...
            testAngles_deg(invalidIndex + 1);

    end

end

%% ============================================================
% PRINT BOUNDARY
% =============================================================

fprintf('\n');

fprintf( ...
    '%12s %20s %20s %20s\n', ...
    'Frequency', ...
    'Negative Boundary', ...
    'Positive Boundary', ...
    'Symmetric Limit');

fprintf('%s\n', ...
    repmat('-', 1, 80));

for frequencyCase = 1:numberOfFrequencies

    negativeBoundary = ...
        boundaryNegative_deg(frequencyCase);

    positiveBoundary = ...
        boundaryPositive_deg(frequencyCase);

    symmetricLimit = ...
        min(abs(negativeBoundary), ...
            abs(positiveBoundary));

    fprintf( ...
        '%12.2f %20.3f %20.3f %20.3f\n', ...
        testFrequencies_GHz(frequencyCase), ...
        negativeBoundary, ...
        positiveBoundary, ...
        symmetricLimit);

end

%% ============================================================
% GLOBAL ERROR SUMMARY
% =============================================================

fprintf('\n');

for frequencyCase = 1:numberOfFrequencies

    rmsError_deg = ...
        sqrt(mean( ...
            angleErrors_deg(:, frequencyCase).^2));

    maximumError_deg = ...
        max(abs( ...
            angleErrors_deg(:, frequencyCase)));

    fprintf( ...
        'Frequency = %.2f GHz : RMS = %.9f deg, Max = %.9f deg\n', ...
        testFrequencies_GHz(frequencyCase), ...
        rmsError_deg, ...
        maximumError_deg);

end

%% ============================================================
% SAVE RESULTS
% =============================================================

results.frequency_GHz = ...
    testFrequencies_GHz;

results.angles_deg = ...
    testAngles_deg;

results.estimatedAngles_deg = ...
    estimatedAngles_deg;

results.angleErrors_deg = ...
    angleErrors_deg;

results.validMask = ...
    validMask;

results.boundaryNegative_deg = ...
    boundaryNegative_deg;

results.boundaryPositive_deg = ...
    boundaryPositive_deg;

results.elementSpacing_m = ...
    geometry.elementSpacing_m;

results.referenceFrequency_Hz = ...
    cfg.antenna.referenceFrequency_Hz;

save( ...
    'M08_7_5_aoa_angle_boundary_results.mat', ...
    'results');

fprintf('\n');

fprintf('Results saved to:\n');
fprintf('M08_7_5_aoa_angle_boundary_results.mat\n');

fprintf('\n');

fprintf('============================================================\n');
fprintf('M08.7.5 CHARACTERIZATION COMPLETE\n');
fprintf('============================================================\n');