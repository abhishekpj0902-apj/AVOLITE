%% ============================================================
%  SARRS STUDIO - CA-CFAR THRESHOLD ANALYSIS
% =============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf(' SARRS STUDIO - CA-CFAR THRESHOLD ANALYSIS\n');
fprintf('============================================================\n');

%% ------------------------------------------------------------
% 1. Folder configuration
% ------------------------------------------------------------

ResultsFolder = ...
    'D:\SARRS_STUDIO\04_MATLAB\DSP\SARRS_Results';

OutputFolder = fullfile(ResultsFolder, ...
    'CFAR_Threshold_Analysis');

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

[~, RadarIndex] = max([RadarFiles.datenum]);

RadarFile = fullfile( ...
    ResultsFolder, ...
    RadarFiles(RadarIndex).name);

RadarData = load(RadarFile);

%% ------------------------------------------------------------
% 3. Load latest CFAR result
% ------------------------------------------------------------

CFARFiles = dir(fullfile(ResultsFolder, ...
    'CFAR_FiveTarget_Result_*.mat'));

if isempty(CFARFiles)
    error('CFAR result file was not found.');
end

[~, CFARIndex] = max([CFARFiles.datenum]);

CFARFile = fullfile( ...
    ResultsFolder, ...
    CFARFiles(CFARIndex).name);

CFARData = load(CFARFile);

if ~isfield(CFARData, 'CFARResult')
    error('CFARResult structure was not found.');
end

CFARResult = CFARData.CFARResult;

%% ------------------------------------------------------------
% 4. Extract data
% ------------------------------------------------------------

DopplerMap_dB = RadarData.DopplerMap_dB;
RangeAxis     = RadarData.RangeAxis;
VelocityAxis  = RadarData.VelocityAxis;

CFARDetection = CFARResult.CFARDetection;

DetectedRange = CFARResult.DetectedRange;
DetectedVelocity = CFARResult.DetectedVelocity;
DetectedPower_dB = CFARResult.DetectedPower_dB;

%% ------------------------------------------------------------
% 5. Check threshold field
% ------------------------------------------------------------

if ~isfield(CFARResult, 'CFARThreshold')

    error(['CFARThreshold was not found in CFARResult. ', ...
           'Modify the CFAR script to save the threshold matrix.']);

end

CFARThreshold = CFARResult.CFARThreshold;

fprintf('\nData loaded successfully.\n');

fprintf('Doppler map size    : %d x %d\n', ...
    size(DopplerMap_dB, 1), ...
    size(DopplerMap_dB, 2));

fprintf('Threshold size      : %d x %d\n', ...
    size(CFARThreshold, 1), ...
    size(CFARThreshold, 2));

%% ------------------------------------------------------------
% 6. Convert threshold to dB if necessary
% ------------------------------------------------------------

% CFAR threshold is normally stored in linear power units.
% Convert it to dB for comparison with DopplerMap_dB.

if max(CFARThreshold(:)) > 0

    CFARThreshold_dB = ...
        10 .* log10(abs(CFARThreshold) + eps);

else

    CFARThreshold_dB = CFARThreshold;

end

%% ------------------------------------------------------------
% 7. Plot original Doppler map
% ------------------------------------------------------------

Figure1 = figure( ...
    'Name', 'Original Range-Doppler Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('Original Range-Doppler Map');

set(gca, 'Toolbar', []);

exportgraphics(Figure1, ...
    fullfile(OutputFolder, ...
    '01_Original_Range_Doppler_Map.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 8. Plot CFAR threshold map
% ------------------------------------------------------------

Figure2 = figure( ...
    'Name', 'CA-CFAR Threshold Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARThreshold_dB);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('CA-CFAR Adaptive Threshold Map');

set(gca, 'Toolbar', []);

exportgraphics(Figure2, ...
    fullfile(OutputFolder, ...
    '02_CFAR_Threshold_Map.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 9. Plot binary CFAR detection map
% ------------------------------------------------------------

Figure3 = figure( ...
    'Name', 'CA-CFAR Detection Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARDetection);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('CA-CFAR Binary Detection Map');

set(gca, 'Toolbar', []);

exportgraphics(Figure3, ...
    fullfile(OutputFolder, ...
    '03_CFAR_Detection_Map.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 10. Plot all three maps together
% ------------------------------------------------------------

Figure4 = figure( ...
    'Name', 'CA-CFAR Complete Analysis', ...
    'Color', 'w', ...
    'Position', [100 100 1500 500]);

subplot(1,3,1);

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('Range-Doppler Map');

subplot(1,3,2);

imagesc(RangeAxis, VelocityAxis, CFARThreshold_dB);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('Adaptive CFAR Threshold');

subplot(1,3,3);

imagesc(RangeAxis, VelocityAxis, CFARDetection);

axis xy;
colorbar;

xlabel('Range (m)');
ylabel('Velocity (m/s)');

title('CFAR Detection Output');

set(findall(Figure4, 'Type', 'axes'), ...
    'Toolbar', []);

exportgraphics(Figure4, ...
    fullfile(OutputFolder, ...
    '04_CFAR_Complete_Analysis.png'), ...
    'Resolution', 300);

%% ------------------------------------------------------------
% 11. Display detected target information
% ------------------------------------------------------------

fprintf('\n');
fprintf('DETECTED TARGET INFORMATION\n');
fprintf('------------------------------------------------------------\n');

fprintf('%8s %18s %20s %18s\n', ...
    'Target', ...
    'Range (m)', ...
    'Velocity (m/s)', ...
    'Power (dB)');

for k = 1:length(DetectedRange)

    fprintf('%8d %18.2f %20.2f %18.2f\n', ...
        k, ...
        DetectedRange(k), ...
        DetectedVelocity(k), ...
        DetectedPower_dB(k));

end

%% ------------------------------------------------------------
% 12. Save threshold analysis data
% ------------------------------------------------------------

ThresholdAnalysis.DopplerMap_dB = DopplerMap_dB;
ThresholdAnalysis.CFARThreshold = CFARThreshold;
ThresholdAnalysis.CFARThreshold_dB = CFARThreshold_dB;
ThresholdAnalysis.CFARDetection = CFARDetection;

ThresholdAnalysis.DetectedRange = DetectedRange;
ThresholdAnalysis.DetectedVelocity = DetectedVelocity;
ThresholdAnalysis.DetectedPower_dB = DetectedPower_dB;

ThresholdAnalysis.RangeAxis = RangeAxis;
ThresholdAnalysis.VelocityAxis = VelocityAxis;

save(fullfile(OutputFolder, ...
    'CFAR_Threshold_Analysis.mat'), ...
    'ThresholdAnalysis');

%% ------------------------------------------------------------
% 13. Completion message
% ------------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf(' CFAR THRESHOLD ANALYSIS COMPLETED SUCCESSFULLY\n');
fprintf('============================================================\n');

fprintf('\nOutput folder:\n%s\n', OutputFolder);

fprintf('\nGenerated files:\n');
fprintf('1. 01_Original_Range_Doppler_Map.png\n');
fprintf('2. 02_CFAR_Threshold_Map.png\n');
fprintf('3. 03_CFAR_Detection_Map.png\n');
fprintf('4. 04_CFAR_Complete_Analysis.png\n');
fprintf('5. CFAR_Threshold_Analysis.mat\n');

fprintf('\n');