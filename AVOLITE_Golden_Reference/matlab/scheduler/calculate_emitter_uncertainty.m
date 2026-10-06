function [uncertaintyScore, info] = calculate_emitter_uncertainty( ...
    schedulerState, cfg)
%CALCULATE_EMITTER_UNCERTAINTY Calculate deterministic emitter uncertainty.
%
% AVOLITE Golden Reference
%
% Output:
%   uncertaintyScore : normalized uncertainty in [0,1]
%   info             : uncertainty components and diagnostics
%
% Higher value = greater uncertainty.
%
% Components:
%   1. Detection-history uncertainty
%   2. Hit-history uncertainty
%   3. Activity-probability uncertainty
%   4. Observation-age uncertainty
%   5. Frequency-history variability

%% ============================================================
% INPUT VALIDATION
% =============================================================

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
% DETECTION HISTORY UNCERTAINTY
% ============================================================

detectionHistory = ...
    double(schedulerState.detectionHistory(:));

detectionRate = ...
    mean(detectionHistory > 0);

% Maximum uncertainty occurs when detection probability = 0.5.
detectionUncertainty = ...
    1 - abs(2*detectionRate - 1);

detectionUncertainty = ...
    min(max(detectionUncertainty,0),1);

%% ============================================================
% HIT HISTORY UNCERTAINTY
% ============================================================

hitHistory = ...
    double(schedulerState.hitHistory(:));

hitRate = ...
    mean(hitHistory > 0);

hitUncertainty = ...
    1 - abs(2*hitRate - 1);

hitUncertainty = ...
    min(max(hitUncertainty,0),1);

%% ============================================================
% ACTIVITY-PROBABILITY UNCERTAINTY
% ============================================================

activityProbability = ...
    schedulerState.emitterActivityProbability;

activityUncertainty = ...
    1 - abs(2*activityProbability - 1);

activityUncertainty = ...
    min(max(activityUncertainty,0),1);

%% ============================================================
% OBSERVATION-AGE UNCERTAINTY
% ============================================================

observationAge_s = ...
    schedulerState.timeSinceLastObservation_s;

referenceObservationAge_s = 10e-3;

if observationAge_s <= 0

    observationAgeUncertainty = 0;

elseif observationAge_s >= ...
        referenceObservationAge_s

    observationAgeUncertainty = 1;

else

    observationAgeUncertainty = ...
        observationAge_s / ...
        referenceObservationAge_s;

end

observationAgeUncertainty = ...
    min(max(observationAgeUncertainty,0),1);

%% ============================================================
% FREQUENCY-HISTORY VARIABILITY
% ============================================================

frequencyHistory_Hz = ...
    schedulerState.frequencyHistory_Hz(:);

if numel(frequencyHistory_Hz) <= 1

    frequencyVariability = 0;

else

    frequencyMean_Hz = ...
        mean(frequencyHistory_Hz);

    if frequencyMean_Hz > 0

        frequencyStd_Hz = ...
            std(frequencyHistory_Hz);

        frequencyVariability = ...
            frequencyStd_Hz / ...
            frequencyMean_Hz;

    else

        frequencyVariability = 0;

    end

end

% Normalize variability to [0,1].
%
% A coefficient of variation of 0.25 or greater is treated
% as high variability for this deterministic baseline.

frequencyVariabilityReference = 0.25;

frequencyVariabilityComponent = ...
    frequencyVariability / ...
    frequencyVariabilityReference;

frequencyVariabilityComponent = ...
    min(max(frequencyVariabilityComponent,0),1);

%% ============================================================
% WEIGHTS
% ============================================================

weightDetection = 0.25;
weightHit = 0.20;
weightActivity = 0.20;
weightObservationAge = 0.20;
weightFrequencyVariability = 0.15;

weightSum = ...
    weightDetection + ...
    weightHit + ...
    weightActivity + ...
    weightObservationAge + ...
    weightFrequencyVariability;

%% ============================================================
% TOTAL UNCERTAINTY
% ============================================================

uncertaintyScore = ...
    ( ...
        weightDetection * detectionUncertainty + ...
        weightHit * hitUncertainty + ...
        weightActivity * activityUncertainty + ...
        weightObservationAge * observationAgeUncertainty + ...
        weightFrequencyVariability * ...
            frequencyVariabilityComponent ...
    ) / weightSum;

uncertaintyScore = ...
    min(max(uncertaintyScore,0),1);

%% ============================================================
% DIAGNOSTICS
% ============================================================

info = struct();

info.detectionRate = ...
    detectionRate;

info.hitRate = ...
    hitRate;

info.activityProbability = ...
    activityProbability;

info.detectionUncertainty = ...
    detectionUncertainty;

info.hitUncertainty = ...
    hitUncertainty;

info.activityUncertainty = ...
    activityUncertainty;

info.observationAgeUncertainty = ...
    observationAgeUncertainty;

info.frequencyMean_Hz = ...
    mean(frequencyHistory_Hz);

if numel(frequencyHistory_Hz) > 1
    info.frequencyStd_Hz = ...
        std(frequencyHistory_Hz);
else
    info.frequencyStd_Hz = 0;
end

info.frequencyVariability = ...
    frequencyVariability;

info.frequencyVariabilityComponent = ...
    frequencyVariabilityComponent;

info.weightDetection = ...
    weightDetection;

info.weightHit = ...
    weightHit;

info.weightActivity = ...
    weightActivity;

info.weightObservationAge = ...
    weightObservationAge;

info.weightFrequencyVariability = ...
    weightFrequencyVariability;

info.weightSum = ...
    weightSum;

info.uncertaintyScore = ...
    uncertaintyScore;

info.method = ...
    "deterministic_weighted_uncertainty";

end