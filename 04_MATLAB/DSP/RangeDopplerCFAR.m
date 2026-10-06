function CFAR2D = RangeDopplerCFAR(RDMap)

%=========================================================
% SARRS STUDIO
% Multi-PRF Range-Doppler CFAR
%
% Processing:
%
% Multi-PRF Range-Doppler Map
%            ↓
%       2-D CA-CFAR
%            ↓
%   Local Target Detection
%            ↓
%     Target List
%
% Data format:
%   Rows    = detected range gates
%   Columns = Doppler bins
%
% Features:
%   ✓ Multi-PRF compatible
%   ✓ Range-Doppler detection
%   ✓ Local noise estimation
%   ✓ Cell Under Test
%   ✓ Guard cells
%   ✓ Training cells
%   ✓ Local maxima
%   ✓ Duplicate suppression
%=========================================================


%% ========================================================
% Input Validation
%========================================================

if ~isstruct(RDMap)

    error( ...
        'RangeDopplerCFAR: RDMap must be a structure.');

end


if ~isfield(RDMap,'Data')

    error( ...
        'RangeDopplerCFAR: RDMap.Data not found.');

end


RD = abs(double(RDMap.Data));


if isempty(RD)

    error( ...
        'RangeDopplerCFAR: Range-Doppler map is empty.');

end


%% ========================================================
% Dimensions
%========================================================

[NumRangeBins,NumDopplerBins] = ...
    size(RD);


%% ========================================================
% Normalize
%========================================================

MaximumValue = ...
    max(RD(:));


if MaximumValue > 0

    RD = ...
        RD ./ MaximumValue;

end


%% ========================================================
% CFAR Parameters
%=========================================================

% Range training cells

TrainingRange = 1;

% Doppler training cells

TrainingDoppler = 16;

% Guard cells

GuardRange = 0;

GuardDoppler = 4;

% Number of detected targets

MaxTargets = 5;

% Threshold multiplier

ThresholdScale = 2.5;


%% ========================================================
% Detection Map
%=========================================================

DetectionMask = ...
    false(NumRangeBins,NumDopplerBins);


ThresholdMap = ...
    zeros(NumRangeBins,NumDopplerBins);


%% ========================================================
% CA-CFAR Processing
%=========================================================

for r = 1:NumRangeBins

    for d = 1:NumDopplerBins


        %% ================================================
        % Doppler Training Window
        %================================================

        DopplerStart = ...
            max(1,...
            d - TrainingDoppler - GuardDoppler);

        DopplerEnd = ...
            min(NumDopplerBins,...
            d + TrainingDoppler + GuardDoppler);


        %% ================================================
        % Range Training Window
        %================================================

        RangeStart = ...
            max(1,...
            r - TrainingRange - GuardRange);

        RangeEnd = ...
            min(NumRangeBins,...
            r + TrainingRange + GuardRange);


        %% ================================================
        % Extract Training Cells
        %================================================

        Window = ...
            RD( ...
                RangeStart:RangeEnd,...
                DopplerStart:DopplerEnd);


        %% ================================================
        % Remove Guard / CUT Cells
        %================================================

        RangeIndex = ...
            (RangeStart:RangeEnd)';


        DopplerIndex = ...
            DopplerStart:DopplerEnd;


        RangeDistance = ...
            abs(RangeIndex-r);


        DopplerDistance = ...
            abs(DopplerIndex-d);


        GuardMask = ...
            (RangeDistance <= GuardRange) & ...
            (DopplerDistance <= GuardDoppler);


        TrainingMask = ...
            ~GuardMask;


        TrainingCells = ...
            Window(TrainingMask);


        %% ================================================
        % Noise Estimate
        %================================================

        if isempty(TrainingCells)

            NoiseEstimate = 0;

        else

            NoiseEstimate = ...
                mean(TrainingCells);

        end


        %% ================================================
        % Threshold
        %================================================

        Threshold = ...
            NoiseEstimate * ThresholdScale;


        % Prevent zero threshold

        Threshold = ...
            max(Threshold,0.05);


        ThresholdMap(r,d) = ...
            Threshold;


        %% ================================================
        % Cell Under Test
        %================================================

        CUT = ...
            RD(r,d);


        if CUT > Threshold

            DetectionMask(r,d) = true;

        end

    end

end


%% ========================================================
% Local Maximum Suppression
%=========================================================

LocalMaximum = ...
    true(size(RD));


%% Range direction

if NumRangeBins >= 3

    LocalMaximum(2:end-1,:) = ...
        RD(2:end-1,:) >= ...
        RD(1:end-2,:) & ...
        RD(2:end-1,:) >= ...
        RD(3:end,:);

end


%% Doppler direction

if NumDopplerBins >= 3

    DopplerMaximum = ...
        true(size(RD));


    DopplerMaximum(:,2:end-1) = ...
        RD(:,2:end-1) >= ...
        RD(:,1:end-2) & ...
        RD(:,2:end-1) >= ...
        RD(:,3:end);


    LocalMaximum = ...
        LocalMaximum & ...
        DopplerMaximum;

end


%% ========================================================
% Final Detection Mask
%=========================================================

DetectionMask = ...
    DetectionMask & ...
    LocalMaximum;


%% ========================================================
% Extract Detections
%=========================================================

[row,col] = ...
    find(DetectionMask);


%% ========================================================
% Sort By Amplitude
%=========================================================

if ~isempty(row)

    LinearIndex = ...
        sub2ind( ...
            size(RD),...
            row,...
            col);


    Amplitudes = ...
        RD(LinearIndex);


    [Amplitudes,Order] = ...
        sort( ...
            Amplitudes,...
            'descend');


    row = ...
        row(Order);


    col = ...
        col(Order);

