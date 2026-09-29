function AssociationTable = FindClosestTargetAtRadarTime( ...
    TargetData, detectedRange, radarTime)
% ==============================================================
% FIND CLOSEST TARGET AT RADAR PROCESSING TIME
% ==============================================================
%
% Inputs:
%   TargetData    : target structure array
%   detectedRange : measured radar range in meters
%   radarTime     : radar processing time in seconds
%
% Output:
%   AssociationTable : table containing closest target samples
%
% ==============================================================

if nargin < 3
    error('Usage: FindClosestTargetAtRadarTime(TargetData, detectedRange, radarTime)');
end

if isempty(TargetData)
    error('TargetData is empty.');
end

if ~isscalar(detectedRange) || ...
        ~isfinite(detectedRange)

    error('detectedRange must be a finite scalar.');
end

if ~isscalar(radarTime) || ...
        ~isfinite(radarTime)

    error('radarTime must be a finite scalar.');
end

numberOfTargets = numel(TargetData);

TargetID = NaN(numberOfTargets, 1);

TargetVelocity_mps = NaN(numberOfTargets, 1);

MatchedTime_s = NaN(numberOfTargets, 1);

MatchedRange_m = NaN(numberOfTargets, 1);

RangeError_m = NaN(numberOfTargets, 1);

for k = 1:numberOfTargets

    %% Read ID safely

    targetIDValue = TargetData(k).ID;

    targetIDValue = targetIDValue(:);

    if isempty(targetIDValue)
        TargetID(k) = k;
    else
        TargetID(k) = double(targetIDValue(1));
    end

    %% Read velocity safely

    velocityValue = TargetData(k).Velocity;

    velocityValue = velocityValue(:);

    if ~isempty(velocityValue)
        TargetVelocity_mps(k) = ...
            double(velocityValue(1));
    end

    %% Read time and distance

    timeHistory = ...
        double(TargetData(k).Time(:));

    distanceHistory = ...
        double(TargetData(k).Distance(:));

    %% Remove invalid values

    validTime = ...
        isfinite(timeHistory);

    validDistance = ...
        isfinite(distanceHistory);

    if ~any(validTime) || ~any(validDistance)
        continue;
    end

    timeHistory = ...
        timeHistory(validTime);

    distanceHistory = ...
        distanceHistory(validDistance);

    %% Match time and range independently

    [~, timeIndex] = ...
        min(abs(timeHistory - radarTime));

    [~, rangeIndex] = ...
        min(abs(distanceHistory - detectedRange));

    MatchedTime_s(k) = ...
        timeHistory(timeIndex);

    MatchedRange_m(k) = ...
        distanceHistory(rangeIndex);

    RangeError_m(k) = ...
        abs(MatchedRange_m(k) - detectedRange);

end

%% Create output table

AssociationTable = table( ...
    TargetID, ...
    TargetVelocity_mps, ...
    MatchedTime_s, ...
    MatchedRange_m, ...
    RangeError_m);

AssociationTable = sortrows( ...
    AssociationTable, ...
    'RangeError_m', ...
    'ascend');

fprintf('\n');
fprintf('====================================================\n');
fprintf('TARGET RANGE ASSOCIATION\n');
fprintf('====================================================\n');

fprintf('Radar time             : %.3f s\n', radarTime);

fprintf('Detected range        : %.3f m\n', detectedRange);

disp(AssociationTable);

end