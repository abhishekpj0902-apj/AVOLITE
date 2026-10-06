%% ============================================================
%  SARRS STUDIO - VISUALIZE CA-CFAR RESULTS
%  File: Visualize_CFAR_FiveTargetRadar.m
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
% 2. FIND LATEST RADAR RESULT FILE
% ------------------------------------------------------------

RadarFiles = dir(fullfile( ...
    ResultsFolder, ...
    'FiveTargetRadar_Result_*.mat'));

if isempty(RadarFiles)
    error('No original radar result file found.');
end

[~, RadarIndex] = max([RadarFiles.datenum]);

LatestRadarFile = fullfile( ...
    ResultsFolder, ...
    RadarFiles(RadarIndex).name);

fprintf('\nLatest radar result:\n%s\n', ...
    LatestRadarFile);

RadarFileInfo = dir(LatestRadarFile);

fprintf('Radar file size: %.2f KB\n', ...
    RadarFileInfo.bytes / 1024);

%% ------------------------------------------------------------
% 3. FIND LATEST CFAR RESULT FILE
% ------------------------------------------------------------

CFARFiles = dir(fullfile( ...
    ResultsFolder, ...
    'CFAR_FiveTarget_Result_*.mat'));

if isempty(CFARFiles)
    error('No CFAR result file found. Run CFAR_FiveTargetRadar.m first.');
end

[~, CFARIndex] = max([CFARFiles.datenum]);

LatestCFARFile = fullfile( ...
    ResultsFolder, ...
    CFARFiles(CFARIndex).name);

fprintf('\nLatest CFAR result:\n%s\n', ...
    LatestCFARFile);

CFARFileInfo = dir(LatestCFARFile);

fprintf('CFAR file size: %.2f KB\n', ...
    CFARFileInfo.bytes / 1024);

%% ------------------------------------------------------------
% 4. LOAD ORIGINAL RADAR DATA
% ------------------------------------------------------------

RadarData = load(LatestRadarFile);

fprintf('\nOriginal radar MAT file loaded successfully.\n');

%% Read original radar variables

if isfield(RadarData, 'DopplerMap_dB')

    DopplerMap_dB = double(RadarData.DopplerMap_dB);

elseif isfield(RadarData, 'DopplerMap')

    DopplerMap = double(RadarData.DopplerMap);

    DopplerMap_dB = 20 * log10( ...
        abs(DopplerMap) ./ ...
        (max(abs(DopplerMap(:))) + eps));

else

    error('DopplerMap_dB or DopplerMap not found.');

end

if isfield(RadarData, 'RangeAxis')

    RangeAxis = double(RadarData.RangeAxis);

else

    error('RangeAxis not found in original radar file.');

end

if isfield(RadarData, 'VelocityAxis')

    VelocityAxis = double(RadarData.VelocityAxis);

else

    error('VelocityAxis not found in original radar file.');

end

if isfield(RadarData, 'TargetRanges')

    ExpectedRanges = double(RadarData.TargetRanges);

else

    ExpectedRanges = [];

end

if isfield(RadarData, 'TargetVelocities')

    ExpectedVelocities = double(RadarData.TargetVelocities);

else

    ExpectedVelocities = [];

end

%% Correct axis orientation

RangeAxis = RangeAxis(:).';
VelocityAxis = VelocityAxis(:);

%% ------------------------------------------------------------
% 5. LOAD CFAR DATA
% ------------------------------------------------------------

CFARData = load(LatestCFARFile);

fprintf('CFAR MAT file loaded successfully.\n');

if ~isfield(CFARData, 'CFARResult')

    error('CFARResult structure not found in CFAR MAT file.');

end

CFARResult = CFARData.CFARResult;

fprintf('CFARResult structure found.\n');

%% ------------------------------------------------------------
% 6. READ CFAR DETECTION INFORMATION
% ------------------------------------------------------------

if isfield(CFARResult, 'DetectedRange')

    DetectedRanges = double(CFARResult.DetectedRange);

else

    DetectedRanges = [];

end

if isfield(CFARResult, 'DetectedVelocity')

    DetectedVelocities = double(CFARResult.DetectedVelocity);

else

    DetectedVelocities = [];

end

if isfield(CFARResult, 'DetectedPower_dB')

    DetectedPowers = double(CFARResult.DetectedPower_dB);

else

    DetectedPowers = [];

end

%% ------------------------------------------------------------
% 7. READ CFAR DETECTION MATRIX
% ------------------------------------------------------------

if isfield(CFARResult, 'CFARDetection')

    CFARDetection = logical(CFARResult.CFARDetection);

else

    warning('CFARDetection matrix was not found.');

    CFARDetection = false(size(DopplerMap_dB));

end

%% ------------------------------------------------------------
% 8. READ CFAR THRESHOLD
% ------------------------------------------------------------

if isfield(CFARResult, 'CFARThreshold')

    CFARThreshold = double(CFARResult.CFARThreshold);

    CFARThreshold_dB = 10 * log10(CFARThreshold + eps);

else

    CFARThreshold_dB = nan(size(DopplerMap_dB));

end

%% ------------------------------------------------------------
% 9. DIMENSION CHECK
% ------------------------------------------------------------

fprintf('\nDATA DIMENSION CHECK\n');
fprintf('------------------------------------------------------------\n');

fprintf('Doppler map       : %d x %d\n', ...
    size(DopplerMap_dB, 1), ...
    size(DopplerMap_dB, 2));

fprintf('CFAR detection    : %d x %d\n', ...
    size(CFARDetection, 1), ...
    size(CFARDetection, 2));

fprintf('Range axis        : %d elements\n', ...
    numel(RangeAxis));

