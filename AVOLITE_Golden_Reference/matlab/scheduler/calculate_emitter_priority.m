function [priorityScore, info] = calculate_emitter_priority( ...
    schedulerState, cfg)
%CALCULATE_EMITTER_PRIORITY Calculate deterministic emitter priority.
%
% AVOLITE Golden Reference
%
% The priority score combines:
%   - emitter activity probability
%   - recent detection/hit behavior
%   - SNR
%   - received power
%   - time since last observation
%
% Output:
%   priorityScore : normalized priority in [0,1]
%   info          : component values and diagnostics

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
% HISTORY FEATURES
% =============================================================

detectionHistory = ...
    double(schedulerState.detectionHistory(:));

hitHistory = ...
    double(schedulerState.hitHistory(:));

detectionRate = ...
    mean(detectionHistory > 0);

hitRate = ...
    mean(hitHistory > 0);

%% ============================================================
% ACTIVITY COMPONENT
% =============================================================

activityComponent = ...
    schedulerState.emitterActivityProbability;

%% ============================================================
% DETECTION COMPONENT
% =============================================================

detectionComponent = ...
    detectionRate;

%% ============================================================
% HIT COMPONENT
% =============================================================

hitComponent = ...
    hitRate;

%% ============================================================
% SNR COMPONENT
% ============================================================

snr_dB = schedulerState.snr_dB;

snrReference_dB = 20;

if snr_dB <= 0

    snrComponent = 0;

elseif snr_dB >= snrReference_dB

    snrComponent = 1;

else

    snrComponent = ...
        snr_dB / snrReference_dB;

end

%% ============================================================
% RECEIVED POWER COMPONENT
% ============================================================

receivedPower_dBm = ...
    schedulerState.receivedPower_dBm;

powerLow_dBm = -100;

powerHigh_dBm = -30;

if receivedPower_dBm <= powerLow_dBm

    powerComponent = 0;

elseif receivedPower_dBm >= powerHigh_dBm

    powerComponent = 1;

else

    powerComponent = ...
        (receivedPower_dBm - powerLow_dBm) / ...
        (powerHigh_dBm - powerLow_dBm);

end

%% ============================================================
% OBSERVATION-AGE COMPONENT
% ============================================================

timeSinceLastObservation_s = ...
    schedulerState.timeSinceLastObservation_s;

referenceObservationAge_s = 10e-3;

if timeSinceLastObservation_s <= 0

    observationAgeComponent = 0;

elseif timeSinceLastObservation_s >= ...
        referenceObservationAge_s

    observationAgeComponent = 1;

else

    observationAgeComponent = ...
        timeSinceLastObservation_s / ...
        referenceObservationAge_s;

end

%% ============================================================
% WEIGHTS
% =============================================================

weightActivity = 0.25;
weightDetection = 0.20;
weightHit = 0.15;
weightSNR = 0.15;
weightPower = 0.10;
weightObservationAge = 0.15;

weightSum = ...
    weightActivity + ...
    weightDetection + ...
    weightHit + ...
    weightSNR + ...
    weightPower + ...
    weightObservationAge;

%% ============================================================
% PRIORITY SCORE
% =============================================================

priorityScore = ...
    ( ...
        weightActivity * activityComponent + ...
        weightDetection * detectionComponent + ...
        weightHit * hitComponent + ...
        weightSNR * snrComponent + ...
        weightPower * powerComponent + ...
        weightObservationAge * observationAgeComponent ...
    ) / weightSum;

%% ============================================================
% FINAL CLAMP
% =============================================================

priorityScore = ...
    min(max(priorityScore,0),1);

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.activityComponent = ...
    activityComponent;

info.detectionComponent = ...
    detectionComponent;

info.hitComponent = ...
    hitComponent;

info.snrComponent = ...
    snrComponent;

info.powerComponent = ...
    powerComponent;

info.observationAgeComponent = ...
    observationAgeComponent;

info.detectionRate = ...
    detectionRate;

info.hitRate = ...
    hitRate;

info.snr_dB = ...
    snr_dB;

info.receivedPower_dBm = ...
    receivedPower_dBm;

info.timeSinceLastObservation_s = ...
    timeSinceLastObservation_s;

info.weightActivity = ...
    weightActivity;

info.weightDetection = ...
    weightDetection;

info.weightHit = ...
    weightHit;

info.weightSNR = ...
    weightSNR;

info.weightPower = ...
    weightPower;

info.weightObservationAge = ...
    weightObservationAge;

info.weightSum = ...
    weightSum;

info.priorityScore = ...
    priorityScore;

info.method = ...
    "deterministic_weighted_priority";

end