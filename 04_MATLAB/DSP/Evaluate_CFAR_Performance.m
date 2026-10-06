%% ============================================================
%  SARRS STUDIO - CA-CFAR PERFORMANCE EVALUATION
% =============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - CA-CFAR PERFORMANCE EVALUATION\n');
fprintf('============================================================\n');

%% ------------------------------------------------------------
% 1. Folder locations
% ------------------------------------------------------------

ResultsFolder = ...
    'D:\SARRS_STUDIO\04_MATLAB\DSP\SARRS_Results';

OutputFolder = fullfile(ResultsFolder, ...
    'CFAR_Performance');

if ~exist(OutputFolder, 'dir')
    mkdir(OutputFolder);
end

%% ------------------------------------------------------------
% 2. Load latest radar result
% ------------------------------------------------------------

RadarFiles = dir(fullfile(ResultsFolder, ...
    'FiveTargetRadar_Result_*.mat'));

if isempty(RadarFiles)
    error('Original radar result file was not found.');
end

[~, idxRadar] = max([RadarFiles.datenum]);
LatestRadarFile = fullfile(ResultsFolder, ...
    RadarFiles(idxRadar).name);

RadarData = load(LatestRadarFile);

fprintf('\nOriginal radar file:\n%s\n', LatestRadarFile);

%% ------------------------------------------------------------
% 3. Load latest CFAR result
% ------------------------------------------------------------

CFARFiles = dir(fullfile(ResultsFolder, ...
    'CFAR_FiveTarget_Result_*.mat'));

if isempty(CFARFiles)
    error('CFAR result file was not found.');
end

[~, idxCFAR] = max([CFARFiles.datenum]);
LatestCFARFile = fullfile(ResultsFolder, ...
    CFARFiles(idxCFAR).name);

CFARData = load(LatestCFARFile);

fprintf('\nCFAR result file:\n%s\n', LatestCFARFile);

%% ------------------------------------------------------------
% 4. Extract original radar data
% ------------------------------------------------------------

DopplerMap_dB = RadarData.DopplerMap_dB;
RangeAxis     = RadarData.RangeAxis;
VelocityAxis  = RadarData.VelocityAxis;

ExpectedRange    = RadarData.TargetRanges;
ExpectedVelocity = RadarData.TargetVelocities;

%% ------------------------------------------------------------
% 5. Extract CFAR data
% ------------------------------------------------------------

CFARResult = CFARData.CFARResult;

CFARDetection = CFARResult.CFARDetection;

DetectedRange    = CFARResult.DetectedRange;
DetectedVelocity = CFARResult.DetectedVelocity;
DetectedPower_dB = CFARResult.DetectedPower_dB;

%% ------------------------------------------------------------
% 6. Number of targets
% ------------------------------------------------------------

NumberOfTargets = length(ExpectedRange);

if length(DetectedRange) ~= NumberOfTargets
    warning(['Expected target count and detected target count ', ...
             'are different.']);
end

%% ------------------------------------------------------------
% 7. Match detected targets with expected targets
% ------------------------------------------------------------

RangeError    = zeros(NumberOfTargets, 1);
VelocityError = zeros(NumberOfTargets, 1);

MatchedRange    = zeros(NumberOfTargets, 1);
MatchedVelocity = zeros(NumberOfTargets, 1);

UsedDetection = false(length(DetectedRange), 1);

for k = 1:NumberOfTargets

    CurrentExpectedRange = ExpectedRange(k);
    CurrentExpectedVelocity = ExpectedVelocity(k);

    DistanceError = sqrt( ...
        (DetectedRange - CurrentExpectedRange).^2 + ...
        (DetectedVelocity - CurrentExpectedVelocity).^2);

    DistanceError(UsedDetection) = inf;

    [~, BestIndex] = min(DistanceError);

    if isfinite(DistanceError(BestIndex))

        UsedDetection(BestIndex) = true;

        MatchedRange(k) = DetectedRange(BestIndex);
        MatchedVelocity(k) = DetectedVelocity(BestIndex);

        RangeError(k) = ...
            MatchedRange(k) - CurrentExpectedRange;

        VelocityError(k) = ...
            MatchedVelocity(k) - CurrentExpectedVelocity;

    else

        MatchedRange(k) = NaN;
        MatchedVelocity(k) = NaN;

        RangeError(k) = NaN;
        VelocityError(k) = NaN;

    end
