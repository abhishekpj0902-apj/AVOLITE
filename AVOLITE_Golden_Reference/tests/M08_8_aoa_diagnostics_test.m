clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

geometry = create_ula_geometry(cfg);

%% ============================================================
% TEST CASE
% =============================================================

frequency_Hz = 10e9;

trueAngle_deg = 30;

trueAngle_rad = deg2rad(trueAngle_deg);

numberOfSamples = 10000;

signalAmplitude = 1.0;

x_waveform = ...
    signalAmplitude * ones(numberOfSamples, 1);

%% ============================================================
% ARRAY SIGNAL
% =============================================================

x_array = ...
    apply_ula_steering( ...
        x_waveform, ...
        geometry, ...
        frequency_Hz, ...
        trueAngle_rad);

%% ============================================================
% AOA ESTIMATION
% =============================================================

[estimatedAngle_deg, info] = ...
    estimate_ula_aoa( ...
        x_array, ...
        frequency_Hz, ...
        geometry, ...
        cfg);

%% ============================================================
% EXPECTED PHYSICAL VALUES
% =============================================================

c_mps = cfg.constants.c_mps;

lambda_m = ...
    c_mps / frequency_Hz;

k = ...
    2 * pi / lambda_m;

d_m = ...
    geometry.elementSpacing_m;

expectedPhaseDifference_rad = ...
    -k * d_m * sin(trueAngle_rad);

expectedPhaseDifference_deg = ...
    rad2deg(expectedPhaseDifference_rad);

expectedSinTheta = ...
    sin(trueAngle_rad);

%% ============================================================
% ACTUAL DIAGNOSTICS
% =============================================================

measuredWavelength_m = ...
    info.wavelength_m;

measuredSpacing_m = ...
    info.elementSpacing_m;

measuredPhaseDifference_rad = ...
    info.phaseDifference_rad;

measuredPhaseDifference_deg = ...
    info.phaseDifference_deg;

measuredSinThetaRaw = ...
    info.sinThetaRaw;

measuredSinThetaClamped = ...
    info.sinThetaClamped;

measuredAngle_rad = ...
    info.estimatedAngle_rad;

measuredAngle_deg = ...
    info.estimatedAngle_deg;

%% ============================================================
% CALCULATED ERRORS
% =============================================================

wavelengthError_m = ...
    measuredWavelength_m - lambda_m;

spacingError_m = ...
    measuredSpacing_m - d_m;

phaseError_rad = ...
    measuredPhaseDifference_rad - ...
    expectedPhaseDifference_rad;

phaseError_deg = ...
    measuredPhaseDifference_deg - ...
    expectedPhaseDifference_deg;

sinThetaRawError = ...
    measuredSinThetaRaw - ...
    expectedSinTheta;

sinThetaClampedError = ...
    measuredSinThetaClamped - ...
    expectedSinTheta;

angleRadError = ...
    measuredAngle_rad - trueAngle_rad;

angleDegError = ...
    measuredAngle_deg - trueAngle_deg;

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.8 AOA DIAGNOSTICS VERIFICATION\n');
fprintf('============================================================\n');

%% ============================================================
% BASIC INFORMATION
% =============================================================

fprintf('\n');

fprintf('Estimator method           = %s\n', ...
    info.method);

fprintf('Frequency                  = %.6f GHz\n', ...
    frequency_Hz / 1e9);

fprintf('True angle                 = %.9f deg\n', ...
    trueAngle_deg);

fprintf('Estimated angle            = %.9f deg\n', ...
    estimatedAngle_deg);

%% ============================================================
% WAVELENGTH / ARRAY
% =============================================================

fprintf('\n');

fprintf('Expected wavelength        = %.15f m\n', ...
    lambda_m);

fprintf('Measured wavelength        = %.15f m\n', ...
    measuredWavelength_m);

fprintf('Wavelength error           = %.12e m\n', ...
    wavelengthError_m);

fprintf('\n');

fprintf('Expected element spacing   = %.15f m\n', ...
    d_m);

fprintf('Measured element spacing   = %.15f m\n', ...
    measuredSpacing_m);

fprintf('Element spacing error      = %.12e m\n', ...
    spacingError_m);

fprintf('Number of elements         = %d\n', ...
    info.numberOfElements);

%% ============================================================
% PHASE DIFFERENCE
% =============================================================

fprintf('\n');

fprintf('Expected phase difference  = %.15f rad\n', ...
    expectedPhaseDifference_rad);

fprintf('Measured phase difference = %.15f rad\n', ...
    measuredPhaseDifference_rad);

fprintf('Phase error                = %.12e rad\n', ...
    phaseError_rad);

fprintf('\n');

fprintf('Expected phase difference  = %.15f deg\n', ...
    expectedPhaseDifference_deg);

fprintf('Measured phase difference = %.15f deg\n', ...
    measuredPhaseDifference_deg);

fprintf('Phase error                = %.12e deg\n', ...
    phaseError_deg);

%% ============================================================
% ADJACENT PHASE DIFFERENCES
% =============================================================

fprintf('\n');

fprintf('Adjacent phase differences [rad]:\n');

disp(info.adjacentPhaseDifference_rad);

fprintf('Phase residuals [rad]:\n');

disp(info.phaseDifferenceResidual_rad);

fprintf('Maximum phase residual     = %.12e rad\n', ...
    max(abs(info.phaseDifferenceResidual_rad)));

%% ============================================================
% SIN THETA
% =============================================================

fprintf('\n');

