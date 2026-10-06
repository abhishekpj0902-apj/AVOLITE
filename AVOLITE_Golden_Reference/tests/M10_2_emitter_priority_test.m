clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

clear calculate_emitter_priority;
rehash;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.2 EMITTER PRIORITY VERIFICATION\n');
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
    [1 1 1 0 1];

state.hitHistory = ...
    [1 1 0 1 1];

state.snr_dB = 20;

state.receivedPower_dBm = -30;

state.noiseFloor_dBm = -80;

state.pulseWidth_s = 1e-6;

state.PRI_s = 1e-3;

state.frequencyHistory_Hz = ...
    [4e9 5e9 4e9];

state.emitterActivityProbability = 1;

state.aoa_deg = 30;

state.environmentState = struct();

state.timeSinceLastObservation_s = 10e-3;

%% ============================================================
% TEST 1 — BASELINE
% =============================================================

[priority1, info1] = ...
    calculate_emitter_priority( ...
        state, cfg);

baselinePass = ...
    isfinite(priority1) && ...
    priority1 >= 0 && ...
    priority1 <= 1;

fprintf('\nM10.2.1 Baseline priority:\n');
fprintf('    Priority = %.12f\n', priority1);
fprintf('    Result   = %s\n', ...
    passFailText(baselinePass));

%% ============================================================
% TEST 2 — ZERO-ACTIVITY STATE
% =============================================================

stateLow = state;

stateLow.detectionHistory = ...
    zeros(size(state.detectionHistory));

stateLow.hitHistory = ...
    zeros(size(state.hitHistory));

stateLow.snr_dB = 0;

stateLow.receivedPower_dBm = -100;

stateLow.emitterActivityProbability = 0;

stateLow.timeSinceLastObservation_s = 0;

[priorityLow, infoLow] = ...
    calculate_emitter_priority( ...
        stateLow, cfg);

lowStatePass = ...
    priorityLow >= 0 && ...
    priorityLow < priority1;

fprintf('\nM10.2.2 Low-priority state:\n');
fprintf('    Priority = %.12f\n', priorityLow);
fprintf('    Result   = %s\n', ...
    passFailText(lowStatePass));

%% ============================================================
% TEST 3 — MAXIMUM PRIORITY STATE
% =============================================================

stateHigh = state;

stateHigh.detectionHistory = ...
    ones(size(state.detectionHistory));

stateHigh.hitHistory = ...
    ones(size(state.hitHistory));

stateHigh.snr_dB = 20;

stateHigh.receivedPower_dBm = -30;

stateHigh.emitterActivityProbability = 1;

stateHigh.timeSinceLastObservation_s = 10e-3;

[priorityHigh, infoHigh] = ...
    calculate_emitter_priority( ...
        stateHigh, cfg);

maximumStatePass = ...
    abs(priorityHigh - 1) < 1e-12;

fprintf('\nM10.2.3 Maximum-priority state:\n');
fprintf('    Priority = %.12f\n', priorityHigh);
fprintf('    Result   = %s\n', ...
    passFailText(maximumStatePass));

%% ============================================================
% TEST 4 — ACTIVITY MONOTONICITY
% =============================================================

activityValues = ...
    [0 0.25 0.5 0.75 1];

activityPriority = ...
    zeros(size(activityValues));

for k = 1:numel(activityValues)

    testState = state;

    testState.emitterActivityProbability = ...
        activityValues(k);

    [activityPriority(k), ~] = ...
        calculate_emitter_priority( ...
            testState, cfg);

end

activityMonotonic = ...
    all(diff(activityPriority) >= -1e-12);

fprintf('\nM10.2.4 Activity monotonicity:\n');

for k = 1:numel(activityValues)

    fprintf( ...
        '    Activity %.2f -> Priority %.12f\n', ...
        activityValues(k), ...
        activityPriority(k));

end

fprintf('    Result = %s\n', ...
    passFailText(activityMonotonic));

%% ============================================================
% TEST 5 — OBSERVATION AGE MONOTONICITY
% =============================================================

ageValues = ...
    [0 1e-3 2e-3 5e-3 10e-3];

agePriority = ...
    zeros(size(ageValues));

for k = 1:numel(ageValues)

    testState = state;

    testState.timeSinceLastObservation_s = ...
        ageValues(k);

    [agePriority(k), ~] = ...
        calculate_emitter_priority( ...
            testState, cfg);

end

ageMonotonic = ...
    all(diff(agePriority) >= -1e-12);

fprintf('\nM10.2.5 Observation-age monotonicity:\n');

for k = 1:numel(ageValues)

    fprintf( ...
        '    Age %.6f s -> Priority %.12f\n', ...
        ageValues(k), ...
        agePriority(k));

end

fprintf('    Result = %s\n', ...
    passFailText(ageMonotonic));

%% ============================================================
% TEST 6 — DETERMINISM
% =============================================================

[priorityRepeat, infoRepeat] = ...
    calculate_emitter_priority( ...
        state, cfg);

deterministicPass = ...
    abs(priorityRepeat - priority1) < 1e-15;

fprintf('\nM10.2.6 Determinism:\n');
fprintf('    First  = %.15f\n', priority1);
fprintf('    Repeat = %.15f\n', priorityRepeat);
fprintf('    Result = %s\n', ...
    passFailText(deterministicPass));

%% ============================================================
% TEST 7 — COMPONENT RANGE
% =============================================================

componentValues = [ ...
    info1.activityComponent
    info1.detectionComponent
    info1.hitComponent
    info1.snrComponent
    info1.powerComponent
    info1.observationAgeComponent];

componentRangePass = ...
    all(componentValues >= 0) && ...
    all(componentValues <= 1);

fprintf('\nM10.2.7 Component range:\n');

fprintf('    Activity       = %.6f\n', ...
    info1.activityComponent);

fprintf('    Detection      = %.6f\n', ...
    info1.detectionComponent);

fprintf('    Hit            = %.6f\n', ...
    info1.hitComponent);

fprintf('    SNR            = %.6f\n', ...
    info1.snrComponent);

fprintf('    Power          = %.6f\n', ...
    info1.powerComponent);

fprintf('    ObservationAge = %.6f\n', ...
    info1.observationAgeComponent);

fprintf('    Result         = %s\n', ...
    passFailText(componentRangePass));

%% ============================================================
% FINAL RESULT
% =============================================================

allPass = ...
    baselinePass && ...
    lowStatePass && ...
    maximumStatePass && ...
    activityMonotonic && ...
    ageMonotonic && ...
    deterministicPass && ...
    componentRangePass;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.2 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Baseline priority          = %s\n', ...
    passFailText(baselinePass));

fprintf('Low-priority behavior      = %s\n', ...
    passFailText(lowStatePass));

fprintf('Maximum-priority behavior  = %s\n', ...
    passFailText(maximumStatePass));

fprintf('Activity monotonicity      = %s\n', ...
    passFailText(activityMonotonic));

fprintf('Age monotonicity            = %s\n', ...
    passFailText(ageMonotonic));

fprintf('Determinism                = %s\n', ...
    passFailText(deterministicPass));

fprintf('Component ranges           = %s\n', ...
    passFailText(componentRangePass));

fprintf('\n');

if allPass

    fprintf('M10.2 RESULT = PASS\n');

else

    fprintf('M10.2 RESULT = REVIEW\n');

end

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.2 EMITTER PRIORITY VERIFICATION COMPLETE\n');
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