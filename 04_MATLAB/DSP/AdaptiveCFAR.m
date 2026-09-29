function CFAR = AdaptiveCFAR(InputData,Noise)

%=========================================================
% SARRS STUDIO
% Adaptive CA-CFAR Detector
% One Detection Per Target
%=========================================================

%% Extract Signal

if isstruct(InputData)

    if isfield(InputData,'Magnitude')
        Signal = InputData.Magnitude;

    elseif isfield(InputData,'Output')
        Signal = InputData.Output;

    elseif isfield(InputData,'Input')
        Signal = InputData.Input;

    else
        error('Unsupported Input Structure');
    end

else

    Signal = InputData;

end

Signal = abs(double(Signal(:)));

%% Debug

disp(' ')
disp('========== CFAR DEBUG ==========')

fprintf('Signal Length : %d\n',length(Signal));
fprintf('Signal Max    : %e\n',max(Signal));
fprintf('Signal Mean   : %e\n',mean(Signal));
fprintf('Signal Min    : %e\n',min(Signal));

%% Default Noise

if nargin<2

    Noise.Floor = mean(Signal);
    Noise.SNR   = 20;

end

%% Parameters

TrainingCells = 12;
GuardCells    = 4;
ScaleFactor   = 4.5;

N = length(Signal);

Threshold = zeros(N,1);
Detection = zeros(N,1);

%% CFAR

for i = TrainingCells+GuardCells+1 : N-(TrainingCells+GuardCells)

    Left = Signal(i-GuardCells-TrainingCells : i-GuardCells-1);

    Right = Signal(i+GuardCells+1 : i+GuardCells+TrainingCells);

    NoiseEstimate = mean([Left;Right]);

    Threshold(i)=ScaleFactor*NoiseEstimate;

    %-------------------------------
    % Local Maximum Test
    %-------------------------------

    if Signal(i)>Threshold(i)

        if Signal(i)>Signal(i-1) && Signal(i)>=Signal(i+1)

            Detection(i)=1;

        end

    end

end

%% Merge Nearby Peaks

CandidateIndex = find(Detection);

if isempty(CandidateIndex)

    Index=[];

    Peaks=[];

else

    [Peaks,Locs] = findpeaks(...
        Signal,...
        'MinPeakHeight',mean(Threshold),...
        'MinPeakDistance',300);

    Index=Locs;

end

%% Output

CFAR.Signal=Signal;

CFAR.Threshold=Threshold;

CFAR.Detection=zeros(N,1);

CFAR.Detection(Index)=1;

CFAR.Index=Index;

CFAR.Peaks=Peaks;

CFAR.NumberOfTargets=length(Index);

CFAR.TargetDetected=~isempty(Index);

CFAR.NoiseFloor=Noise.Floor;

CFAR.EstimatedSNR=Noise.SNR;

if isempty(Peaks)

    CFAR.PeakValue=0;

else

    CFAR.PeakValue=max(Peaks);

end

%% Debug

disp(' ')
disp('========== CFAR RESULTS ==========')

fprintf('Noise Floor      : %e\n',Noise.Floor);

fprintf('Threshold Mean   : %e\n',mean(Threshold));

fprintf('Targets Found    : %d\n',CFAR.NumberOfTargets);

fprintf('Peak Value       : %e\n',CFAR.PeakValue);

disp('=================================')

end