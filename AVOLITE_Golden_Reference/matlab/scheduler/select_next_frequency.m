function [nextFrequency_Hz, info] = select_next_frequency( ...
    candidateFrequencies_Hz, ...
    schedulerState, ...
    priorityScore, ...
    uncertaintyScore, ...
    mode, ...
    cfg)
%SELECT_NEXT_FREQUENCY Select next RF scan frequency.
%
% AVOLITE Golden Reference
%
% Inputs:
%   candidateFrequencies_Hz : available RF scan frequencies [Hz]
%   schedulerState          : validated scheduler state
%   priorityScore           : current emitter priority [0,1]
%   uncertaintyScore        : current uncertainty [0,1]
%   mode                    : EXPLORE / EXPLOIT / BALANCED
%   cfg                     : AVOLITE configuration
%
% Outputs:
%   nextFrequency_Hz : selected next scan frequency [Hz]
%   info             : selection diagnostics
%
% Design:
%   EXPLOIT   -> prefer the current/known important frequency
%   EXPLORE   -> prefer the least recently observed candidate
%   BALANCED  -> combine revisit priority and exploration
%
% The implementation is deterministic.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(candidateFrequencies_Hz) || ...
        isempty(candidateFrequencies_Hz) || ...
        ~isreal(candidateFrequencies_Hz)

    error( ...
        'select_next_frequency:InvalidCandidates', ...
        'candidateFrequencies_Hz must be a non-empty real numeric vector.');

end

candidateFrequencies_Hz = ...
    candidateFrequencies_Hz(:);

if any(~isfinite(candidateFrequencies_Hz))

    error( ...
        'select_next_frequency:NonFiniteCandidates', ...
        'candidateFrequencies_Hz must contain only finite values.');

end

if any(candidateFrequencies_Hz < 0)

    error( ...
        'select_next_frequency:NegativeCandidateFrequency', ...
        'candidateFrequencies_Hz must contain non-negative values.');

end

if numel(unique(candidateFrequencies_Hz)) ~= ...
        numel(candidateFrequencies_Hz)

    error( ...
        'select_next_frequency:DuplicateCandidates', ...
        'candidateFrequencies_Hz must not contain duplicate values.');

end

if ~isnumeric(priorityScore) || ...
        ~isscalar(priorityScore) || ...
        ~isfinite(priorityScore) || ...
        ~isreal(priorityScore) || ...
        priorityScore < 0 || ...
        priorityScore > 1

    error( ...
        'select_next_frequency:InvalidPriority', ...
        'priorityScore must be in [0,1].');

end

if ~isnumeric(uncertaintyScore) || ...
        ~isscalar(uncertaintyScore) || ...
        ~isfinite(uncertaintyScore) || ...
        ~isreal(uncertaintyScore) || ...
        uncertaintyScore < 0 || ...
        uncertaintyScore > 1

    error( ...
        'select_next_frequency:InvalidUncertainty', ...
        'uncertaintyScore must be in [0,1].');

end

if ~(mode == "EXPLORE" || ...
        mode == "EXPLOIT" || ...
        mode == "BALANCED")

    error( ...
        'select_next_frequency:InvalidMode', ...
        'mode must be EXPLORE, EXPLOIT, or BALANCED.');

end

[isValid, validationInfo] = ...
    validate_scheduler_input( ...
        schedulerState, cfg);

if ~isValid

    error( ...
        validationInfo.errorIdentifier, ...
        '%s', ...
        validationInfo.errorMessage);

end

%% ============================================================
% FREQUENCY HISTORY
% =============================================================

frequencyHistory_Hz = ...
    schedulerState.frequencyHistory_Hz(:);

%% ============================================================
% HISTORY / OBSERVATION SCORE
% =============================================================

numberOfCandidates = ...
    numel(candidateFrequencies_Hz);

historyCounts = ...
    zeros(numberOfCandidates,1);

for k = 1:numberOfCandidates

    historyCounts(k) = ...
        sum(abs( ...
            frequencyHistory_Hz - ...
            candidateFrequencies_Hz(k)) < 1e-9);

end

maxHistoryCount = ...
    max(historyCounts);

