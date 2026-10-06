function result = M10_8_scheduler_decision_test()
% M10_8_SCHEDULER_DECISION_TEST
% Complete M10.8 verification of the integrated scheduler.
%
% Integrates:
%   M10.1 Scheduler input validation
%   M10.2 Emitter priority
%   M10.3 Emitter uncertainty
%   M10.4 Exploration/exploitation mode
%   M10.5 Next-frequency selection
%   M10.6 Adaptive dwell time
%   M10.7 Adaptive receiver configuration
%
% Golden Reference verification test.

clc;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.8 COMPLETE SCHEDULER DECISION VERIFICATION\n');
fprintf('============================================================\n');

%% ============================================================
% LOCATE GOLDEN REFERENCE
% =============================================================

testFile = mfilename('fullpath');

if isempty(testFile)
    error('M10_8:PathError', ...
        'Unable to determine M10.8 test file path.');
end

testDirectory = fileparts(testFile);
goldenRoot = fileparts(testDirectory);

fprintf('\nGolden Reference root:\n%s\n', goldenRoot);

%% ============================================================
% ADD REQUIRED PATHS
% =============================================================

matlabRoot = fullfile(goldenRoot, 'matlab');
configDirectory = fullfile(goldenRoot, 'config');

if ~isfolder(matlabRoot)
    error('M10_8:MissingMatlabRoot', ...
        'MATLAB directory does not exist: %s', matlabRoot);
end

if ~isfolder(configDirectory)
    error('M10_8:MissingConfigDirectory', ...
        'Config directory does not exist: %s', configDirectory);
end

addpath(genpath(matlabRoot));
addpath(configDirectory);

rehash;

%% ============================================================
% VERIFY REQUIRED FUNCTION LOCATIONS
% =============================================================

fprintf('\nFunction locations:\n');

requiredFunctions = { ...
    'run_scheduler_decision'
    'validate_scheduler_input'
    'calculate_emitter_priority'
    'calculate_emitter_uncertainty'
    'select_exploration_mode'
    'select_next_frequency'
    'calculate_adaptive_dwell_time'
    'calculate_adaptive_receiver_config'};

for k = 1:numel(requiredFunctions)

    functionName = requiredFunctions{k};

    fprintf('\n%s:\n', functionName);

    location = which(functionName, '-all');

    if isempty(location)
        error('M10_8:MissingFunction', ...
            'Required function not found: %s', functionName);
    end

    disp(location);

end

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

fprintf('\nConfiguration loaded:\n');
fprintf('    Project : %s\n', cfg.project.name);
fprintf('    Version : %s\n', cfg.project.version);

%% ============================================================
% TEST SCHEDULER INPUT
% =============================================================

schedulerInput = struct();

schedulerInput.currentFrequency_Hz = 5e9;

schedulerInput.previousFrequency_Hz = 4e9;

schedulerInput.detectionHistory = ...
    [1 1 1 0 1 1 0 1];

schedulerInput.hitHistory = ...
    [1 1 0 0 1 1 0 1];

schedulerInput.snr_dB = 12;

schedulerInput.receivedPower_dBm = -55;

schedulerInput.noiseFloor_dBm = -85;

schedulerInput.pulseWidth_s = 2e-6;

schedulerInput.PRI_s = 1e-3;

schedulerInput.frequencyHistory_Hz = ...
    [1e9 2e9 4e9 5e9];

schedulerInput.emitterActivityProbability = 0.75;

schedulerInput.aoa_deg = 20;

schedulerInput.environmentState = struct( ...
    'receivedPower_dBm', -55, ...
    'noisePower_dBm', -85, ...
    'SNR_dB', 30);

schedulerInput.timeSinceLastObservation_s = 2e-3;

%% ============================================================
% CANDIDATE FREQUENCIES
% =============================================================

candidateFrequencies_Hz = ...
    [1e9 2e9 3e9 4e9 5e9 6e9];

fprintf('\nCandidate frequencies:\n');

