%% ============================================================
%  SARRS STUDIO
%  FINAL RADAR + CA-CFAR DEMONSTRATION
%
%  Purpose:
%  Final simulation and result presentation for the project
%
%  Project:
%  Self-Adaptive Reconfigurable Radar Receiver System
% =============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf(' SARRS STUDIO - FINAL RADAR DEMONSTRATION\n');
fprintf('============================================================\n');

%% ------------------------------------------------------------
% 1. Folder configuration
% ------------------------------------------------------------

ResultsFolder = ...
    'D:\SARRS_STUDIO\04_MATLAB\DSP\SARRS_Results';

FinalOutputFolder = fullfile(ResultsFolder, ...
    'FINAL_DEMONSTRATION');

if ~exist(FinalOutputFolder, 'dir')
    mkdir(FinalOutputFolder);
end

%% ------------------------------------------------------------
% 2. Find latest radar result
% ------------------------------------------------------------

RadarFiles = dir(fullfile(ResultsFolder, ...
    'FiveTargetRadar_Result_*.mat'));

if isempty(RadarFiles)
    error('No radar result file was found.');
end

[~, RadarIndex] = max([RadarFiles.datenum]);

LatestRadarFile = fullfile( ...
    ResultsFolder, ...
    RadarFiles(RadarIndex).name);

%% ------------------------------------------------------------
% 3. Find latest CFAR result
% ------------------------------------------------------------

CFARFiles = dir(fullfile(ResultsFolder, ...
    'CFAR_FiveTarget_Result_*.mat'));

if isempty(CFARFiles)
    error('No CFAR result file was found.');
end

[~, CFARIndex] = max([CFARFiles.datenum]);

LatestCFARFile = fullfile( ...
    ResultsFolder, ...
    CFARFiles(CFARIndex).name);

fprintf('\nLatest radar result:\n%s\n', ...
    LatestRadarFile);

fprintf('\nLatest CFAR result:\n%s\n', ...
    LatestCFARFile);

%% ------------------------------------------------------------
% 4. Load files
% ------------------------------------------------------------

RadarData = load(LatestRadarFile);
CFARData = load(LatestCFARFile);

if ~isfield(CFARData, 'CFARResult')
    error('CFARResult structure was not found.');
end

CFARResult = CFARData.CFARResult;

fprintf('\nRadar and CFAR files loaded successfully.\n');

%% ------------------------------------------------------------
% 5. Extract radar data
% ------------------------------------------------------------

DopplerMap_dB = RadarData.DopplerMap_dB;
RangeAxis     = RadarData.RangeAxis;
VelocityAxis  = RadarData.VelocityAxis;

ExpectedRange = RadarData.TargetRanges;
ExpectedVelocity = RadarData.TargetVelocities;

%% ------------------------------------------------------------
% 6. Extract CFAR data
% ------------------------------------------------------------

CFARDetection = CFARResult.CFARDetection;

DetectedRange = CFARResult.DetectedRange;
DetectedVelocity = CFARResult.DetectedVelocity;
DetectedPower_dB = CFARResult.DetectedPower_dB;

%% ------------------------------------------------------------
% 7. Display dimension check
% ------------------------------------------------------------

fprintf('\n');
fprintf('DATA DIMENSION CHECK\n');
fprintf('------------------------------------------------------------\n');

fprintf('Doppler map       : %d x %d\n', ...
    size(DopplerMap_dB, 1), ...
    size(DopplerMap_dB, 2));

fprintf('CFAR detection    : %d x %d\n', ...
    size(CFARDetection, 1), ...
    size(CFARDetection, 2));

fprintf('Range axis        : %d elements\n', ...
    length(RangeAxis));

fprintf('Velocity axis     : %d elements\n', ...
    length(VelocityAxis));

%% ------------------------------------------------------------
% 8. Display target results
% ------------------------------------------------------------

fprintf('\n');
fprintf('FINAL TARGET DETECTION RESULTS\n');
fprintf('------------------------------------------------------------\n');

fprintf('%8s %18s %22s %18s\n', ...
    'Target', ...
    'Range (m)', ...
    'Velocity (m/s)', ...
    'Power (dB)');

fprintf('%8s %18s %22s %18s\n', ...
    '------', ...
    '--------', ...
    '--------------', ...
    '---------');

NumberOfDetections = length(DetectedRange);

for k = 1:NumberOfDetections

    fprintf('%8d %18.2f %22.2f %18.2f\n', ...
        k, ...
        DetectedRange(k), ...
        DetectedVelocity(k), ...
        DetectedPower_dB(k));

