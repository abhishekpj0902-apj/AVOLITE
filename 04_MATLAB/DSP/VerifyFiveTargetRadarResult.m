%% ============================================================
%  SARRS STUDIO
%  VERIFY FIVE-TARGET RADAR RESULT
%
%  File name:
%  VerifyFiveTargetRadarResult.m
%% ============================================================

clc;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - VERIFY FIVE-TARGET RADAR RESULT\n');
fprintf('============================================================\n');

%% ============================================================
% 1. RESULT FOLDER
%% ============================================================

ResultsFolder = fullfile(pwd, 'SARRS_Results');

fprintf('\nSearching folder:\n');
fprintf('%s\n', ResultsFolder);

if ~exist(ResultsFolder, 'dir')

    error('Result folder does not exist: %s', ResultsFolder);

end

%% ============================================================
% 2. SEARCH FOR RESULT FILES
%% ============================================================

ResultFiles = dir(fullfile( ...
    ResultsFolder, ...
    'FiveTargetRadar_Result_*.mat'));

% Remove empty files
ValidFiles = [];

for k = 1:length(ResultFiles)

    if ResultFiles(k).bytes > 0
        ValidFiles = [ValidFiles; ResultFiles(k)]; %#ok<AGROW>
    end

end

if isempty(ValidFiles)

    error(['No readable and valid radar MAT file was found. ' ...
           'Run FiveTargetRadar.m again.']);

end

% Sort by date
[~, SortIndex] = sort([ValidFiles.datenum], 'descend');

ValidFiles = ValidFiles(SortIndex);

LatestFile = ValidFiles(1);

LatestFilePath = fullfile( ...
    LatestFile.folder, ...
    LatestFile.name);

fprintf('\nLatest result file found:\n');
fprintf('%s\n', LatestFilePath);

fprintf('File size: %.2f KB\n', ...
    LatestFile.bytes/1024);

%% ============================================================
% 3. LOAD MAT FILE
%% ============================================================

try

    LoadedData = load(LatestFilePath);

catch ME

    error('MAT file could not be loaded:\n%s', ME.message);

end

fprintf('\nMAT file loaded successfully.\n');

%% ============================================================
% 4. CHECK RADAR RESULT STRUCTURE
%% ============================================================

if isfield(LoadedData, 'RadarResult')

    RadarResult = LoadedData.RadarResult;

    fprintf('RadarResult structure found.\n');

else

    error('RadarResult structure was not found.');

end

%% ============================================================
% 5. DISPLAY AVAILABLE VARIABLES
%% ============================================================

fprintf('\nAVAILABLE VARIABLES\n');
fprintf('------------------------------------------------------------\n');

VariableNames = fieldnames(LoadedData);

for k = 1:length(VariableNames)

    VariableName = VariableNames{k};

    VariableValue = LoadedData.(VariableName);

    VariableSize = size(VariableValue);

    fprintf('%-28s Size: ', VariableName);

    fprintf('%d ', VariableSize);

    fprintf('\n');

end

%% ============================================================
% 6. READ TARGET INFORMATION
%% ============================================================

if isfield(LoadedData, 'TargetRanges')

    TargetRanges = LoadedData.TargetRanges;

elseif isfield(RadarResult, 'TargetInformation')

    TargetRanges = ...
        RadarResult.TargetInformation.TargetRanges;

else

    error('Target range information not found.');

end

if isfield(LoadedData, 'TargetVelocities')

    TargetVelocities = LoadedData.TargetVelocities;

elseif isfield(RadarResult, 'TargetInformation')

    TargetVelocities = ...
        RadarResult.TargetInformation.TargetVelocities;

else

    error('Target velocity information not found.');

end

if isfield(LoadedData, 'TargetAmplitudes')

    TargetAmplitudes = LoadedData.TargetAmplitudes;

elseif isfield(RadarResult, 'TargetInformation')

    TargetAmplitudes = ...
        RadarResult.TargetInformation.TargetAmplitudes;

else

    error('Target amplitude information not found.');

end

NumberOfTargets = length(TargetRanges);

%% ============================================================
% 7. DISPLAY TARGET INFORMATION
%% ============================================================

fprintf('\nTARGET INFORMATION\n');
fprintf('------------------------------------------------------------\n');

fprintf('Number of targets: %d\n', NumberOfTargets);

fprintf('Target ranges in metres:\n');
disp(TargetRanges);

fprintf('Target velocities in m/s:\n');
disp(TargetVelocities);

fprintf('Target amplitudes:\n');
disp(TargetAmplitudes);

%% ============================================================
% 8. READ RADAR PARAMETERS
%% ============================================================

if isfield(LoadedData, 'fc')
    fc = LoadedData.fc;
else
    fc = RadarResult.RadarParameters.fc;
end

if isfield(LoadedData, 'B')
    B = LoadedData.B;
else
    B = RadarResult.RadarParameters.B;
end

if isfield(LoadedData, 'Tchirp')
    Tchirp = LoadedData.Tchirp;
else
    Tchirp = RadarResult.RadarParameters.Tchirp;
end