fprintf('Velocity axis     : %d elements\n', ...
    numel(VelocityAxis));

%% If dimensions do not match, stop safely

if ~isequal(size(CFARDetection), size(DopplerMap_dB))

    error(['CFAR detection matrix and Doppler map dimensions ', ...
           'do not match.']);

end

%% ------------------------------------------------------------
% 10. FIGURE 1 - ORIGINAL RANGE-DOPPLER MAP
% ------------------------------------------------------------

figure( ...
    'Name', 'Original Range-Doppler Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('Original Five-Target Range-Doppler Map', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

colormap turbo;
colorbar;
caxis([-40 0]);
grid on;

hold on;

if ~isempty(ExpectedRanges) && ...
        ~isempty(ExpectedVelocities)

    plot(ExpectedRanges, ...
         ExpectedVelocities, ...
         'wo', ...
         'MarkerSize', 10, ...
         'LineWidth', 2);

    for k = 1:min(numel(ExpectedRanges), ...
                 numel(ExpectedVelocities))

        text(ExpectedRanges(k) + 1.5, ...
             ExpectedVelocities(k), ...
             sprintf('Expected T%d', k), ...
             'Color', 'w', ...
             'FontWeight', 'bold');

    end

end

hold off;

%% ------------------------------------------------------------
% 11. FIGURE 2 - BINARY CFAR DETECTION MAP
% ------------------------------------------------------------

figure( ...
    'Name', 'Binary CFAR Detection Map', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, CFARDetection);

axis xy;
xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('2D CA-CFAR Binary Detection Map', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

colormap gray;
colorbar;
grid on;

%% ------------------------------------------------------------
% 12. FIGURE 3 - CFAR DETECTIONS ON RADAR MAP
% ------------------------------------------------------------

figure( ...
    'Name', 'CFAR Target Detection Results', ...
    'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('CA-CFAR Target Detection Results', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

colormap turbo;
colorbar;
caxis([-40 0]);
grid on;

hold on;

if ~isempty(DetectedRanges) && ...
        ~isempty(DetectedVelocities)

    NumberOfDetections = min( ...
        numel(DetectedRanges), ...
        numel(DetectedVelocities));

    plot(DetectedRanges(1:NumberOfDetections), ...
         DetectedVelocities(1:NumberOfDetections), ...
         'wo', ...
         'MarkerSize', 11, ...
         'LineWidth', 2);

    for k = 1:NumberOfDetections

        text(DetectedRanges(k) + 1.5, ...
             DetectedVelocities(k), ...
             sprintf('D%d', k), ...
             'Color', 'w', ...
             'FontSize', 12, ...
             'FontWeight', 'bold');

    end

end

hold off;

%% ------------------------------------------------------------
% 13. FIGURE 4 - CFAR THRESHOLD MAP
% ------------------------------------------------------------

if any(isfinite(CFARThreshold_dB(:)))

    figure( ...
        'Name', 'CFAR Threshold Map', ...
        'Color', 'w');

    imagesc(RangeAxis, VelocityAxis, CFARThreshold_dB);

    axis xy;
    xlabel('Range (m)', 'FontSize', 12);
    ylabel('Velocity (m/s)', 'FontSize', 12);

    title('2D CA-CFAR Threshold Map', ...
        'FontSize', 14, ...
        'FontWeight', 'bold');

    colormap turbo;
    colorbar;
    grid on;

end

%% ------------------------------------------------------------
% 14. PRINT DETECTION TABLE
% ------------------------------------------------------------

fprintf('\n');
fprintf('CFAR DETECTION RESULTS\n');
fprintf('------------------------------------------------------------\n');

fprintf('%8s %20s %25s %15s\n', ...
    'Target', ...
    'Range (m)', ...
    'Velocity (m/s)', ...
    'Power (dB)');

fprintf('%8s %20s %25s %15s\n', ...
    '------', ...
    '--------', ...
    '--------------', ...
    '---------');

NumberOfDetections = min( ...
    [numel(DetectedRanges), ...
     numel(DetectedVelocities)]);

for k = 1:NumberOfDetections

    if k <= numel(DetectedPowers)

        CurrentPower = DetectedPowers(k);

    else

        CurrentPower = NaN;

    end

    fprintf('%8d %20.2f %25.2f %15.2f\n', ...
        k, ...
        DetectedRanges(k), ...
        DetectedVelocities(k), ...
        CurrentPower);

end

%% ------------------------------------------------------------
% 15. SAVE FIGURES
% ------------------------------------------------------------

VisualizationFolder = fullfile( ...
    ResultsFolder, ...
    'CFAR_Visualization');

if ~isfolder(VisualizationFolder)
    mkdir(VisualizationFolder);
end

TimeStamp = datestr(now, 'yyyymmdd_HHMMSS');

FigureHandles = findall(0, 'Type', 'figure');

for k = 1:numel(FigureHandles)

    FigureName = get(FigureHandles(k), 'Name');

    if isempty(FigureName)

        FigureName = sprintf('CFAR_Figure_%d', k);

    end

    FigureName = regexprep( ...
        FigureName, ...
        '[^a-zA-Z0-9_]', ...
        '_');

    OutputFile = fullfile( ...
        VisualizationFolder, ...
        [FigureName '_' TimeStamp '.png']);

    saveas(FigureHandles(k), OutputFile);

end

fprintf('\n');
fprintf('Visualization figures saved successfully.\n');
fprintf('Folder:\n%s\n', VisualizationFolder);

fprintf('\n');
fprintf('============================================================\n');
fprintf('CFAR VISUALIZATION COMPLETED SUCCESSFULLY\n');
fprintf('============================================================\n');