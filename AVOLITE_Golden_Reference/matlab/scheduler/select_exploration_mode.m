function [mode, explorationProbability, info] = ...
    select_exploration_mode( ...
    priorityScore, ...
    uncertaintyScore, ...
    cfg)
%SELECT_EXPLORATION_MODE Select exploration/exploitation scan mode.
%
% AVOLITE Golden Reference
%
% Inputs:
%   priorityScore      : emitter priority [0,1]
%   uncertaintyScore   : emitter uncertainty [0,1]
%   cfg                : AVOLITE configuration
%
% Outputs:
%   mode               : "EXPLOIT", "EXPLORE", or "BALANCED"
%   explorationProbability : probability [0,1]
%   info               : decision diagnostics
%
% Decision principle:
%
%   High uncertainty
%       -> EXPLORE
%
%   High priority + low uncertainty
%       -> EXPLOIT
%
%   Intermediate condition
%       -> BALANCED
%
% The configured exploration probability is used as the
% baseline exploration probability.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(priorityScore) || ...
        ~isscalar(priorityScore) || ...
        ~isreal(priorityScore) || ...
        ~isfinite(priorityScore)

    error( ...
        'select_exploration_mode:InvalidPriority', ...
        'priorityScore must be a finite real numeric scalar.');

end

if ~isnumeric(uncertaintyScore) || ...
        ~isscalar(uncertaintyScore) || ...
        ~isreal(uncertaintyScore) || ...
        ~isfinite(uncertaintyScore)

    error( ...
        'select_exploration_mode:InvalidUncertainty', ...
        'uncertaintyScore must be a finite real numeric scalar.');

end

if ~isstruct(cfg)

    error( ...
        'select_exploration_mode:InvalidConfiguration', ...
        'cfg must be a structure.');

end

if priorityScore < 0 || priorityScore > 1

    error( ...
        'select_exploration_mode:PriorityOutOfRange', ...
        'priorityScore must be in the range [0,1].');

end

if uncertaintyScore < 0 || uncertaintyScore > 1

    error( ...
        'select_exploration_mode:UncertaintyOutOfRange', ...
        'uncertaintyScore must be in the range [0,1].');

end

%% ============================================================
% CONFIGURATION
% =============================================================

if isfield(cfg,'scheduler') && ...
        isfield(cfg.scheduler,'explorationProbability')

    configuredExplorationProbability = ...
        cfg.scheduler.explorationProbability;

else

    configuredExplorationProbability = 0.20;

end

if ~isnumeric(configuredExplorationProbability) || ...
        ~isscalar(configuredExplorationProbability) || ...
        ~isfinite(configuredExplorationProbability)

    error( ...
        'select_exploration_mode:InvalidExplorationProbability', ...
        'Exploration probability must be finite numeric scalar.');

end

if configuredExplorationProbability < 0 || ...
        configuredExplorationProbability > 1

    error( ...
        'select_exploration_mode:ExplorationProbabilityOutOfRange', ...
        'Exploration probability must be in the range [0,1].');

end

%% ============================================================
% DECISION THRESHOLDS
% =============================================================

highPriorityThreshold = 0.70;

highUncertaintyThreshold = 0.60;

lowUncertaintyThreshold = 0.30;

%% ============================================================
% EXPLORATION PROBABILITY
% ============================================================

% Base probability from configuration.

explorationProbability = ...
    configuredExplorationProbability;

% Increase exploration when uncertainty is high.

if uncertaintyScore >= highUncertaintyThreshold

    uncertaintyExcess = ...
        (uncertaintyScore - highUncertaintyThreshold) / ...
        (1 - highUncertaintyThreshold);

    explorationProbability = ...
        explorationProbability + ...
        (1 - explorationProbability) * ...
        uncertaintyExcess;

end

% High-priority but uncertain emitters receive additional
% exploration emphasis.

if priorityScore >= highPriorityThreshold && ...
        uncertaintyScore >= highUncertaintyThreshold

    explorationProbability = ...
        explorationProbability + ...
        0.10 * ...
        (1 - explorationProbability);

end

explorationProbability = ...
    min(max(explorationProbability,0),1);

%% ============================================================
% MODE DECISION
% =============================================================

if uncertaintyScore >= highUncertaintyThreshold

    mode = "EXPLORE";

elseif priorityScore >= highPriorityThreshold && ...
        uncertaintyScore <= lowUncertaintyThreshold

    mode = "EXPLOIT";

else

    mode = "BALANCED";

end

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.priorityScore = ...
    priorityScore;

info.uncertaintyScore = ...
    uncertaintyScore;

info.highPriorityThreshold = ...
    highPriorityThreshold;

info.highUncertaintyThreshold = ...
    highUncertaintyThreshold;

info.lowUncertaintyThreshold = ...
    lowUncertaintyThreshold;

info.configuredExplorationProbability = ...
    configuredExplorationProbability;

info.explorationProbability = ...
    explorationProbability;

info.mode = ...
    mode;

info.method = ...
    "deterministic_exploration_exploitation";

end