if maxHistoryCount > 0

    revisitScore = ...
        1 - historyCounts ./ maxHistoryCount;

else

    revisitScore = ...
        ones(numberOfCandidates,1);

end

%% ============================================================
% CURRENT-FREQUENCY SCORE
% =============================================================

currentFrequency_Hz = ...
    schedulerState.currentFrequency_Hz;

currentFrequencyScore = ...
    zeros(numberOfCandidates,1);

for k = 1:numberOfCandidates

    if abs( ...
            candidateFrequencies_Hz(k) - ...
            currentFrequency_Hz) < 1e-9

        currentFrequencyScore(k) = 1;

    end

end

%% ============================================================
% PREVIOUS-FREQUENCY PENALTY
% =============================================================

previousFrequency_Hz = ...
    schedulerState.previousFrequency_Hz;

previousFrequencyPenalty = ...
    zeros(numberOfCandidates,1);

for k = 1:numberOfCandidates

    if abs( ...
            candidateFrequencies_Hz(k) - ...
            previousFrequency_Hz) < 1e-9

        previousFrequencyPenalty(k) = 1;

    end

end

%% ============================================================
% MODE-DEPENDENT SCORING
% =============================================================

switch mode

    case "EXPLOIT"

        % Revisit known/current important frequency.
        candidateScore = ...
            0.70 .* currentFrequencyScore + ...
            0.30 .* revisitScore;

    case "EXPLORE"

        % Prefer frequencies that have been observed least.
        candidateScore = ...
            0.85 .* revisitScore + ...
            0.15 .* (1 - currentFrequencyScore);

    case "BALANCED"

        % Combine exploitation and exploration.
        candidateScore = ...
            0.45 .* currentFrequencyScore + ...
            0.40 .* revisitScore + ...
            0.15 .* (1 - currentFrequencyScore);

end

%% ============================================================
% UNCERTAINTY MODULATION
% ============================================================

% Higher uncertainty increases the value of unexplored
% candidates.

candidateScore = ...
    candidateScore + ...
    0.20 .* uncertaintyScore .* revisitScore;

% Higher priority slightly favors known/current observations.

candidateScore = ...
    candidateScore + ...
    0.10 .* priorityScore .* currentFrequencyScore;

%% ============================================================
% AVOID IMMEDIATE REPETITION
% ============================================================

% Penalize the previous frequency unless it is the only
% available candidate.

candidateScore = ...
    candidateScore - ...
    0.25 .* previousFrequencyPenalty;

if numberOfCandidates > 1

    previousMask = ...
        previousFrequencyPenalty > 0.5;

    if any(~previousMask)

        candidateScore(previousMask) = ...
            -Inf;

    end

end

%% ============================================================
% DETERMINISTIC TIE BREAKING
% ============================================================

maximumScore = ...
    max(candidateScore);

tieMask = ...
    abs(candidateScore - maximumScore) < 1e-12;

tieIndices = ...
    find(tieMask);

% If multiple candidates have identical score, select the
% lowest frequency. This makes the result deterministic.

selectedIndex = ...
    tieIndices(1);

if numel(tieIndices) > 1

    [~, localIndex] = ...
        min(candidateFrequencies_Hz(tieIndices));

    selectedIndex = ...
        tieIndices(localIndex);

end

%% ============================================================
% OUTPUT
% =============================================================

nextFrequency_Hz = ...
    candidateFrequencies_Hz(selectedIndex);

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.candidateFrequencies_Hz = ...
    candidateFrequencies_Hz;

info.historyCounts = ...
    historyCounts;

info.revisitScore = ...
    revisitScore;

info.currentFrequencyScore = ...
    currentFrequencyScore;

info.previousFrequencyPenalty = ...
    previousFrequencyPenalty;

info.candidateScore = ...
    candidateScore;

info.selectedIndex = ...
    selectedIndex;

info.selectedFrequency_Hz = ...
    nextFrequency_Hz;

info.priorityScore = ...
    priorityScore;

info.uncertaintyScore = ...
    uncertaintyScore;

info.mode = ...
    mode;

info.numberOfCandidates = ...
    numberOfCandidates;

info.method = ...
    "deterministic_candidate_frequency_selection";

end