end

%% ------------------------------------------------------------
% 8. Calculate detection probability
% ------------------------------------------------------------

DetectedTargetCount = sum(~isnan(MatchedRange));

Pd = DetectedTargetCount / NumberOfTargets;

%% ------------------------------------------------------------
% 9. Calculate false alarm probability
% ------------------------------------------------------------

TotalCells = numel(CFARDetection);

DetectedCells = sum(CFARDetection(:));

ExpectedTargetCells = NumberOfTargets;

FalseAlarmCount = max(DetectedCells - ExpectedTargetCells, 0);

Pfa = FalseAlarmCount / TotalCells;

%% ------------------------------------------------------------
% 10. Calculate error statistics
% ------------------------------------------------------------

ValidRangeErrors = RangeError(~isnan(RangeError));
ValidVelocityErrors = VelocityError(~isnan(VelocityError));

if isempty(ValidRangeErrors)

    MeanRangeError = NaN;
    RMSE_Range = NaN;

else

    MeanRangeError = mean(abs(ValidRangeErrors));
    RMSE_Range = sqrt(mean(ValidRangeErrors.^2));

end

if isempty(ValidVelocityErrors)

    MeanVelocityError = NaN;
    RMSE_Velocity = NaN;

else

    MeanVelocityError = mean(abs(ValidVelocityErrors));
    RMSE_Velocity = sqrt(mean(ValidVelocityErrors.^2));

end

%% ------------------------------------------------------------
% 11. Print performance results
% ------------------------------------------------------------

fprintf('\n');
fprintf('CFAR PERFORMANCE RESULTS\n');
fprintf('------------------------------------------------------------\n');

fprintf('Total expected targets       : %d\n', NumberOfTargets);
fprintf('Detected targets             : %d\n', DetectedTargetCount);
fprintf('Total CFAR cells             : %d\n', TotalCells);
fprintf('Detected CFAR cells          : %d\n', DetectedCells);
fprintf('Estimated false alarms       : %d\n', FalseAlarmCount);

fprintf('\n');
fprintf('Detection probability Pd     : %.4f\n', Pd);
fprintf('Detection probability        : %.2f %%\n', Pd * 100);

fprintf('False alarm probability Pfa  : %.6e\n', Pfa);

fprintf('\n');
fprintf('Mean absolute range error    : %.4f m\n', ...
    MeanRangeError);

fprintf('Range RMSE                   : %.4f m\n', ...
    RMSE_Range);

fprintf('Mean absolute velocity error : %.4f m/s\n', ...
    MeanVelocityError);

fprintf('Velocity RMSE                : %.4f m/s\n', ...
    RMSE_Velocity);

%% ------------------------------------------------------------
% 12. Create target performance table
% ------------------------------------------------------------

TargetNumber = (1:NumberOfTargets).';

PerformanceTable = table( ...
    TargetNumber, ...
    ExpectedRange(:), ...
    MatchedRange(:), ...
    RangeError(:), ...
    ExpectedVelocity(:), ...
    MatchedVelocity(:), ...
    VelocityError(:), ...
    'VariableNames', { ...
    'Target', ...
    'ExpectedRange_m', ...
    'DetectedRange_m', ...
    'RangeError_m', ...
    'ExpectedVelocity_mps', ...
    'DetectedVelocity_mps', ...
    'VelocityError_mps'});

fprintf('\n');
disp(PerformanceTable);

%% ------------------------------------------------------------
% 13. Plot expected versus detected range
% ------------------------------------------------------------

Figure1 = figure('Name', ...
    'Expected vs Detected Range', ...
    'Color', 'w');

plot(TargetNumber, ExpectedRange, ...
    'bo-', 'LineWidth', 1.8, ...
    'MarkerSize', 8);

hold on;

plot(TargetNumber, MatchedRange, ...
    'rx--', 'LineWidth', 1.8, ...
    'MarkerSize', 9);

grid on;

xlabel('Target Number');
ylabel('Range (m)');