for k = 1:numel(candidateFrequencies_Hz)

    fprintf('    %.3f GHz\n', ...
        candidateFrequencies_Hz(k) / 1e9);

end

%% ============================================================
% M10.1 DIRECT VALIDATION
% =============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('M10.1 DIRECT VALIDATION\n');
fprintf('------------------------------------------------------------\n');

[inputValid, inputInfo] = ...
    validate_scheduler_input(schedulerInput, cfg);

fprintf('M10.1 isValid = %d\n', inputValid);

if ~inputValid

    if isstruct(inputInfo) && ...
            isfield(inputInfo, 'errorMessage')

        fprintf('Validation error: %s\n', ...
            inputInfo.errorMessage);

    end

    error('M10_8:M10_1Failed', ...
        'M10.1 scheduler input validation failed.');

end

fprintf('M10.1 RESULT = PASS\n');

%% ============================================================
% M10.8 COMPLETE PIPELINE
% =============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('M10.8 COMPLETE PIPELINE\n');
fprintf('------------------------------------------------------------\n');

[schedulerDecision, info] = ...
    run_scheduler_decision( ...
        candidateFrequencies_Hz, ...
        schedulerInput, ...
        cfg);

%% ============================================================
% M10.8.1 COMPLETE PIPELINE EXECUTION
% =============================================================

test1 = ...
    isstruct(schedulerDecision) && ...
    isfield(schedulerDecision, 'nextFrequency_Hz') && ...
    isfield(schedulerDecision, 'dwellTime_s') && ...
    isfield(schedulerDecision, 'priorityScore') && ...
    isfield(schedulerDecision, 'uncertaintyScore') && ...
    isfield(schedulerDecision, 'explorationMode') && ...
    isfield(schedulerDecision, 'explorationProbability') && ...
    isfield(schedulerDecision, 'receiverConfig') && ...
    isfinite(schedulerDecision.nextFrequency_Hz) && ...
    isfinite(schedulerDecision.dwellTime_s) && ...
    isfinite(schedulerDecision.priorityScore) && ...
    isfinite(schedulerDecision.uncertaintyScore) && ...
    isstring(schedulerDecision.explorationMode) && ...
    isstruct(schedulerDecision.receiverConfig);

fprintf('\nM10.8.1 Complete pipeline execution:\n');
fprintf('    Result = %s\n', passFailText(test1));

if ~test1
    error('M10_8:InvalidPipelineOutput', ...
        'Complete scheduler pipeline returned invalid output.');
end

%% ============================================================
% DISPLAY DECISION
% =============================================================

fprintf('\nScheduler decision:\n');

fprintf('    Next frequency          = %.6f GHz\n', ...
    schedulerDecision.nextFrequency_Hz / 1e9);

fprintf('    Dwell time              = %.6f ms\n', ...
    schedulerDecision.dwellTime_s * 1e3);

fprintf('    Priority score          = %.9f\n', ...
    schedulerDecision.priorityScore);

fprintf('    Uncertainty score       = %.9f\n', ...
    schedulerDecision.uncertaintyScore);

fprintf('    Exploration mode        = %s\n', ...
    char(schedulerDecision.explorationMode));

fprintf('    Exploration probability = %.9f\n', ...
    schedulerDecision.explorationProbability);

%% ============================================================
% M10.8.2 FREQUENCY VALIDITY
% =============================================================

frequencyValidity = ...
    any(candidateFrequencies_Hz == ...
        schedulerDecision.nextFrequency_Hz);

fprintf('\nM10.8.2 Selected frequency validity:\n');

fprintf('    Selected = %.6f GHz\n', ...
    schedulerDecision.nextFrequency_Hz / 1e9);

fprintf('    Result = %s\n', ...
    passFailText(frequencyValidity));

%% ============================================================
% M10.8.3 DWELL LIMITS
% =============================================================

dwellValidity = ...
    schedulerDecision.dwellTime_s >= ...
        cfg.scheduler.minimumDwellTime_s && ...
    schedulerDecision.dwellTime_s <= ...
        cfg.scheduler.maximumDwellTime_s;