if isfield(LoadedData, 'Fs')
    Fs = LoadedData.Fs;
else
    Fs = RadarResult.RadarParameters.Fs;
end

if isfield(LoadedData, 'slope')
    slope = LoadedData.slope;
else
    slope = RadarResult.RadarParameters.slope;
end

if isfield(LoadedData, 'Ns')
    Ns = LoadedData.Ns;
else
    Ns = RadarResult.RadarParameters.Ns;
end

if isfield(LoadedData, 'Nchirps')
    Nchirps = LoadedData.Nchirps;
else
    Nchirps = RadarResult.RadarParameters.Nchirps;
end

%% ============================================================
% 9. DISPLAY RADAR PARAMETERS
%% ============================================================

fprintf('\nRADAR PARAMETERS\n');
fprintf('------------------------------------------------------------\n');

fprintf('Carrier frequency: %.2f GHz\n', fc/1e9);
fprintf('Bandwidth: %.2f MHz\n', B/1e6);
fprintf('Chirp duration: %.2f us\n', Tchirp*1e6);
fprintf('Sampling frequency: %.2f MHz\n', Fs/1e6);
fprintf('Chirp slope: %.3e Hz/s\n', slope);
fprintf('Number of samples: %d\n', Ns);
fprintf('Number of chirps: %d\n', Nchirps);

%% ============================================================
% 10. READ RANGE-DOPPLER DATA
%% ============================================================

if isfield(LoadedData, 'RangeAxis')
    RangeAxis = LoadedData.RangeAxis;
else
    RangeAxis = RadarResult.RangeProcessing.RangeAxis;
end

if isfield(LoadedData, 'RangeProfile_dB')
    RangeProfile_dB = LoadedData.RangeProfile_dB;
else
    RangeProfile_dB = ...
        RadarResult.RangeProcessing.RangeProfile_dB;
end

if isfield(LoadedData, 'DopplerMap_dB')
    DopplerMap_dB = LoadedData.DopplerMap_dB;
else
    DopplerMap_dB = ...
        RadarResult.DopplerProcessing.DopplerMap_dB;
end

if isfield(LoadedData, 'VelocityAxis')
    VelocityAxis = LoadedData.VelocityAxis;
else
    VelocityAxis = ...
        RadarResult.DopplerProcessing.VelocityAxis;
end

%% ============================================================
% 11. PLOT VERIFIED RANGE PROFILE
%% ============================================================

figure('Name', 'Verified Five-Target Range Profile', ...
       'Color', 'w');

plot(RangeAxis, RangeProfile_dB, ...
     'LineWidth', 1.8);

hold on;

for k = 1:NumberOfTargets

    xline(TargetRanges(k), '--r', ...
        sprintf('%d m', TargetRanges(k)), ...
        'LineWidth', 1.2, ...
        'LabelOrientation', 'aligned', ...
        'LabelVerticalAlignment', 'middle');

end

grid on;

xlabel('Range (m)', 'FontSize', 12);
ylabel('Magnitude (dB)', 'FontSize', 12);

title('Verified Five-Target Range Profile', ...
      'FontSize', 14, ...
      'FontWeight', 'bold');

xlim([0 200]);
ylim([-60 5]);

set(gca, 'FontSize', 11);

%% ============================================================
% 12. PLOT VERIFIED RANGE-DOPPLER MAP
%% ============================================================

figure('Name', 'Verified Five-Target Range-Doppler Map', ...
       'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
colormap turbo;
colorbar;

caxis([-40 0]);

hold on;

for k = 1:NumberOfTargets

    plot(TargetRanges(k), TargetVelocities(k), ...
        'wo', ...
        'MarkerSize', 9, ...
        'LineWidth', 1.5);

    text(TargetRanges(k) + 2, ...
         TargetVelocities(k), ...
         sprintf('T%d', k), ...
         'Color', 'w', ...
         'FontWeight', 'bold', ...
         'FontSize', 10);

end

xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('Verified Five-Target Range-Doppler Map', ...
      'FontSize', 14, ...
      'FontWeight', 'bold');

xlim([0 200]);
ylim([-25 25]);

set(gca, 'FontSize', 11);

%% ============================================================
% 13. CHECK TARGET RANGE BINS
%% ============================================================

fprintf('\nEXPECTED TARGET LOCATIONS\n');
fprintf('------------------------------------------------------------\n');

for k = 1:NumberOfTargets

    [~, RangeIndex] = min(abs(RangeAxis - TargetRanges(k)));

    [~, VelocityIndex] = ...
        min(abs(VelocityAxis - TargetVelocities(k)));

    MapValue = DopplerMap_dB(VelocityIndex, RangeIndex);

    fprintf(['Target %d: Expected Range = %6.2f m, ' ...
             'Expected Velocity = %6.2f m/s, ' ...
             'Map Value = %6.2f dB\n'], ...
             k, ...
             TargetRanges(k), ...
             TargetVelocities(k), ...
             MapValue);

end

%% ============================================================
% 14. COMPLETION MESSAGE
%% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('VERIFICATION COMPLETED SUCCESSFULLY\n');
fprintf('============================================================\n');