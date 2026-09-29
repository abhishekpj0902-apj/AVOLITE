function ActiveTracks = TrackTerminator(Fusion)

%=========================================================
% SARRS STUDIO
% Track Terminator
%
% Removes lost or invalid radar tracks
%=========================================================

ActiveTracks = struct([]);

%% No Tracks

if isempty(Fusion)

    return

end

Count = 0;

for k = 1:length(Fusion)

    %% Skip statistics entry

    if ~isfield(Fusion(k),"TrackID")
        continue
    end

    %% Check Confidence

    if Fusion(k).Confidence < 0.50

        continue

    end

    %% Keep Active Track

    Count = Count + 1;

    ActiveTracks(Count).TrackID = ...
        Fusion(k).TrackID;

    ActiveTracks(Count).Range = ...
        Fusion(k).Range;

    ActiveTracks(Count).State = ...
        "ACTIVE";

    ActiveTracks(Count).Confidence = ...
        Fusion(k).Confidence;

    ActiveTracks(Count).SensorSource = ...
        Fusion(k).SensorSource;

    ActiveTracks(Count).TimeStamp = ...
        Fusion(k).TimeStamp;

end

%% Statistics

if isempty(ActiveTracks)

    ActiveTracks = struct;

    ActiveTracks.NumberOfTracks = 0;

else

    ActiveTracks(end).NumberOfTracks = Count;

end

end