fprintf('\nM10.8.3 Dwell-time validity:\n');

fprintf('    Dwell = %.9f ms\n', ...
    schedulerDecision.dwellTime_s * 1e3);

fprintf('    Minimum = %.9f ms\n', ...
    cfg.scheduler.minimumDwellTime_s * 1e3);

fprintf('    Maximum = %.9f ms\n', ...
    cfg.scheduler.maximumDwellTime_s * 1e3);

fprintf('    Result = %s\n', ...
    passFailText(dwellValidity));

%% ============================================================
% M10.8.4 SCORE VALIDITY
% =============================================================

scoreValidity = ...
    schedulerDecision.priorityScore >= 0 && ...
    schedulerDecision.priorityScore <= 1 && ...
    schedulerDecision.uncertaintyScore >= 0 && ...
    schedulerDecision.uncertaintyScore <= 1;

fprintf('\nM10.8.4 Scheduler score validity:\n');

fprintf('    Priority    = %.9f\n', ...
    schedulerDecision.priorityScore);

fprintf('    Uncertainty = %.9f\n', ...
    schedulerDecision.uncertaintyScore);

fprintf('    Result = %s\n', ...
    passFailText(scoreValidity));

%% ============================================================
% M10.8.5 EXPLORATION MODE VALIDITY
% =============================================================

modeValidity = ...
    schedulerDecision.explorationMode == "EXPLORE" || ...
    schedulerDecision.explorationMode == "EXPLOIT" || ...
    schedulerDecision.explorationMode == "BALANCED";

fprintf('\nM10.8.5 Exploration mode validity:\n');

fprintf('    Mode = %s\n', ...
    char(schedulerDecision.explorationMode));

fprintf('    Result = %s\n', ...
    passFailText(modeValidity));

%% ============================================================
% M10.8.6 RECEIVER CONFIGURATION VALIDITY
% =============================================================

receiverConfig = schedulerDecision.receiverConfig;

receiverValidity = ...
    isstruct(receiverConfig) && ...
    isfield(receiverConfig, 'gain_dB') && ...
    isfield(receiverConfig, 'rfFilterBandwidth_Hz') && ...
    isfield(receiverConfig, 'ifFilterBandwidth_Hz') && ...
    isfield(receiverConfig, 'mode') && ...
    isfinite(receiverConfig.gain_dB) && ...
    isfinite(receiverConfig.rfFilterBandwidth_Hz) && ...
    isfinite(receiverConfig.ifFilterBandwidth_Hz) && ...
    receiverConfig.gain_dB >= 0 && ...
    receiverConfig.rfFilterBandwidth_Hz > 0 && ...
    receiverConfig.ifFilterBandwidth_Hz > 0;

fprintf('\nM10.8.6 Receiver configuration validity:\n');

fprintf('    Gain   = %.6f dB\n', ...
    receiverConfig.gain_dB);

fprintf('    RF BW  = %.6f MHz\n', ...
    receiverConfig.rfFilterBandwidth_Hz / 1e6);

fprintf('    IF BW  = %.6f MHz\n', ...
    receiverConfig.ifFilterBandwidth_Hz / 1e6);

fprintf('    Mode   = %s\n', ...
    char(receiverConfig.mode));

fprintf('    Result = %s\n', ...
    passFailText(receiverValidity));

%% ============================================================
% M10.8.7 PIPELINE TRACE
% =============================================================

expectedPipeline = [ ...
    "validate_input"
    "calculate_priority"
    "calculate_uncertainty"
    "select_exploration_mode"
    "select_next_frequency"
    "calculate_dwell_time"
    "calculate_receiver_configuration"];

pipelineTracePass = ...
    isfield(info, 'pipeline') && ...
    isequal(info.pipeline, expectedPipeline);

fprintf('\nM10.8.7 Pipeline trace:\n');

