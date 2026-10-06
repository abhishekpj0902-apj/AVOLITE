%% ============================================================
%  SARRS STUDIO - FIVE-TARGET 2D CA-CFAR DETECTION
%  File: CFAR_FiveTargetRadar.m
% =============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - 2D CA-CFAR TARGET DETECTION\n');
fprintf('============================================================\n\n');

%% ------------------------------------------------------------
% 1. FIND LATEST RADAR RESULT FILE
% ------------------------------------------------------------

ResultsFolder = fullfile(pwd, 'SARRS_Results');

if ~isfolder(ResultsFolder)
    error('Results folder not found: %s', ResultsFolder);
end

Files = dir(fullfile(ResultsFolder, 'FiveTargetRadar_Result_*.mat'));

if isempty(Files)
    error('No radar MAT file found. Run FiveTargetRadar.m first.');
end

% Sort files by modification time
[~, SortIndex] = sort([Files.datenum], 'descend');
Files = Files(SortIndex);

LatestFile = fullfile(ResultsFolder, Files(1).name);

fprintf('Latest radar result:\n');
fprintf('%s\n\n', LatestFile);

%% ------------------------------------------------------------
% 2. LOAD RADAR DATA
% ------------------------------------------------------------

Data = load(LatestFile);

fprintf('MAT file loaded successfully.\n');

%% Read variables from the top level of the MAT file

% Range axis
if isfield(Data, 'RangeAxis')
    RangeAxis = Data.RangeAxis;
elseif isfield(Data, 'RadarResult') && ...
       isfield(Data.RadarResult, 'RangeAxis')

    RangeAxis = Data.RadarResult.RangeAxis;

else
    error('RangeAxis was not found in the MAT file.');
end

% Velocity axis
if isfield(Data, 'VelocityAxis')
    VelocityAxis = Data.VelocityAxis;
elseif isfield(Data, 'RadarResult') && ...
       isfield(Data.RadarResult, 'VelocityAxis')

    VelocityAxis = Data.RadarResult.VelocityAxis;

else
    error('VelocityAxis was not found in the MAT file.');
end

% Range-Doppler map in dB
if isfield(Data, 'DopplerMap_dB')
    DopplerMap_dB = Data.DopplerMap_dB;
elseif isfield(Data, 'RadarResult') && ...
       isfield(Data.RadarResult, 'DopplerMap_dB')

    DopplerMap_dB = Data.RadarResult.DopplerMap_dB;

else
    error('DopplerMap_dB was not found in the MAT file.');
end

% Expected target ranges
if isfield(Data, 'TargetRanges')
    TargetRanges = Data.TargetRanges;
elseif isfield(Data, 'RadarResult') && ...
       isfield(Data.RadarResult, 'TargetRanges')

    TargetRanges = Data.RadarResult.TargetRanges;

else
    error('TargetRanges was not found in the MAT file.');
end

% Expected target velocities
if isfield(Data, 'TargetVelocities')
    TargetVelocities = Data.TargetVelocities;
elseif isfield(Data, 'RadarResult') && ...
       isfield(Data.RadarResult, 'TargetVelocities')

    TargetVelocities = Data.RadarResult.TargetVelocities;

else
    error('TargetVelocities was not found in the MAT file.');
end

%% Convert data to correct format

