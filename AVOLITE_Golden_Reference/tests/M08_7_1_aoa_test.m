clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

cfg = config_AVOLITE();

%% ============================================================
% ARRAY
% =============================================================

geometry = ...
    create_ula_geometry(cfg);

%% ============================================================
% TEST PARAMETERS
% =============================================================

frequency_Hz = ...
    cfg.antenna.referenceFrequency_Hz;

testAngles_deg = [ ...
    -60 ...
    -30 ...
      0 ...
     30 ...
     60];

numberOfSamples = ...
    10000;

%% ============================================================
% RESULTS
% =============================================================

numberOfCases = ...
    numel(testAngles_deg);

estimatedAngles_deg = ...
    zeros(numberOfCases,1);

angleErrors_deg = ...
    zeros(numberOfCases,1);

%% ============================================================
% TEST LOOP
% =============================================================

for caseIndex = 1:numberOfCases

    trueAngle_deg = ...
        testAngles_deg(caseIndex);

    trueAngle_rad = ...
        deg2rad(trueAngle_deg);

    %% --------------------------------------------------------
    % GENERATE ARRAY-RECEIVED SIGNAL
    % --------------------------------------------------------
    %
    % The true angle is used ONLY to generate the verification
    % input. It is NOT passed into the estimator.
    %

    basebandSignal = ...
        ones(numberOfSamples,1);

    x_array = ...
        apply_ula_steering( ...
            basebandSignal, ...
            geometry, ...
            frequency_Hz, ...
            trueAngle_rad);

    %% --------------------------------------------------------
    % ESTIMATE AOA
    % --------------------------------------------------------

    [estimatedAngle_deg, estimatorInfo] = ...
        estimate_ula_aoa( ...
            x_array, ...
            frequency_Hz, ...
            geometry, ...
            cfg);

    %% --------------------------------------------------------
    % CALCULATE VERIFICATION ERROR
    % --------------------------------------------------------

    angleError_deg = ...
        estimatedAngle_deg - ...
        trueAngle_deg;

    estimatedAngles_deg(caseIndex) = ...
        estimatedAngle_deg;

    angleErrors_deg(caseIndex) = ...
        angleError_deg;

end

%% ============================================================
% DISPLAY RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.7.1 ULA AOA DETERMINISTIC VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('Array elements       = %d\n', ...
    geometry.numberOfElements);

fprintf('Element spacing      = %.12f m\n', ...
    geometry.elementSpacing_m);

fprintf('RF frequency         = %.6f GHz\n', ...
    frequency_Hz / 1e9);

fprintf('\n');

fprintf('%15s %20s %20s\n', ...
    'True Angle', ...
    'Estimated Angle', ...
    'Error');

fprintf('%s\n', ...
    repmat('-',1,65));

for k = 1:numberOfCases

    fprintf('%15.6f %20.9f %20.9f\n', ...
        testAngles_deg(k), ...
        estimatedAngles_deg(k), ...
        angleErrors_deg(k));

end

%% ============================================================
% MAXIMUM ERROR
% =============================================================

maximumAbsoluteError_deg = ...
    max(abs(angleErrors_deg));

fprintf('\n');

fprintf('Maximum absolute AoA error = %.12f deg\n', ...
    maximumAbsoluteError_deg);

fprintf('Ground truth used internally by estimator = %d\n', ...
    estimatorInfo.groundTruthUsed);

%% ============================================================
% PHASE-DIFFERENCE DIAGNOSTICS
% =============================================================

fprintf('\nLast-case estimator diagnostics:\n');

fprintf('Estimated phase difference = %.12f deg\n', ...
    estimatorInfo.phaseDifference_deg);

fprintf('Estimated sin(theta)       = %.12f\n', ...
    estimatorInfo.sinThetaClamped);

fprintf('Estimated angle            = %.12f deg\n', ...
    estimatorInfo.estimatedAngle_deg);

fprintf('Maximum phase residual     = %.12e rad\n', ...
    max(abs(estimatorInfo.phaseDifferenceResidual_rad)));

%% ============================================================
% VERIFICATION
% =============================================================

if maximumAbsoluteError_deg < 1e-9

    fprintf('\nM08.7.1 RESULT = PASS\n');

else

    fprintf('\nM08.7.1 RESULT = REVIEW\n');

end

fprintf('============================================================\n');