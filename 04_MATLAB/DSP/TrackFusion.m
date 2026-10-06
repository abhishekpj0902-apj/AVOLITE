function Fusion = TrackFusion(InitiatedTracks)

%=========================================================
% SARRS STUDIO
% Track Fusion
%
% Combines multiple radar tracks into a fused track list
%=========================================================

Fusion = struct([]);

%% No Tracks

if isempty(InitiatedTracks)

    return

end

TrackCount = 0;

for k = 1:length(InitiatedTracks)

    %% Skip statistics structure

    if ~isfield(InitiatedTracks(k),"TrackID")
        continue
    end

    %% Skip tentative tracks

    if ~InitiatedTracks(k).Confirmed
        continue
    end

    TrackCount = TrackCount + 1;

    Fusion(TrackCount).TrackID = ...
        InitiatedTracks(k).TrackID;

    Fusion(TrackCount).Range = ...
        InitiatedTracks(k).Range;

    Fusion(TrackCount).State = ...
        InitiatedTracks(k).State;

    %% Fusion Confidence

    Fusion(TrackCount).Confidence = 0.95;

    %% Sensor Information

    Fusion(TrackCount).SensorSource = ...
        "Primary Radar";

    %% Time Stamp

    Fusion(TrackCount).TimeStamp = now;

end

%% Statistics

if isempty(Fusion)

    Fusion = struct;

    Fusion.NumberOfTracks = 0;

else

    Fusion(end).NumberOfTracks = TrackCount;

end

end