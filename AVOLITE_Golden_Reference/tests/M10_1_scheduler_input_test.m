clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

clear validate_scheduler_input;
rehash;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.1 SCHEDULER INPUT INTERFACE VERIFICATION\n');
fprintf('============================================================\n');

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

%% ============================================================
% VALID SCHEDULER STATE
% =============================================================

schedulerState = struct();

schedulerState.currentFrequency_Hz = 5e9;
schedulerState.previousFrequency_Hz = 4e9;

schedulerState.detectionHistory = ...
    [1 1 0 1 0];

schedulerState.hitHistory = ...
    [1 1 0 1 0];

schedulerState.snr_dB = 20;

schedulerState.receivedPower_dBm = -50;

schedulerState.noiseFloor_dBm = -80;

schedulerState.pulseWidth_s = 1e-6;

schedulerState.PRI_s = 1e-3;

schedulerState.frequencyHistory_Hz = ...
    [4e9 5e9 4e9];

schedulerState.emitterActivityProbability = 0.8;

schedulerState.aoa_deg = 30;

schedulerState.environmentState = struct();

schedulerState.timeSinceLastObservation_s = 0.002;

%% ============================================================
% VALID CONTROL
% =============================================================

[valid, info] = ...
    validate_scheduler_input( ...
        schedulerState, ...
        cfg);

fprintf('\nValid scheduler input:\n');
fprintf('    Result = %s\n', passFailText(valid));

if ~valid

    fprintf('    Error  = %s\n', info.errorMessage);

end

%% ============================================================
% TEST DEFINITIONS
% =============================================================

testNames = { ...
    'Valid scheduler state'
    'Missing current frequency'
    'Invalid activity probability'
    'Negative current frequency'
    'Negative dwell-related time'
    'Empty detection history'
    'Invalid environment state'
    'Invalid configuration type'};

testPass = false(numel(testNames),1);

%% ============================================================
% TEST 1 — VALID
% =============================================================

testPass(1) = valid;

%% ============================================================
% TEST 2 — MISSING FIELD
% =============================================================

testState = schedulerState;

testState = rmfield( ...
    testState, ...
    'currentFrequency_Hz');

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        testState, ...
        cfg);

testPass(2) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:MissingField");

%% ============================================================
% TEST 3 — INVALID ACTIVITY PROBABILITY
% =============================================================

testState = schedulerState;

testState.emitterActivityProbability = 1.5;

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        testState, ...
        cfg);

testPass(3) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:InvalidActivityProbability");

%% ============================================================
% TEST 4 — NEGATIVE FREQUENCY
% =============================================================

testState = schedulerState;

testState.currentFrequency_Hz = -1;

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        testState, ...
        cfg);

testPass(4) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:InvalidFrequency");

%% ============================================================
% TEST 5 — NEGATIVE OBSERVATION TIME
% =============================================================

testState = schedulerState;

testState.timeSinceLastObservation_s = -1;

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        testState, ...
        cfg);

testPass(5) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:InvalidObservationTime");

%% ============================================================
% TEST 6 — EMPTY DETECTION HISTORY
% =============================================================

testState = schedulerState;

testState.detectionHistory = [];

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        testState, ...
        cfg);

testPass(6) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:EmptyDetectionHistory");

%% ============================================================
% TEST 7 — INVALID ENVIRONMENT STATE
% =============================================================

testState = schedulerState;

testState.environmentState = [];

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        testState, ...
        cfg);

testPass(7) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:InvalidEnvironmentState");

%% ============================================================
% TEST 8 — INVALID CONFIGURATION TYPE
% ============================================================

[validTest, infoTest] = ...
    validate_scheduler_input( ...
        schedulerState, ...
        []);

testPass(8) = ...
    ~validTest && ...
    strcmp( ...
        infoTest.errorIdentifier, ...
        "validate_scheduler_input:InvalidConfiguration");

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.1 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('%-45s %10s\n', ...
    'Test condition', ...
    'Result');

fprintf('%s\n', ...
    repmat('-',1,60));

for k = 1:numel(testNames)

    fprintf('%-45s %10s\n', ...
        testNames{k}, ...
        passFailText(testPass(k)));

end

allPass = all(testPass);

fprintf('\n');

fprintf('Passed tests = %d / %d\n', ...
    sum(testPass), ...
    numel(testPass));

fprintf('\n');

if allPass

    fprintf('M10.1 RESULT = PASS\n');

else

    fprintf('M10.1 RESULT = REVIEW\n');

end

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.1 SCHEDULER INPUT INTERFACE VERIFICATION COMPLETE\n');
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