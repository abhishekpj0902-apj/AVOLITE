function [isValid, info] = validate_scheduler_input(schedulerState, cfg)
%VALIDATE_SCHEDULER_INPUT Validate AVOLITE scheduler input state.
%
% Golden Reference
%
% Inputs:
%   schedulerState : structure containing current RF/environment state
%   cfg            : AVOLITE configuration structure
%
% Outputs:
%   isValid : true if the required scheduler interface is valid
%   info    : validation diagnostics
%
% Required scheduler-state fields:
%   currentFrequency_Hz
%   previousFrequency_Hz
%   detectionHistory
%   hitHistory
%   snr_dB
%   receivedPower_dBm
%   noiseFloor_dBm
%   pulseWidth_s
%   PRI_s
%   frequencyHistory_Hz
%   emitterActivityProbability
%   aoa_deg
%   environmentState
%   timeSinceLastObservation_s

%% ============================================================
% INITIALIZATION
% =============================================================

isValid = false;

info = struct();

info.validationPassed = false;
info.errorIdentifier = "";
info.errorMessage = "";
info.checkedFields = {};
info.missingFields = {};

%% ============================================================
% INPUT VALIDATION
% ============================================================

if ~isstruct(schedulerState)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidSchedulerState";

    info.errorMessage = ...
        "schedulerState must be a structure.";

    return;

end

if ~isstruct(cfg)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidConfiguration";

    info.errorMessage = ...
        "cfg must be a structure.";

    return;

end

%% ============================================================
% REQUIRED FIELDS
% =============================================================

requiredFields = { ...
    'currentFrequency_Hz'
    'previousFrequency_Hz'
    'detectionHistory'
    'hitHistory'
    'snr_dB'
    'receivedPower_dBm'
    'noiseFloor_dBm'
    'pulseWidth_s'
    'PRI_s'
    'frequencyHistory_Hz'
    'emitterActivityProbability'
    'aoa_deg'
    'environmentState'
    'timeSinceLastObservation_s'};

info.checkedFields = requiredFields;

missingFields = {};

for k = 1:numel(requiredFields)

    fieldName = requiredFields{k};

    if ~isfield(schedulerState,fieldName)

        missingFields{end+1} = fieldName; %#ok<AGROW>

    end

end

info.missingFields = missingFields;

if ~isempty(missingFields)

    info.errorIdentifier = ...
        "validate_scheduler_input:MissingField";

    info.errorMessage = ...
        sprintf( ...
        'Missing required scheduler field: %s', ...
        missingFields{1});

    return;

end

%% ============================================================
% SCALAR NUMERIC VALIDATION
% =============================================================

scalarFields = { ...
    'currentFrequency_Hz'
    'previousFrequency_Hz'
    'snr_dB'
    'receivedPower_dBm'
    'noiseFloor_dBm'
    'pulseWidth_s'
    'PRI_s'
    'emitterActivityProbability'
    'aoa_deg'
    'timeSinceLastObservation_s'};

for k = 1:numel(scalarFields)

    fieldName = scalarFields{k};

    value = schedulerState.(fieldName);

    if ~isnumeric(value) || ...
            ~isscalar(value) || ...
            ~isreal(value) || ...
            ~isfinite(value)

        info.errorIdentifier = ...
            "validate_scheduler_input:InvalidScalar";

        info.errorMessage = ...
            sprintf( ...
            ['Scheduler field %s must be a finite real ', ...
             'numeric scalar.'], ...
            fieldName);

        return;

    end

end

%% ============================================================
% FREQUENCY VALIDATION
% =============================================================

if schedulerState.currentFrequency_Hz < 0

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidFrequency";

    info.errorMessage = ...
        "currentFrequency_Hz must be non-negative.";

    return;

end

if schedulerState.previousFrequency_Hz < 0

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidFrequency";

    info.errorMessage = ...
        "previousFrequency_Hz must be non-negative.";

    return;

end

%% ============================================================
% TIME-RELATED VALIDATION
% =============================================================

if schedulerState.pulseWidth_s < 0

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidPulseWidth";

    info.errorMessage = ...
        "pulseWidth_s must be non-negative.";

    return;

end

if schedulerState.PRI_s < 0

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidPRI";

    info.errorMessage = ...
        "PRI_s must be non-negative.";

    return;

end

if schedulerState.timeSinceLastObservation_s < 0

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidObservationTime";

    info.errorMessage = ...
        "timeSinceLastObservation_s must be non-negative.";

    return;

end

%% ============================================================
% ACTIVITY-PROBABILITY VALIDATION
% =============================================================

if schedulerState.emitterActivityProbability < 0 || ...
        schedulerState.emitterActivityProbability > 1

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidActivityProbability";

    info.errorMessage = ...
        "emitterActivityProbability must be between 0 and 1.";

    return;

end

%% ============================================================
% DETECTION HISTORY
% =============================================================

if ~isnumeric(schedulerState.detectionHistory) && ...
        ~islogical(schedulerState.detectionHistory)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidDetectionHistory";

    info.errorMessage = ...
        "detectionHistory must be numeric or logical.";

    return;

end

if isempty(schedulerState.detectionHistory)

    info.errorIdentifier = ...
        "validate_scheduler_input:EmptyDetectionHistory";

    info.errorMessage = ...
        "detectionHistory must not be empty.";

    return;

end

%% ============================================================
% HIT HISTORY
% =============================================================

if ~isnumeric(schedulerState.hitHistory) && ...
        ~islogical(schedulerState.hitHistory)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidHitHistory";

    info.errorMessage = ...
        "hitHistory must be numeric or logical.";

    return;

end

if isempty(schedulerState.hitHistory)

    info.errorIdentifier = ...
        "validate_scheduler_input:EmptyHitHistory";

    info.errorMessage = ...
        "hitHistory must not be empty.";

    return;

end

%% ============================================================
% FREQUENCY HISTORY
% =============================================================

if ~isnumeric(schedulerState.frequencyHistory_Hz)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidFrequencyHistory";

    info.errorMessage = ...
        "frequencyHistory_Hz must be numeric.";

    return;

end

if isempty(schedulerState.frequencyHistory_Hz)

    info.errorIdentifier = ...
        "validate_scheduler_input:EmptyFrequencyHistory";

    info.errorMessage = ...
        "frequencyHistory_Hz must not be empty.";

    return;

end

if any(~isfinite(schedulerState.frequencyHistory_Hz(:)))

    info.errorIdentifier = ...
        "validate_scheduler_input:NonFiniteFrequencyHistory";

    info.errorMessage = ...
        "frequencyHistory_Hz must contain finite values.";

    return;

end

if any(schedulerState.frequencyHistory_Hz(:) < 0)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidFrequencyHistory";

    info.errorMessage = ...
        "frequencyHistory_Hz must contain non-negative values.";

    return;

end

%% ============================================================
% ENVIRONMENT STATE
% =============================================================

if ~isstruct(schedulerState.environmentState)

    info.errorIdentifier = ...
        "validate_scheduler_input:InvalidEnvironmentState";

    info.errorMessage = ...
        "environmentState must be a structure.";

    return;

end

%% ============================================================
% SUCCESS
% =============================================================

isValid = true;

info.validationPassed = true;
info.errorIdentifier = "";
info.errorMessage = "";

end