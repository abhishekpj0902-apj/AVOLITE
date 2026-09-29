function Clustered = TargetCluster(CFARResult, RadarData)

% ============================================================
% TARGET CLUSTERING / PEAK GROUPING
% ============================================================

if nargin < 2
    error("TargetCluster requires CFARResult and RadarData.");
end

Range = CFARResult.Range(:);
Doppler = CFARResult.Doppler(:);
Velocity = CFARResult.Velocity(:);
Amplitude = CFARResult.Amplitude(:);

if isempty(Range)
    Clustered = CFARResult;
    Clustered.NumberOfTargets = 0;
    Clustered.ClusteredTargets = table();
    return;
end

% ------------------------------------------------------------
% Clustering tolerances
% ------------------------------------------------------------

RangeTolerance = 300;      % metres
DopplerTolerance = 10;     % Hz

% Sort detections by descending amplitude
[~, SortIndex] = sort(Amplitude, "descend");

Range = Range(SortIndex);
Doppler = Doppler(SortIndex);
Velocity = Velocity(SortIndex);
Amplitude = Amplitude(SortIndex);

Used = false(length(Range), 1);

ClusterRange = [];
ClusterDoppler = [];
ClusterVelocity = [];
ClusterAmplitude = [];
ClusterCount = [];

% ------------------------------------------------------------
% Group neighboring detections
% ------------------------------------------------------------

for i = 1:length(Range)

    if Used(i)
        continue;
    end

    CurrentRange = Range(i);
    CurrentDoppler = Doppler(i);

    DistanceMask = ...
        abs(Range - CurrentRange) <= RangeTolerance & ...
        abs(Doppler - CurrentDoppler) <= DopplerTolerance & ...
        ~Used;

    Members = find(DistanceMask);

    if isempty(Members)
        continue;
    end

    % Mark members as used
    Used(Members) = true;

    % Select the strongest member as the representative target
    [~, StrongestLocalIndex] = max(Amplitude(Members));
    StrongestIndex = Members(StrongestLocalIndex);

    ClusterRange(end+1,1) = Range(StrongestIndex);
    ClusterDoppler(end+1,1) = Doppler(StrongestIndex);
    ClusterVelocity(end+1,1) = Velocity(StrongestIndex);
    ClusterAmplitude(end+1,1) = Amplitude(StrongestIndex);
    ClusterCount(end+1,1) = length(Members);

end

% ------------------------------------------------------------
% Store clustered results
% ------------------------------------------------------------

Clustered = CFARResult;

Clustered.Range = ClusterRange;
Clustered.Doppler = ClusterDoppler;
Clustered.Velocity = ClusterVelocity;
Clustered.Amplitude = ClusterAmplitude;
Clustered.NumberOfTargets = length(ClusterRange);
Clustered.ClusterCount = ClusterCount;

Clustered.ClusteredTargets = table( ...
    ClusterRange, ...
    ClusterDoppler, ...
    ClusterVelocity, ...
    ClusterAmplitude, ...
    ClusterCount, ...
    'VariableNames', { ...
    'Range_m', ...
    'Doppler_Hz', ...
    'Velocity_mps', ...
    'Amplitude', ...
    'CellsGrouped'});

% ------------------------------------------------------------
% Print result
% ------------------------------------------------------------

fprintf("\n==============================================\n");
fprintf("TARGET CLUSTERING RESULT\n");
fprintf("==============================================\n");

fprintf("Raw CFAR detections : %d\n", length(Range));
fprintf("Clustered targets   : %d\n", Clustered.NumberOfTargets);

fprintf("\n");

disp(Clustered.ClusteredTargets);

fprintf("==============================================\n\n");

end