title('Expected Range vs CA-CFAR Detected Range');

legend('Expected Range', ...
       'Detected Range', ...
       'Location', 'best');

set(gca, 'Toolbar', []);

exportgraphics(Figure1, ...
    fullfile(OutputFolder, ...
    'Expected_vs_Detected_Range.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 14. Plot expected versus detected velocity
% ------------------------------------------------------------

Figure2 = figure('Name', ...
    'Expected vs Detected Velocity', ...
    'Color', 'w');

plot(TargetNumber, ExpectedVelocity, ...
    'bo-', 'LineWidth', 1.8, ...
    'MarkerSize', 8);

hold on;

plot(TargetNumber, MatchedVelocity, ...
    'rx--', 'LineWidth', 1.8, ...
    'MarkerSize', 9);

grid on;

xlabel('Target Number');
ylabel('Velocity (m/s)');

title('Expected Velocity vs CA-CFAR Detected Velocity');

legend('Expected Velocity', ...
       'Detected Velocity', ...
       'Location', 'best');

set(gca, 'Toolbar', []);

exportgraphics(Figure2, ...
    fullfile(OutputFolder, ...
    'Expected_vs_Detected_Velocity.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 15. Plot range and velocity errors
% ------------------------------------------------------------

Figure3 = figure('Name', ...
    'Range and Velocity Errors', ...
    'Color', 'w');

subplot(2,1,1);

bar(TargetNumber, RangeError);

grid on;

xlabel('Target Number');
ylabel('Range Error (m)');

title('Range Estimation Error');

subplot(2,1,2);

bar(TargetNumber, VelocityError);

grid on;

xlabel('Target Number');
ylabel('Velocity Error (m/s)');

title('Velocity Estimation Error');

set(findall(Figure3, 'Type', 'axes'), ...
    'Toolbar', []);

exportgraphics(Figure3, ...
    fullfile(OutputFolder, ...
    'Range_Velocity_Errors.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 16. Plot CFAR detection map
% ------------------------------------------------------------

Figure4 = figure('Name', ...
    'CA-CFAR Detection Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARDetection);

axis xy;
xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('CA-CFAR Binary Detection Map');

colorbar;
colormap(gray);

set(gca, 'Toolbar', []);

exportgraphics(Figure4, ...
    fullfile(OutputFolder, ...
    'CFAR_Detection_Map.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 17. Save numerical evaluation results
% ------------------------------------------------------------

CFARPerformance.Pd = Pd;
CFARPerformance.Pfa = Pfa;

CFARPerformance.TotalExpectedTargets = NumberOfTargets;
CFARPerformance.DetectedTargetCount = DetectedTargetCount;
CFARPerformance.TotalCells = TotalCells;
CFARPerformance.DetectedCells = DetectedCells;
CFARPerformance.FalseAlarmCount = FalseAlarmCount;

CFARPerformance.MeanRangeError_m = MeanRangeError;
CFARPerformance.RangeRMSE_m = RMSE_Range;

CFARPerformance.MeanVelocityError_mps = ...
    MeanVelocityError;

CFARPerformance.VelocityRMSE_mps = ...
    RMSE_Velocity;

CFARPerformance.PerformanceTable = PerformanceTable;

save(fullfile(OutputFolder, ...
    'CFAR_Performance_Evaluation.mat'), ...
    'CFARPerformance');

writetable(PerformanceTable, ...
    fullfile(OutputFolder, ...
    'CFAR_Performance_Table.csv'));

%% ------------------------------------------------------------
% 18. Completion message
% ------------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('CFAR PERFORMANCE EVALUATION COMPLETED\n');
fprintf('============================================================\n');

fprintf('Output folder:\n%s\n', OutputFolder);

fprintf('\nGenerated files:\n');
fprintf('1. Expected_vs_Detected_Range.png\n');
fprintf('2. Expected_vs_Detected_Velocity.png\n');
fprintf('3. Range_Velocity_Errors.png\n');
fprintf('4. CFAR_Detection_Map.png\n');
fprintf('5. CFAR_Performance_Evaluation.mat\n');
fprintf('6. CFAR_Performance_Table.csv\n');

fprintf('\n');