if isfield(info, 'pipeline')

    for k = 1:numel(info.pipeline)

        fprintf('    %d. %s\n', ...
            k, char(info.pipeline(k)));

    end

end

fprintf('    Result = %s\n', ...
    passFailText(pipelineTracePass));

%% ============================================================
% M10.8.8 DETERMINISM
% =============================================================

[decisionRepeat, ~] = ...
    run_scheduler_decision( ...
        candidateFrequencies_Hz, ...
        schedulerInput, ...
        cfg);

deterministicPass = ...
    abs(decisionRepeat.nextFrequency_Hz - ...
        schedulerDecision.nextFrequency_Hz) < 1e-9 && ...
    abs(decisionRepeat.dwellTime_s - ...
        schedulerDecision.dwellTime_s) < 1e-15 && ...
    abs(decisionRepeat.priorityScore - ...
        schedulerDecision.priorityScore) < 1e-15 && ...
    abs(decisionRepeat.uncertaintyScore - ...
        schedulerDecision.uncertaintyScore) < 1e-15 && ...
    decisionRepeat.explorationMode == ...
        schedulerDecision.explorationMode && ...
    abs(decisionRepeat.explorationProbability - ...
        schedulerDecision.explorationProbability) < 1e-15 && ...
    abs(decisionRepeat.receiverConfig.gain_dB - ...
        schedulerDecision.receiverConfig.gain_dB) < 1e-12 && ...
    abs(decisionRepeat.receiverConfig.rfFilterBandwidth_Hz - ...
        schedulerDecision.receiverConfig.rfFilterBandwidth_Hz) < 1e-6 && ...
    abs(decisionRepeat.receiverConfig.ifFilterBandwidth_Hz - ...
        schedulerDecision.receiverConfig.ifFilterBandwidth_Hz) < 1e-6;

fprintf('\nM10.8.8 Determinism:\n');

fprintf('    First frequency  = %.9f GHz\n', ...
    schedulerDecision.nextFrequency_Hz / 1e9);

fprintf('    Repeat frequency = %.9f GHz\n', ...
    decisionRepeat.nextFrequency_Hz / 1e9);

fprintf('    Result = %s\n', ...
    passFailText(deterministicPass));

%% ============================================================
% FINAL RESULT
% =============================================================

allPass = ...
    test1 && ...
    frequencyValidity && ...
    dwellValidity && ...
    scoreValidity && ...
    modeValidity && ...
    receiverValidity && ...
    pipelineTracePass && ...
    deterministicPass;

fprintf('\n');
fprintf('============================================================\n');
fprintf('M10.8 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('Complete pipeline execution = %s\n', ...
    passFailText(test1));

fprintf('Selected frequency validity = %s\n', ...
    passFailText(frequencyValidity));

fprintf('Dwell-time validity         = %s\n', ...
    passFailText(dwellValidity));

fprintf('Scheduler score validity    = %s\n', ...
    passFailText(scoreValidity));

fprintf('Exploration mode validity   = %s\n', ...
    passFailText(modeValidity));

fprintf('Receiver configuration      = %s\n', ...
    passFailText(receiverValidity));

fprintf('Pipeline trace              = %s\n', ...
    passFailText(pipelineTracePass));

fprintf('Determinism                 = %s\n', ...
    passFailText(deterministicPass));

fprintf('\n');

if allPass

    fprintf('M10.8 RESULT = PASS\n');

else

    fprintf('M10.8 RESULT = REVIEW\n');

end

fprintf('============================================================\n');

%% ============================================================
% RETURN RESULT STRUCTURE
% =============================================================

result = struct();

result.allPass = allPass;

result.completePipeline = test1;

result.frequencyValidity = frequencyValidity;

result.dwellValidity = dwellValidity;

result.scoreValidity = scoreValidity;

result.modeValidity = modeValidity;

result.receiverValidity = receiverValidity;

result.pipelineTracePass = pipelineTracePass;

result.deterministicPass = deterministicPass;

result.schedulerDecision = schedulerDecision;

result.schedulerInfo = info;

end


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