fprintf('Expected sin(theta)        = %.15f\n', ...
    expectedSinTheta);

fprintf('Raw sin(theta)             = %.15f\n', ...
    measuredSinThetaRaw);

fprintf('Clamped sin(theta)         = %.15f\n', ...
    measuredSinThetaClamped);

fprintf('Raw sin(theta) error       = %.12e\n', ...
    sinThetaRawError);

fprintf('Clamped sin(theta) error   = %.12e\n', ...
    sinThetaClampedError);

%% ============================================================
% ANGLE
% =============================================================

fprintf('\n');

fprintf('Expected angle             = %.15f deg\n', ...
    trueAngle_deg);

fprintf('Estimated angle            = %.15f deg\n', ...
    measuredAngle_deg);

fprintf('Angle error                = %.12e deg\n', ...
    angleDegError);

fprintf('\n');

fprintf('Expected angle             = %.15f rad\n', ...
    trueAngle_rad);

fprintf('Estimated angle            = %.15f rad\n', ...
    measuredAngle_rad);

fprintf('Angle error                = %.12e rad\n', ...
    angleRadError);

%% ============================================================
% GROUND-TRUTH ISOLATION
% =============================================================

fprintf('\n');

fprintf('Ground truth used          = %d\n', ...
    info.groundTruthUsed);

%% ============================================================
% REQUIRED FIELD CHECK
% =============================================================

requiredFields = { ...
    'method', ...
    'frequency_Hz', ...
    'wavelength_m', ...
    'elementSpacing_m', ...
    'numberOfElements', ...
    'phaseDifference_rad', ...
    'phaseDifference_deg', ...
    'adjacentPhaseDifference_rad', ...
    'phaseDifferenceResidual_rad', ...
    'sinThetaRaw', ...
    'sinThetaClamped', ...
    'estimatedAngle_rad', ...
    'estimatedAngle_deg', ...
    'maxAbsAngle_deg', ...
    'groundTruthUsed'};

missingFields = {};

for fieldCase = 1:numel(requiredFields)

    fieldName = requiredFields{fieldCase};

    if ~isfield(info, fieldName)

        missingFields{end+1} = ...
            fieldName; %#ok<SAGROW>

    end

end

%% ============================================================
% VERIFICATION CRITERIA
% =============================================================
%
% These are numerical consistency tolerances for this
% deterministic mathematical verification.
%
% They are NOT project-level AoA performance requirements.

wavelengthTolerance_m = 1e-12;

spacingTolerance_m = 1e-12;

phaseTolerance_rad = 1e-10;

phaseTolerance_deg = 1e-8;

sinThetaTolerance = 1e-10;

angleTolerance_rad = 1e-10;

angleTolerance_deg = 1e-8;

residualTolerance_rad = 1e-10;

%% ============================================================
% INDIVIDUAL CHECKS
% =============================================================

wavelengthPass = ...
    abs(wavelengthError_m) <= wavelengthTolerance_m;

spacingPass = ...
    abs(spacingError_m) <= spacingTolerance_m;

phaseRadPass = ...
    abs(phaseError_rad) <= phaseTolerance_rad;

phaseDegPass = ...
    abs(phaseError_deg) <= phaseTolerance_deg;

sinThetaRawPass = ...
    abs(sinThetaRawError) <= sinThetaTolerance;

sinThetaClampedPass = ...
    abs(sinThetaClampedError) <= sinThetaTolerance;

angleRadPass = ...
    abs(angleRadError) <= angleTolerance_rad;

angleDegPass = ...
    abs(angleDegError) <= angleTolerance_deg;

residualPass = ...
    max(abs(info.phaseDifferenceResidual_rad)) ...
    <= residualTolerance_rad;

groundTruthPass = ...
    info.groundTruthUsed == false;

fieldsPass = ...
    isempty(missingFields);

%% ============================================================
% PRINT CHECK RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M08.8 INTERNAL CONSISTENCY RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Diagnostic fields          = %s\n', ...
    passFailText(fieldsPass));

fprintf('Wavelength consistency     = %s\n', ...
    passFailText(wavelengthPass));

fprintf('Element spacing consistency= %s\n', ...
    passFailText(spacingPass));

fprintf('Phase consistency [rad]    = %s\n', ...
    passFailText(phaseRadPass));

fprintf('Phase consistency [deg]    = %s\n', ...
    passFailText(phaseDegPass));

fprintf('Raw sin(theta) consistency = %s\n', ...
    passFailText(sinThetaRawPass));

fprintf('Clamped sin(theta)         = %s\n', ...
    passFailText(sinThetaClampedPass));

fprintf('Angle consistency [rad]    = %s\n', ...
    passFailText(angleRadPass));

fprintf('Angle consistency [deg]    = %s\n', ...
    passFailText(angleDegPass));

fprintf('Phase residual consistency  = %s\n', ...
    passFailText(residualPass));

fprintf('Ground-truth isolation      = %s\n', ...
    passFailText(groundTruthPass));

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    fieldsPass && ...
    wavelengthPass && ...
    spacingPass && ...
    phaseRadPass && ...
    phaseDegPass && ...
    sinThetaRawPass && ...
    sinThetaClampedPass && ...
    angleRadPass && ...
    angleDegPass && ...
    residualPass && ...
    groundTruthPass;

fprintf('\n');

if overallPass

    fprintf('M08.8 RESULT = PASS\n');

else

    fprintf('M08.8 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M08.8 AOA DIAGNOSTICS VERIFICATION COMPLETE\n');
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