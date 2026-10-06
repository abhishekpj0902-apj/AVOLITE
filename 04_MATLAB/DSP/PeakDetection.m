function Peaks = PeakDetection(CFAR)

%=========================================================
% SARRS STUDIO
% Peak Detection
%
% Extracts valid target peaks from CFAR detections
%=========================================================

Peaks = struct;

%% No Detection

if ~CFAR.TargetDetected

    Peaks.Index = [];
    Peaks.Value = [];
    Peaks.NumberOfTargets = 0;
    Peaks.TargetDetected = false;

    return

end

%% Read CFAR Output

Signal = CFAR.Signal;

Index = CFAR.Index;

%% Keep only Local Maxima

PeakIndex = [];
PeakValue = [];

for k = 1:length(Index)

    i = Index(k);

    if i<=1 || i>=length(Signal)
        continue
    end

    if Signal(i)>=Signal(i-1) && Signal(i)>=Signal(i+1)

        PeakIndex(end+1)=i;
        PeakValue(end+1)=Signal(i);

    end

end

%% Remove Duplicate Peaks

MinimumSpacing = 20;

FinalIndex = [];
FinalValue = [];

for k=1:length(PeakIndex)

    if isempty(FinalIndex)

        FinalIndex(end+1)=PeakIndex(k);
        FinalValue(end+1)=PeakValue(k);

    else

        if PeakIndex(k)-FinalIndex(end) > MinimumSpacing

            FinalIndex(end+1)=PeakIndex(k);
            FinalValue(end+1)=PeakValue(k);

        elseif PeakValue(k) > FinalValue(end)

            FinalIndex(end)=PeakIndex(k);
            FinalValue(end)=PeakValue(k);

        end

    end

end

%% Sort by Amplitude

[FinalValue,Order] = sort(FinalValue,'descend');

FinalIndex = FinalIndex(Order);

%% Output

Peaks.Index = FinalIndex;

Peaks.Value = FinalValue;

Peaks.NumberOfTargets = length(FinalIndex);

Peaks.TargetDetected = ~isempty(FinalIndex);

end