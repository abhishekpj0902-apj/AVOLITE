clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

clear calculate_emitter_uncertainty;
rehash;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.3 EMITTER UNCERTAINTY VERIFICATION\n');
fprintf('============================================================\n');

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

%% ============================================================
% BASELINE STATE
% =============================================================

state = struct();

state.currentFrequency_Hz = 5e9;
state.previousFrequency_Hz = 4e9;

state.detectionHistory = ...
    [1 1 0 1 0];

state.hitHistory = ...
    [1 0 1 0 1];

state.snr_dB = 20;

state.receivedPower_dBm = -50;

state.noiseFloor_dBm = -80;

state.pulseWidth_s = 1e-6;

state.PRI_s = 1e-3;

state.frequencyHistory_Hz = ...
    [4e9 5e9 4e9 5e9];

state.emitterActivityProbability = 0.5;

state.aoa_deg = 30;

state.environmentState = struct();

state.timeSinceLastObservation_s = 5e-3;

%% ============================================================
% TEST 1 — BASELINE
% =============================================================

[uncertainty1, info1] = ...
    calculate_emitter_uncertainty( ...
        state, cfg);

baselinePass = ...
    isfinite(uncertainty1) && ...
    uncertainty1 >= 0 && ...
    uncertainty1 <= 1;

fprintf('\nM10.3.1 Baseline uncertainty:\n');
fprintf('    Uncertainty = %.12f\n', uncertainty1);
fprintf('    Result      = %s\n', ...
    passFailText(baselinePass));

%% ============================================================
% TEST 2 — LOW-UNCERTAINTY STATE
% =============================================================

stateLow = state;

stateLow.detectionHistory = ...
    ones(size(state.detectionHistory));

stateLow.hitHistory = ...
    ones(size(state.hitHistory));

stateLow.emitterActivityProbability = 1;

stateLow.timeSinceLastObservation_s = 0;

stateLow.frequencyHistory_Hz = ...
    5e9 .* ones(size(state.frequencyHistory_Hz));

[uncertaintyLow, infoLow] = ...
    calculate_emitter_uncertainty( ...
        stateLow, cfg);

lowUncertaintyPass = ...
    uncertaintyLow < uncertainty1;

fprintf('\nM10.3.2 Low-uncertainty state:\n');
fprintf('    Uncertainty = %.12f\n', uncertaintyLow);
fprintf('    Result      = %s\n', ...
    passFailText(lowUncertaintyPass));

%% ============================================================
% TEST 3 — HIGH-UNCERTAINTY STATE
% =============================================================

stateHigh = state;

stateHigh.detectionHistory = ...
    [1 0 1 0];

stateHigh.hitHistory = ...
    [1 0 1 0];

stateHigh.emitterActivityProbability = 0.5;

stateHigh.timeSinceLastObservation_s = ...
    10e-3;

stateHigh.frequencyHistory_Hz = ...
    [1e9 2e9 1e9 2e9];

[uncertaintyHigh, infoHigh] = ...
    calculate_emitter_uncertainty( ...
        stateHigh, cfg);

highUncertaintyPass = ...
    uncertaintyHigh > uncertainty1;

fprintf('\nM10.3.3 High-uncertainty state:\n');
fprintf('    Uncertainty = %.12f\n', uncertaintyHigh);
fprintf('    Result      = %s\n', ...
    passFailText(highUncertaintyPass));

%% ============================================================
% TEST 4 — DETECTION-HISTORY SENSITIVITY
% =============================================================

stateDetectionCertain = state;

stateDetectionCertain.detectionHistory = ...
    ones(size(state.detectionHistory));

stateDetectionCertain.hitHistory = ...
    ones(size(state.hitHistory));

[uncertainCertain, ~] = ...
    calculate_emitter_uncertainty( ...
        stateDetectionCertain, cfg);

stateDetectionAmbiguous = state;

stateDetectionAmbiguous.detectionHistory = ...
    [1 0 1 0];

stateDetectionAmbiguous.hitHistory = ...
    [1 0 1 0];

[uncertainAmbiguous, ~] = ...
    calculate_emitter_uncertainty( ...
        stateDetectionAmbiguous, cfg);

detectionSensitivityPass = ...
    uncertainAmbiguous > uncertainCertain;

fprintf('\nM10.3.4 Detection-history sensitivity:\n');
fprintf('    Certain history    = %.12f\n', ...
    uncertainCertain);
fprintf('    Ambiguous history  = %.12f\n', ...
    uncertainAmbiguous);
fprintf('    Result             = %s\n', ...
    passFailText(detectionSensitivityPass));

%% ============================================================
% TEST 5 — OBSERVATION-AGE SENSITIVITY
% =============================================================

ageValues = ...
    [0 1e-3 2e-3 5e-3 10e-3];

ageUncertainty = ...
    zeros(size(ageValues));

