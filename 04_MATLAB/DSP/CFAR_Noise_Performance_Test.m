%% ============================================================
%  SARRS STUDIO - VISUALIZE 2D CA-CFAR RESULTS
%  Project: Self-Adaptive Reconfigurable Radar Receiver
% =============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - VISUALIZE CA-CFAR RESULTS\n');
fprintf('============================================================\n');

%% ------------------------------------------------------------
% 1. FOLDER CONFIGURATION
% ------------------------------------------------------------

ResultsFolder = fullfile( ...
    'D:\SARRS_STUDIO\04_MATLAB\DSP\SARRS_Results');

if ~isfolder(ResultsFolder)
    error('Results folder not found:\n%s', ResultsFolder);
end

%% ------------------------------------------------------------
% 2. FIND LATEST CFAR RESULT FILE
% ------------------------------------------------------------

Files = dir(fullfile(ResultsFolder, ...
    'CFAR_FiveTarget_Result_*.mat'));

if isempty(Files)
    error('No CFAR result MAT file found.');
end

[~, Index] = max([Files.datenum]);
LatestFile = fullfile(ResultsFolder, Files(Index).name);

fprintf('\nLatest CFAR result:\n%s\n', LatestFile);

FileInfo = dir(LatestFile);

fprintf('File size: %.2f KB\n', FileInfo.bytes / 1024);

if FileInfo.bytes == 0
    error('The CFAR MAT file is empty.');
end

%% ------------------------------------------------------------
% 3. LOAD CFAR RESULT
% ------------------------------------------------------------

LoadedData = load(LatestFile);

fprintf('\nMAT file loaded successfully.\n');

VariableNames = fieldnames(LoadedData);

fprintf('Variables found in CFAR result:\n');

for k = 1:numel(VariableNames)
    CurrentVariable = LoadedData.(VariableNames{k});

    fprintf('%-30s Size: ', VariableNames{k});
    fprintf('%d ', size(CurrentVariable));
    fprintf('\n');
end

%% ------------------------------------------------------------
% 4. READ RADAR RESULT STRUCTURE
% ------------------------------------------------------------

if isfield(LoadedData, 'RadarResult')

    RadarResult = LoadedData.RadarResult;

else

    error(['RadarResult structure was not found. ', ...
           'Check the saved CFAR MAT file.']);

end

%% ------------------------------------------------------------
% 5. READ RANGE-DOPPLER DATA
% ------------------------------------------------------------

if isfield(RadarResult, 'DopplerMap_dB')
    DopplerMap_dB = RadarResult.DopplerMap_dB;

elseif isfield(RadarResult, 'DopplerMap')
    DopplerMap = RadarResult.DopplerMap;

    DopplerMap_dB = ...
        20 * log10(abs(DopplerMap) ./ ...
        max(abs(DopplerMap(:))) + eps);

else

    error('Doppler map was not found in RadarResult.');

end

if isfield(RadarResult, 'RangeAxis')
    RangeAxis = RadarResult.RangeAxis;
else
    error('RangeAxis was not found in RadarResult.');
end

if isfield(RadarResult, 'VelocityAxis')
    VelocityAxis = RadarResult.VelocityAxis;
else
    error('VelocityAxis was not found in RadarResult.');
end

%% ------------------------------------------------------------
% 6. READ CFAR DETECTION DATA
% ------------------------------------------------------------

% Detection matrix
if isfield(LoadedData, 'CFARDetectionMap')

    CFARDetectionMap = LoadedData.CFARDetectionMap;

elseif isfield(LoadedData, 'DetectionMap')

    CFARDetectionMap = LoadedData.DetectionMap;

elseif isfield(LoadedData, 'CFARMask')

    CFARDetectionMap = LoadedData.CFARMask;

else

    warning(['CFAR detection matrix was not found. ', ...
             'A detection matrix will be reconstructed.']);

    CFARDetectionMap = false(size(DopplerMap_dB));

end

% Threshold map
if isfield(LoadedData, 'CFARThreshold_dB')

    CFARThreshold_dB = LoadedData.CFARThreshold_dB;

elseif isfield(LoadedData, 'ThresholdMap_dB')

    CFARThreshold_dB = LoadedData.ThresholdMap_dB;

elseif isfield(LoadedData, 'CFARThreshold')

    CFARThreshold_dB = LoadedData.CFARThreshold;

else

    CFARThreshold_dB = nan(size(DopplerMap_dB));

end

%% ------------------------------------------------------------
% 7. READ DETECTED TARGET INFORMATION
% ------------------------------------------------------------

DetectedRanges = [];
DetectedVelocities = [];
DetectedPowers = [];

if isfield(LoadedData, 'DetectedRanges')
    DetectedRanges = LoadedData.DetectedRanges;
end

if isfield(LoadedData, 'DetectedVelocities')
    DetectedVelocities = LoadedData.DetectedVelocities;
end

if isfield(LoadedData, 'DetectedPowers')
    DetectedPowers = LoadedData.DetectedPowers;
end

% Alternative variable names
if isempty(DetectedRanges) && ...
        isfield(LoadedData, 'TargetDetectedRanges')

    DetectedRanges = LoadedData.TargetDetectedRanges;

end

if isempty(DetectedVelocities) && ...
        isfield(LoadedData, 'TargetDetectedVelocities')

    DetectedVelocities = LoadedData.TargetDetectedVelocities;

end