else

    Amplitudes = [];

end


%% ========================================================
% Duplicate / Nearby Target Suppression
%=========================================================

SelectedRows = [];

SelectedCols = [];

SelectedAmplitudes = [];


RangeSeparation = 1;

DopplerSeparation = 20;


for k = 1:length(row)

    CurrentRow = row(k);

    CurrentCol = col(k);


    if isempty(SelectedRows)

        Accept = true;

    else

        RangeDifference = ...
            abs(SelectedRows - CurrentRow);


        DopplerDifference = ...
            abs(SelectedCols - CurrentCol);


        Accept = ...
            ~any( ...
                RangeDifference <= RangeSeparation & ...
                DopplerDifference <= DopplerSeparation);

    end


    if Accept

        SelectedRows(end+1) = ...
            CurrentRow;

        SelectedCols(end+1) = ...
            CurrentCol;

        SelectedAmplitudes(end+1) = ...
            Amplitudes(k);

    end


    if length(SelectedRows) >= MaxTargets

        break;

    end

end


%% ========================================================
% Target Structure
%=========================================================

Targets = struct( ...
    'RangeIndex',{},...
    'VelocityIndex',{},...
    'Range',{},...
    'Velocity',{},...
    'Doppler',{},...
    'Amplitude',{});


for k = 1:length(SelectedRows)

    r = SelectedRows(k);

    d = SelectedCols(k);


    %% Range

    if isfield(RDMap,'RangeAxis')

        RangeValue = ...
            RDMap.RangeAxis(r);

    elseif isfield(RDMap,'FullRangeAxis')

        RangeValue = ...
            RDMap.FullRangeAxis(r);

    else

        RangeValue = r;

    end


    %% Velocity

    VelocityValue = ...
        RDMap.VelocityAxis(d);


    %% Doppler

    if isfield(RDMap,'DopplerAxis')

        DopplerValue = ...
            RDMap.DopplerAxis(d);

    else

        DopplerValue = NaN;

    end


    Targets(k).RangeIndex = ...
        r;

    Targets(k).VelocityIndex = ...
        d;

    Targets(k).Range = ...
        RangeValue;

    Targets(k).Velocity = ...
        VelocityValue;

    Targets(k).Doppler = ...
        DopplerValue;

    Targets(k).Amplitude = ...
        SelectedAmplitudes(k);

end


%% ========================================================
% Results
%=========================================================

CFAR2D.Map = ...
    RD;


CFAR2D.DetectionMask = ...
    DetectionMask;


CFAR2D.ThresholdMap = ...
    ThresholdMap;


CFAR2D.ThresholdScale = ...
    ThresholdScale;


CFAR2D.TrainingRange = ...
    TrainingRange;


CFAR2D.TrainingDoppler = ...
    TrainingDoppler;


CFAR2D.GuardRange = ...
    GuardRange;


CFAR2D.GuardDoppler = ...
    GuardDoppler;


CFAR2D.Targets = ...
    Targets;


CFAR2D.NumberOfTargets = ...
    length(Targets);


CFAR2D.TargetDetected = ...
    ~isempty(Targets);


CFAR2D.Description = ...
    "Multi-PRF 2-D CA-CFAR";


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Multi-PRF Range-Doppler CFAR');
disp('=========================================');


fprintf( ...
    'Range Bins       : %d\n',...
    NumRangeBins);


fprintf( ...
    'Doppler Bins     : %d\n',...
    NumDopplerBins);


fprintf( ...
    'Training Range   : %d cells\n',...
    TrainingRange);


fprintf( ...
    'Training Doppler : %d cells\n',...
    TrainingDoppler);


fprintf( ...
    'Guard Range      : %d cells\n',...
    GuardRange);


fprintf( ...
    'Guard Doppler    : %d cells\n',...
    GuardDoppler);


fprintf( ...
    'Threshold Scale  : %.2f\n',...
    ThresholdScale);


fprintf( ...
    'Targets          : %d\n',...
    CFAR2D.NumberOfTargets);


%% ========================================================
% Target Display
%=========================================================

disp(' ');
disp('CFAR Target Detections');
disp('-----------------------------------------');


for k = 1:CFAR2D.NumberOfTargets

    fprintf( ...
        'Target %d : Range %.2f km | Doppler %.2f Hz | Velocity %.2f m/s | Amplitude %.3f\n',...
        k,...
        Targets(k).Range/1000,...
        Targets(k).Doppler,...
        Targets(k).Velocity,...
        Targets(k).Amplitude);

end


%% ========================================================
% Visualization
%=========================================================

figure( ...
    'Name','Multi-PRF Range Doppler CFAR',...
    'NumberTitle','off');


imagesc( ...
    RDMap.VelocityAxis,...
    RDMap.RangeAxis/1000,...
    RD);


axis xy;


xlabel('Velocity (m/s)');

ylabel('Range (km)');

title( ...
    'Multi-PRF Range-Doppler CFAR');


colorbar;

hold on;


%% ========================================================
% Plot Detected Targets
%=========================================================

if CFAR2D.NumberOfTargets > 0

    TargetRanges = ...
        [Targets.Range] / 1000;


    TargetVelocities = ...
        [Targets.Velocity];


    plot( ...
        TargetVelocities,...
        TargetRanges,...
        'rv',...
        'MarkerFaceColor','r',...
        'MarkerSize',8);

end


grid on;

hold off;


end