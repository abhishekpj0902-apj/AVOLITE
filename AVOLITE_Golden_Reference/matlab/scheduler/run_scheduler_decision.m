function [schedulerDecision, info] = run_scheduler_decision( ...
    candidateFrequencies_Hz, schedulerInput, cfg)
%RUN_SCHEDULER_DECISION Complete AVOLITE scheduler decision pipeline.
%
% M10.8
%
% Pipeline:
%   M10.1 Scheduler input validation
%   M10.2 Emitter priority
%   M10.3 Emitter uncertainty
%   M10.4 Exploration / exploitation
%   M10.5 Next frequency selection
%   M10.6 Adaptive dwell time
%   M10.7 Adaptive receiver configuration
%
% Inputs:
%   candidateFrequencies_Hz : candidate scan frequencies [Hz]
%   schedulerInput          : scheduler state structure
%   cfg                     : AVOLITE configuration structure
%
% Outputs:
%   schedulerDecision       : complete scheduler decision
%   info                    : diagnostic information

%% ============================================================
%  M10.8.1 INPUT VALIDATION
% =============================================================

if nargin ~= 3
    error( ...
        'run_scheduler_decision:InvalidNumberOfInputs', ...
        ['Expected exactly 3 inputs: ', ...
         'candidateFrequencies_Hz, schedulerInput, cfg.']);
end

%% Candidate frequency validation

if ~isnumeric(candidateFrequencies_Hz) || ...
        isempty(candidateFrequencies_Hz) || ...
        ~isreal(candidateFrequencies_Hz) || ...
        any(~isfinite(candidateFrequencies_Hz(:))) || ...
        any(candidateFrequencies_Hz(:) < 0)

    error( ...
        'run_scheduler_decision:InvalidCandidateFrequencies', ...
        'Candidate frequencies must be finite, real, nonnegative numeric values.');
end

candidateFrequencies_Hz = candidateFrequencies_Hz(:).';

if numel(unique(candidateFrequencies_Hz)) ~= ...
        numel(candidateFrequencies_Hz)

    error( ...
        'run_scheduler_decision:DuplicateCandidateFrequencies', ...
        'Candidate frequencies must be unique.');
end

%% Scheduler input structure validation

if ~isstruct(schedulerInput)

    error( ...
        'run_scheduler_decision:InvalidSchedulerInput', ...
        'schedulerInput must be a structure.');
end

%% Configuration validation

if ~isstruct(cfg)

    error( ...
        'run_scheduler_decision:InvalidConfiguration', ...
        'cfg must be a structure.');
end

%% ============================================================
%  M10.8.2 M10.1 — SCHEDULER INPUT VALIDATION
% =============================================================

[inputValid, inputValidationInfo] = ...
    validate_scheduler_input(schedulerInput, cfg);

if ~inputValid

    if isstruct(inputValidationInfo) && ...
            isfield(inputValidationInfo, 'errorMessage')

        error( ...
            'run_scheduler_decision:InvalidSchedulerInput', ...
            '%s', inputValidationInfo.errorMessage);

    else

        error( ...
            'run_scheduler_decision:InvalidSchedulerInput', ...
            'Scheduler input validation failed.');

    end
end

%% ============================================================
%  M10.8.3 M10.2 — EMITTER PRIORITY
% =============================================================

[priorityScore, priorityInfo] = ...
    calculate_emitter_priority(schedulerInput, cfg);

[uncertaintyScore, uncertaintyInfo] = ...
    calculate_emitter_uncertainty(schedulerInput, cfg);

%% ============================================================
%  M10.8.5 M10.4 — EXPLORATION / EXPLOITATION
% =============================================================

[mode, explorationProbability] = ...
    select_exploration_mode( ...
        priorityScore, ...
        uncertaintyScore, ...
        cfg);

%% ============================================================
%  M10.8.6 M10.5 — NEXT FREQUENCY SELECTION
% =============================================================

[nextFrequency_Hz, frequencyInfo] = ...
    select_next_frequency( ...
        candidateFrequencies_Hz, ...
        schedulerInput, ...
        priorityScore, ...
        uncertaintyScore, ...
        mode, ...
        cfg);

%% ============================================================
%  M10.8.7 M10.6 — ADAPTIVE DWELL TIME
% =============================================================

[dwellTime_s, dwellInfo] = ...
    calculate_adaptive_dwell_time( ...
        priorityScore, ...
        uncertaintyScore, ...
        mode, ...
        cfg);

%% ============================================================
%  M10.8.8 M10.7 — ADAPTIVE RECEIVER CONFIGURATION
% =============================================================

[receiverConfig, receiverInfo] = ...
    calculate_adaptive_receiver_config( ...
        priorityScore, ...
        uncertaintyScore, ...
        mode, ...
        cfg);

%% ============================================================
%  M10.8.9 COMPLETE SCHEDULER DECISION
% =============================================================

schedulerDecision = struct();

schedulerDecision.nextFrequency_Hz = ...
    nextFrequency_Hz;

schedulerDecision.dwellTime_s = ...
    dwellTime_s;

schedulerDecision.explorationMode = ...
    mode;

schedulerDecision.explorationProbability = ...
    explorationProbability;

schedulerDecision.priorityScore = ...
    priorityScore;

schedulerDecision.uncertaintyScore = ...
    uncertaintyScore;

schedulerDecision.receiverConfig = ...
    receiverConfig;

%% ============================================================
%  M10.8.10 DIAGNOSTIC INFORMATION
% =============================================================

info = struct();

info.inputValidated = inputValid;

info.inputValidation = ...
    inputValidationInfo;

info.priority = ...
    priorityInfo;

info.uncertainty = ...
    uncertaintyInfo;

info.frequencySelection = ...
    frequencyInfo;

info.dwellTime = ...
    dwellInfo;

info.receiverConfiguration = ...
    receiverInfo;

info.pipeline = [ ...
    "validate_input"
    "calculate_priority"
    "calculate_uncertainty"
    "select_exploration_mode"
    "select_next_frequency"
    "calculate_dwell_time"
    "calculate_receiver_configuration"
    ];

end