end

%% ------------------------------------------------------------
% 9. Calculate detection probability
% ------------------------------------------------------------

NumberOfExpectedTargets = length(ExpectedRange);

DetectedTargetCount = length(DetectedRange);

DetectionProbability = ...
    DetectedTargetCount / NumberOfExpectedTargets;

fprintf('\n');
fprintf('Detection probability: %.2f %%\n', ...
    DetectionProbability * 100);

%% ------------------------------------------------------------
% 10. Create final target table
% ------------------------------------------------------------

TargetNumber = (1:DetectedTargetCount).';

FinalTargetTable = table( ...
    TargetNumber, ...
    DetectedRange(:), ...
    DetectedVelocity(:), ...
    DetectedPower_dB(:), ...
    'VariableNames', { ...
    'Target', ...
    'Range_m', ...
    'Velocity_mps', ...
    'Power_dB'});

disp(FinalTargetTable);

%% ------------------------------------------------------------
% 11. Create final presentation figure
% ------------------------------------------------------------

FinalFigure = figure( ...
    'Name', ...
    'SARRS Final Radar Demonstration', ...
    'Color', 'w', ...
    'Position', [100 100 1400 700]);

%% ------------------------------------------------------------
% 12. Range-Doppler map
% ------------------------------------------------------------

subplot(1,2,1);

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('Simulated Range-Doppler Map');

hold on;

plot(ExpectedRange, ExpectedVelocity, ...
    'wo', ...
    'LineWidth', 2, ...
    'MarkerSize', 10);

for k = 1:length(ExpectedRange)

    text(ExpectedRange(k), ...
         ExpectedVelocity(k), ...
         sprintf('  T%d', k), ...
         'Color', 'w', ...
         'FontWeight', 'bold', ...
         'FontSize', 10);

end

legend('Expected Targets', ...
    'Location', 'best');

%% ------------------------------------------------------------
% 13. CFAR detection map
% ------------------------------------------------------------

subplot(1,2,2);

imagesc(RangeAxis, VelocityAxis, CFARDetection);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('CA-CFAR Detection Map');

hold on;

plot(DetectedRange, DetectedVelocity, ...
    'r+', ...
    'LineWidth', 2, ...
    'MarkerSize', 12);

for k = 1:length(DetectedRange)

    text(DetectedRange(k), ...
         DetectedVelocity(k), ...
         sprintf('  D%d', k), ...
         'Color', 'r', ...
         'FontWeight', 'bold', ...
         'FontSize', 10);

end

legend('Detected Targets', ...
    'Location', 'best');

%% ------------------------------------------------------------
% 14. Save final figure
% ------------------------------------------------------------

set(findall(FinalFigure, 'Type', 'axes'), ...
    'Toolbar', []);

FinalFigurePath = fullfile( ...
    FinalOutputFolder, ...
    'SARRS_Final_Radar_CA_CFAR_Result.png');

exportgraphics(FinalFigure, ...
    FinalFigurePath, ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 15. Save final numerical results
% ------------------------------------------------------------

FinalSummary.DetectedRange = DetectedRange;
FinalSummary.DetectedVelocity = DetectedVelocity;
FinalSummary.DetectedPower_dB = DetectedPower_dB;

FinalSummary.ExpectedRange = ExpectedRange;
FinalSummary.ExpectedVelocity = ExpectedVelocity;

FinalSummary.DetectionProbability = ...
    DetectionProbability;

FinalSummary.TargetTable = FinalTargetTable;

FinalSummary.RadarFile = LatestRadarFile;
FinalSummary.CFARFile = LatestCFARFile;

save(fullfile(FinalOutputFolder, ...
    'SARRS_Final_Summary.mat'), ...
    'FinalSummary');

%% ------------------------------------------------------------
% 16. Save CSV table
% ------------------------------------------------------------

writetable(FinalTargetTable, ...
    fullfile(FinalOutputFolder, ...
    'SARRS_Final_Target_Table.csv'));

%% ------------------------------------------------------------
% 17. Completion message
% ------------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf(' FINAL SARRS DEMONSTRATION COMPLETED SUCCESSFULLY\n');
fprintf('============================================================\n');

fprintf('\nFinal output folder:\n%s\n', ...
    FinalOutputFolder);

fprintf('\nGenerated files:\n');
fprintf('1. SARRS_Final_Radar_CA_CFAR_Result.png\n');
fprintf('2. SARRS_Final_Summary.mat\n');
fprintf('3. SARRS_Final_Target_Table.csv\n');

fprintf('\n');