RangeAxis = double(RangeAxis(:).');

VelocityAxis = double(VelocityAxis(:));

DopplerMap_dB = double(DopplerMap_dB);

TargetRanges = double(TargetRanges(:).');

TargetVelocities = double(TargetVelocities(:).');

% Replace invalid values
DopplerMap_dB(~isfinite(DopplerMap_dB)) = -100;

fprintf('Radar data loaded successfully.\n');
fprintf('Range-Doppler map size: %d x %d\n\n', ...
    size(DopplerMap_dB, 1), size(DopplerMap_dB, 2));

%% ------------------------------------------------------------
% 3. RADAR MAP PREPARATION
% ------------------------------------------------------------

% Ensure the map is a 2D matrix
DopplerMap_dB = double(DopplerMap_dB);

% Replace invalid values
DopplerMap_dB(~isfinite(DopplerMap_dB)) = -100;

% Convert dB map to linear power
PowerMap = 10.^(DopplerMap_dB / 10);

% Normalize the map
PowerMap = PowerMap ./ max(PowerMap(:));

[NumDoppler, NumRange] = size(PowerMap);

%% ------------------------------------------------------------
% 4. CFAR PARAMETERS
% ------------------------------------------------------------

% Guard cells around Cell Under Test
GuardDoppler = 2;
GuardRange   = 2;

% Training cells around Cell Under Test
TrainingDoppler = 6;
TrainingRange   = 8;

% Desired probability of false alarm
Pfa = 1e-4;

% Total CFAR window size
TotalDoppler = 2 * (TrainingDoppler + GuardDoppler) + 1;
TotalRange   = 2 * (TrainingRange + GuardRange) + 1;

% Number of training cells
TotalCells = TotalDoppler * TotalRange;

GuardCells = ...
    (2 * GuardDoppler + 1) * ...
    (2 * GuardRange + 1);

NumTrainingCells = TotalCells - GuardCells;

% CA-CFAR threshold scaling factor
Alpha = NumTrainingCells * ...
    (Pfa^(-1 / NumTrainingCells) - 1);

fprintf('CFAR PARAMETERS\n');
fprintf('------------------------------------------------------------\n');
fprintf('Training Doppler cells : %d\n', TrainingDoppler);
fprintf('Training Range cells   : %d\n', TrainingRange);
fprintf('Guard Doppler cells    : %d\n', GuardDoppler);
fprintf('Guard Range cells      : %d\n', GuardRange);
fprintf('Probability of false alarm: %.2e\n', Pfa);
fprintf('Training cell count    : %d\n', NumTrainingCells);
fprintf('Threshold factor Alpha : %.4f\n\n', Alpha);

%% ------------------------------------------------------------
% 5. 2D CA-CFAR PROCESSING
% ------------------------------------------------------------

CFARThreshold = zeros(NumDoppler, NumRange);
CFARDetection = false(NumDoppler, NumRange);

StartDoppler = TrainingDoppler + GuardDoppler + 1;
EndDoppler   = NumDoppler - TrainingDoppler - GuardDoppler;

StartRange = TrainingRange + GuardRange + 1;
EndRange   = NumRange - TrainingRange - GuardRange;

fprintf('Running 2D CA-CFAR processing...\n');

for DopplerIndex = StartDoppler:EndDoppler

    for RangeIndex = StartRange:EndRange

        % Extract complete CFAR window
        DopplerLimits = ...
            DopplerIndex - TrainingDoppler - GuardDoppler : ...
            DopplerIndex + TrainingDoppler + GuardDoppler;

        RangeLimits = ...
            RangeIndex - TrainingRange - GuardRange : ...
            RangeIndex + TrainingRange + GuardRange;

        CFARWindow = PowerMap(DopplerLimits, RangeLimits);

        % Create guard-cell mask
        CenterDoppler = TrainingDoppler + GuardDoppler + 1;
        CenterRange   = TrainingRange + GuardRange + 1;

        GuardMask = true(size(CFARWindow));

        GuardMask( ...
            CenterDoppler - GuardDoppler : ...
            CenterDoppler + GuardDoppler, ...
            CenterRange - GuardRange : ...
            CenterRange + GuardRange) = false;

        % Training cell values
        TrainingValues = CFARWindow(GuardMask);

        % Estimate noise power
        NoisePower = mean(TrainingValues);

        % Calculate threshold
        Threshold = Alpha * NoisePower;

        CFARThreshold(DopplerIndex, RangeIndex) = Threshold;

        % Cell Under Test
        CellUnderTest = PowerMap(DopplerIndex, RangeIndex);

        % Detection decision
        if CellUnderTest > Threshold
            CFARDetection(DopplerIndex, RangeIndex) = true;
        end

    end

end

fprintf('CFAR processing completed.\n\n');

%% ------------------------------------------------------------
% 6. REMOVE VERY WEAK DETECTIONS
% ------------------------------------------------------------

% Additional relative threshold to remove unwanted noise
RelativeThreshold_dB = -18;

RelativeThreshold = 10^(RelativeThreshold_dB / 10);

CFARDetection = CFARDetection & ...
                (PowerMap > RelativeThreshold);

%% ------------------------------------------------------------
% 7. FIND LOCAL MAXIMUM DETECTIONS
% ------------------------------------------------------------

CandidateDoppler = [];
CandidateRange   = [];
CandidatePower   = [];

for DopplerIndex = 2:NumDoppler-1

    for RangeIndex = 2:NumRange-1

        if CFARDetection(DopplerIndex, RangeIndex)

            LocalWindow = PowerMap( ...
                DopplerIndex-1:DopplerIndex+1, ...
                RangeIndex-1:RangeIndex+1);

            CurrentPower = PowerMap(DopplerIndex, RangeIndex);

            % Check if the current cell is a local maximum
            if CurrentPower == max(LocalWindow(:))

                CandidateDoppler(end+1) = DopplerIndex;
                CandidateRange(end+1)   = RangeIndex;
                CandidatePower(end+1)   = CurrentPower;

            end

        end

    end

end

%% ------------------------------------------------------------
% 8. SORT CANDIDATES BY POWER
% ------------------------------------------------------------

if isempty(CandidatePower)

    warning('No CFAR targets detected.');
    return;

end

[CandidatePower, SortIndex] = ...
    sort(CandidatePower, 'descend');

CandidateDoppler = CandidateDoppler(SortIndex);
CandidateRange   = CandidateRange(SortIndex);

%% ------------------------------------------------------------
% 9. NON-MAXIMUM SUPPRESSION
% ------------------------------------------------------------

% Minimum separation between detections
MinimumRangeSeparation = 5;       % metres
MinimumVelocitySeparation = 1.5;  % m/s

DetectedRange = [];
DetectedVelocity = [];
DetectedPower = [];

MaximumTargets = 5;

for CandidateIndex = 1:length(CandidatePower)

    CurrentRange = RangeAxis(CandidateRange(CandidateIndex));
    CurrentVelocity = VelocityAxis(CandidateDoppler(CandidateIndex));
    CurrentPower_dB = 10 * log10(CandidatePower(CandidateIndex));

    IsSeparated = true;

    for ExistingIndex = 1:length(DetectedRange)

        RangeDifference = abs( ...
            CurrentRange - DetectedRange(ExistingIndex));

        VelocityDifference = abs( ...
            CurrentVelocity - DetectedVelocity(ExistingIndex));

        if RangeDifference < MinimumRangeSeparation && ...
           VelocityDifference < MinimumVelocitySeparation

            IsSeparated = false;
            break;

        end

    end

    if IsSeparated

        DetectedRange(end+1) = CurrentRange;
        DetectedVelocity(end+1) = CurrentVelocity;
        DetectedPower(end+1) = CurrentPower_dB;

    end

    if length(DetectedRange) >= MaximumTargets
        break;
    end

end

%% ------------------------------------------------------------
% 10. SORT DETECTIONS BY RANGE
% ------------------------------------------------------------

[DetectedRange, SortIndex] = sort(DetectedRange);

DetectedVelocity = DetectedVelocity(SortIndex);
DetectedPower = DetectedPower(SortIndex);

%% ------------------------------------------------------------
% 11. PRINT DETECTION RESULTS
% ------------------------------------------------------------

fprintf('CFAR DETECTION RESULTS\n');
fprintf('------------------------------------------------------------\n');

fprintf('%8s %18s %20s %15s\n', ...
    'Target', 'Detected Range', 'Detected Velocity', 'Power');

fprintf('%8s %18s %20s %15s\n', ...
    '', '(m)', '(m/s)', '(dB)');

for Index = 1:length(DetectedRange)

    fprintf('%8d %18.2f %20.2f %15.2f\n', ...
        Index, ...
        DetectedRange(Index), ...
        DetectedVelocity(Index), ...
        DetectedPower(Index));

end

fprintf('\n');

%% ------------------------------------------------------------
% 12. COMPARE WITH EXPECTED TARGETS
% ------------------------------------------------------------

fprintf('EXPECTED VS DETECTED TARGETS\n');
fprintf('------------------------------------------------------------\n');

fprintf('%8s %15s %15s %15s %15s\n', ...
    'Target', 'Expected R', 'Detected R', ...
    'Expected V', 'Detected V');

NumberOfComparisons = min( ...
    length(TargetRanges), length(DetectedRange));

RangeErrors = zeros(1, NumberOfComparisons);
VelocityErrors = zeros(1, NumberOfComparisons);

for Index = 1:NumberOfComparisons

    RangeErrors(Index) = ...
        DetectedRange(Index) - TargetRanges(Index);

    VelocityErrors(Index) = ...
        DetectedVelocity(Index) - TargetVelocities(Index);

    fprintf('%8d %15.2f %15.2f %15.2f %15.2f\n', ...
        Index, ...
        TargetRanges(Index), ...
        DetectedRange(Index), ...
        TargetVelocities(Index), ...
        DetectedVelocity(Index));

end

fprintf('\n');

%% ------------------------------------------------------------
% 13. ERROR CALCULATION
% ------------------------------------------------------------

if ~isempty(RangeErrors)

    fprintf('RANGE ERROR RESULTS\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Maximum range error : %.4f m\n', max(abs(RangeErrors)));
    fprintf('Mean range error    : %.4f m\n', mean(abs(RangeErrors)));

    fprintf('\nVELOCITY ERROR RESULTS\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Maximum velocity error : %.4f m/s\n', ...
        max(abs(VelocityErrors)));

    fprintf('Mean velocity error    : %.4f m/s\n', ...
        mean(abs(VelocityErrors)));

end

%% ------------------------------------------------------------
% 14. PLOT ORIGINAL RANGE-DOPPLER MAP
% ------------------------------------------------------------

figure('Name', 'Original Range-Doppler Map', ...
       'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
xlabel('Range (m)');
ylabel('Velocity (m/s)');
title('Original Five-Target Range-Doppler Map');

colormap turbo;
colorbar;
caxis([-40 0]);

hold on;

plot(TargetRanges, TargetVelocities, ...
    'wo', ...
    'MarkerSize', 10, ...
    'LineWidth', 2);

for Index = 1:length(TargetRanges)

    text(TargetRanges(Index) + 2, ...
         TargetVelocities(Index), ...
         sprintf('T%d', Index), ...
         'Color', 'w', ...
         'FontWeight', 'bold', ...
         'FontSize', 11);

end

grid on;

%% ------------------------------------------------------------
% 15. PLOT CFAR DETECTION MAP
% ------------------------------------------------------------

CFARMap_dB = -80 * ones(size(PowerMap));

CFARMap_dB(CFARDetection) = ...
    10 * log10(PowerMap(CFARDetection));

figure('Name', '2D CA-CFAR Detection Map', ...
       'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARMap_dB);

axis xy;
xlabel('Range (m)');
ylabel('Velocity (m/s)');
title('2D CA-CFAR Detection Map');

colormap turbo;
colorbar;
caxis([-40 0]);

hold on;

plot(DetectedRange, DetectedVelocity, ...
    'ro', ...
    'MarkerSize', 12, ...
    'LineWidth', 2);

for Index = 1:length(DetectedRange)

    text(DetectedRange(Index) + 2, ...
         DetectedVelocity(Index), ...
         sprintf('D%d', Index), ...
         'Color', 'w', ...
         'FontWeight', 'bold', ...
         'FontSize', 12);

end

grid on;

%% ------------------------------------------------------------
% 16. PLOT CFAR THRESHOLD MAP
% ------------------------------------------------------------

CFARThreshold_dB = 10 * log10(CFARThreshold + eps);

figure('Name', 'CFAR Threshold Map', ...
       'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARThreshold_dB);

axis xy;
xlabel('Range (m)');
ylabel('Velocity (m/s)');
title('CA-CFAR Noise Threshold Map');

colormap turbo;
colorbar;
grid on;

%% ------------------------------------------------------------
% 17. SAVE CFAR RESULTS
% ------------------------------------------------------------

CFARResult = struct();

CFARResult.DetectedRange = DetectedRange;
CFARResult.DetectedVelocity = DetectedVelocity;
CFARResult.DetectedPower_dB = DetectedPower;

CFARResult.ExpectedRange = TargetRanges;
CFARResult.ExpectedVelocity = TargetVelocities;

CFARResult.RangeErrors = RangeErrors;
CFARResult.VelocityErrors = VelocityErrors;

CFARResult.CFARDetection = CFARDetection;
CFARResult.CFARThreshold = CFARThreshold;

CFARResult.Pfa = Pfa;
CFARResult.Alpha = Alpha;
CFARResult.TrainingDoppler = TrainingDoppler;
CFARResult.TrainingRange = TrainingRange;
CFARResult.GuardDoppler = GuardDoppler;
CFARResult.GuardRange = GuardRange;

CFARFileName = sprintf( ...
    'CFAR_FiveTarget_Result_%s.mat', ...
    datestr(now, 'yyyymmdd_HHMMSS'));

CFARFilePath = fullfile(ResultsFolder, CFARFileName);

save(CFARFilePath, 'CFARResult', '-v7');

fprintf('\n');
fprintf('CFAR RESULT SAVED SUCCESSFULLY\n');
fprintf('------------------------------------------------------------\n');
fprintf('%s\n', CFARFilePath);

fprintf('\n============================================================\n');
fprintf('2D CA-CFAR PROCESSING COMPLETED\n');
fprintf('============================================================\n');