function Track = TrackingFilter(Peaks)

%=========================================================
% SARRS STUDIO
% Tracking Filter
%
% Smooths detected target positions before tracking
%=========================================================

Track = struct;

%% No Targets

if ~Peaks.TargetDetected

    Track.Index = [];
    Track.Range = [];
    Track.NumberOfTargets = 0;

    return

end

%% Parameters

Window = 3;

FilteredIndex = Peaks.Index;

%% Moving Average Filter

for i = 2:length(Peaks.Index)-1

    FilteredIndex(i) = round(mean(...
        Peaks.Index(i-1:i+1)));

end

%% Output

Track.Index = FilteredIndex;

Track.Range = FilteredIndex;

Track.Peaks = Peaks.Value;

Track.NumberOfTargets = length(FilteredIndex);

end