if isempty(DetectedPowers) && ...
        isfield(LoadedData, 'TargetDetectedPowers')

    DetectedPowers = LoadedData.TargetDetectedPowers;

end

%% ------------------------------------------------------------
% 8. DETECTION MAP DIMENSION CHECK
% ------------------------------------------------------------

if ~isequal(size(CFARDetectionMap), size(DopplerMap_dB))

    warning(['CFAR detection map size does not match ', ...
             'Range-Doppler map size.']);

    CFARDetectionMap = false(size(DopplerMap_dB));

end

%% ------------------------------------------------------------
% 9. FIGURE 1 - ORIGINAL RANGE-DOPPLER MAP
% ------------------------------------------------------------

figure('Name', ...
    'Original Range-Doppler Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('Original Five-Target Range-Doppler Map', ...
    'FontSize', 14, 'FontWeight', 'bold');

colorbar;
colormap turbo;
caxis([-40 0]);

grid on;

%% ------------------------------------------------------------
% 10. FIGURE 2 - CFAR DETECTION MAP
% ------------------------------------------------------------

figure('Name', ...
    'CFAR Detection Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARDetectionMap);

axis xy;
xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('2D CA-CFAR Binary Detection Map', ...
    'FontSize', 14, 'FontWeight', 'bold');

colorbar;
colormap gray;

grid on;

%% ------------------------------------------------------------
% 11. FIGURE 3 - DETECTIONS OVER RANGE-DOPPLER MAP
% ------------------------------------------------------------

figure('Name', ...
    'CFAR Target Detections', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('CA-CFAR Target Detection Results', ...
    'FontSize', 14, 'FontWeight', 'bold');

colorbar;
colormap turbo;
caxis([-40 0]);

hold on;

if ~isempty(DetectedRanges) && ...
        ~isempty(DetectedVelocities)

    PlotCount = min(numel(DetectedRanges), ...
                    numel(DetectedVelocities));

    for k = 1:PlotCount

        plot(DetectedRanges(k), ...
             DetectedVelocities(k), ...
             'wo', ...
             'MarkerSize', 10, ...
             'LineWidth', 2);

        text(DetectedRanges(k) + 1.5, ...
             DetectedVelocities(k), ...
             sprintf('T%d', k), ...
             'Color', 'w', ...
             'FontSize', 12, ...
             'FontWeight', 'bold');

    end

else

    warning(['Detected range and velocity arrays were not ', ...
             'found. Only the original map is displayed.']);

end

grid on;
hold off;

%% ------------------------------------------------------------
% 12. FIGURE 4 - CFAR THRESHOLD MAP
% ------------------------------------------------------------

if any(isfinite(CFARThreshold_dB(:)))

    figure('Name', ...
        'CFAR Threshold Map', ...
        'Color', 'w');

    imagesc(RangeAxis, VelocityAxis, CFARThreshold_dB);

    axis xy;
    xlabel('Range (m)', 'FontSize', 12);
    ylabel('Velocity (m/s)', 'FontSize', 12);

    title('2D CA-CFAR Threshold Map', ...
        'FontSize', 14, 'FontWeight', 'bold');

    colorbar;
    colormap turbo;
    grid on;

end

%% ------------------------------------------------------------
% 13. PRINT DETECTION RESULTS
% ------------------------------------------------------------

fprintf('\n');
fprintf('CFAR VISUALIZATION RESULTS\n');
fprintf('------------------------------------------------------------\n');

if ~isempty(DetectedRanges) && ...
        ~isempty(DetectedVelocities)

    NumberOfTargets = min(numel(DetectedRanges), ...
                          numel(DetectedVelocities));

    fprintf('Number of detected targets: %d\n\n', ...
        NumberOfTargets);

    fprintf('%8s %20s %24s\n', ...
        'Target', ...
        'Detected Range (m)', ...
        'Detected Velocity (m/s)');

    fprintf('%8s %20s %24s\n', ...
        '------', ...
        '------------------', ...
        '-----------------------');

    for k = 1:NumberOfTargets

        fprintf('%8d %20.2f %24.2f\n', ...
            k, ...
            DetectedRanges(k), ...
            DetectedVelocities(k));

    end

else

    fprintf('Detected target arrays are not available.\n');

end

%% ------------------------------------------------------------
% 14. SAVE VISUALIZATION FIGURES
% ------------------------------------------------------------

VisualizationFolder = fullfile(ResultsFolder, ...
    'CFAR_Visualization');

if ~isfolder(VisualizationFolder)
    mkdir(VisualizationFolder);
end

TimeStamp = datestr(now, 'yyyymmdd_HHMMSS');

saveas(1, fullfile(VisualizationFolder, ...
    ['Original_RangeDoppler_' TimeStamp '.png']));

saveas(2, fullfile(VisualizationFolder, ...
    ['CFAR_DetectionMap_' TimeStamp '.png']));

saveas(3, fullfile(VisualizationFolder, ...
    ['CFAR_Detections_' TimeStamp '.png']));

if any(isfinite(CFARThreshold_dB(:)))

    saveas(4, fullfile(VisualizationFolder, ...
        ['CFAR_ThresholdMap_' TimeStamp '.png']));

end

fprintf('\n');
fprintf('CFAR visualization figures saved successfully.\n');
fprintf('Folder:\n%s\n', VisualizationFolder);

fprintf('\n');
fprintf('============================================================\n');
fprintf('CFAR VISUALIZATION COMPLETED\n');
fprintf('============================================================\n');