for k = 1:numel(ageValues)

    testState = state;

    testState.timeSinceLastObservation_s = ...
        ageValues(k);

    [ageUncertainty(k), ~] = ...
        calculate_emitter_uncertainty( ...
            testState, cfg);

end

ageMonotonic = ...
    all(diff(ageUncertainty) >= -1e-12);

fprintf('\nM10.3.5 Observation-age sensitivity:\n');

for k = 1:numel(ageValues)

    fprintf( ...
        '    Age %.6f s -> Uncertainty %.12f\n', ...
        ageValues(k), ...
        ageUncertainty(k));

end

fprintf('    Result = %s\n', ...
    passFailText(ageMonotonic));

%% ============================================================
% TEST 6 — FREQUENCY-VARIABILITY SENSITIVITY
% =============================================================

stateStableFrequency = state;

stateStableFrequency.frequencyHistory_Hz = ...
    5e9 .* ones(size(state.frequencyHistory_Hz));

[uncertaintyStableFrequency, ~] = ...
    calculate_emitter_uncertainty( ...
        stateStableFrequency, cfg);

stateAgileFrequency = state;

stateAgileFrequency.frequencyHistory_Hz = ...
    [1e9 2e9 1e9 2e9];

[uncertaintyAgileFrequency, ~] = ...
    calculate_emitter_uncertainty( ...
        stateAgileFrequency, cfg);

frequencySensitivityPass = ...
    uncertaintyAgileFrequency > ...
    uncertaintyStableFrequency;

fprintf('\nM10.3.6 Frequency-variability sensitivity:\n');
fprintf('    Stable frequency = %.12f\n', ...
    uncertaintyStableFrequency);
fprintf('    Agile frequency  = %.12f\n', ...
    uncertaintyAgileFrequency);
fprintf('    Result            = %s\n', ...
    passFailText(frequencySensitivityPass));

%% ============================================================
% TEST 7 — DETERMINISM
% =============================================================

[uncertaintyRepeat, ~] = ...
    calculate_emitter_uncertainty( ...
        state, cfg);

deterministicPass = ...
    abs(uncertaintyRepeat - uncertainty1) < 1e-15;

fprintf('\nM10.3.7 Determinism:\n');
fprintf('    First  = %.15f\n', uncertainty1);
fprintf('    Repeat = %.15f\n', uncertaintyRepeat);
fprintf('    Result = %s\n', ...
    passFailText(deterministicPass));

%% ============================================================
% TEST 8 — COMPONENT RANGE
% =============================================================

componentValues = [ ...
    info1.detectionUncertainty
    info1.hitUncertainty
    info1.activityUncertainty
    info1.observationAgeUncertainty
    info1.frequencyVariabilityComponent];

componentRangePass = ...
    all(componentValues >= 0) && ...
    all(componentValues <= 1);

fprintf('\nM10.3.8 Component range:\n');

fprintf('    Detection uncertainty       = %.6f\n', ...
    info1.detectionUncertainty);

fprintf('    Hit uncertainty             = %.6f\n', ...
    info1.hitUncertainty);

fprintf('    Activity uncertainty        = %.6f\n', ...
    info1.activityUncertainty);

fprintf('    Observation-age uncertainty = %.6f\n', ...
    info1.observationAgeUncertainty);

fprintf('    Frequency variability       = %.6f\n', ...
    info1.frequencyVariabilityComponent);

fprintf('    Result                      = %s\n', ...
    passFailText(componentRangePass));

%% ============================================================
% FINAL RESULT
% =============================================================

allPass = ...
    baselinePass && ...
    lowUncertaintyPass && ...
    highUncertaintyPass && ...
    detectionSensitivityPass && ...
    ageMonotonic && ...
    frequencySensitivityPass && ...
    deterministicPass && ...
    componentRangePass;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.3 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Baseline uncertainty       = %s\n', ...
    passFailText(baselinePass));

fprintf('Low-uncertainty behavior   = %s\n', ...
    passFailText(lowUncertaintyPass));

fprintf('High-uncertainty behavior  = %s\n', ...
    passFailText(highUncertaintyPass));

fprintf('Detection sensitivity      = %s\n', ...
    passFailText(detectionSensitivityPass));

fprintf('Age monotonicity           = %s\n', ...
    passFailText(ageMonotonic));

fprintf('Frequency sensitivity      = %s\n', ...
    passFailText(frequencySensitivityPass));

fprintf('Determinism                = %s\n', ...
    passFailText(deterministicPass));

fprintf('Component ranges           = %s\n', ...
    passFailText(componentRangePass));

fprintf('\n');

if allPass

    fprintf('M10.3 RESULT = PASS\n');

else

    fprintf('M10.3 RESULT = REVIEW\n');

end

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.3 EMITTER UNCERTAINTY VERIFICATION COMPLETE\n');
fprintf('============================================================\n');

%% ============================================================
% LOCAL FUNCTION
% ============================================================

function text = passFailText(value)

if value
    text = 'PASS';
else
    text = 'FAIL';
end

end