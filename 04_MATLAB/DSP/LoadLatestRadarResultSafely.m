%% ============================================================
% LOAD RADAR RESULT FILE SAFELY
% ============================================================

clc;

fprintf('\n============================================================\n');
fprintf('SARRS STUDIO - LOAD RADAR RESULT SAFELY\n');
fprintf('============================================================\n');

%% 1. Detect current MATLAB folder

CurrentFolder = pwd;

fprintf('\nCurrent MATLAB folder:\n%s\n', CurrentFolder);

%% 2. Define results folder

ResultsFolder = fullfile(CurrentFolder, 'SARRS_Results');

if ~exist(ResultsFolder, 'dir')

    error(['Results folder does not exist: ', ResultsFolder]);

end

fprintf('\nResults folder:\n%s\n', ResultsFolder);

%% 3. Search recursively for all radar result files

RadarFiles = dir(fullfile( ...
    ResultsFolder, ...
    '**', ...
    'FiveTargetRadar_Result_*.mat'));

if isempty(RadarFiles)

    error([ ...
        'No FiveTargetRadar_Result_*.mat file found. ', ...
        'Run FiveTargetRadar simulation first.' ...
        ]);

end

fprintf('\nRadar result files found: %d\n', numel(RadarFiles));

%% 4. Sort files from newest to oldest

[~, SortIndex] = sort([RadarFiles.datenum], 'descend');

RadarFiles = RadarFiles(SortIndex);

%% 5. Try loading files one by one

LoadedRadarData = [];

LatestMATFile = '';

FileLoadedSuccessfully = false;

for FileIndex = 1:numel(RadarFiles)

    CandidateFile = fullfile( ...
        RadarFiles(FileIndex).folder, ...
        RadarFiles(FileIndex).name);

    fprintf('\nChecking file %d/%d:\n%s\n', ...
        FileIndex, ...
        numel(RadarFiles), ...
        CandidateFile);

    %% Check file size

    FileInfo = dir(CandidateFile);

    if isempty(FileInfo)

        fprintf('File information unavailable. Skipping.\n');

        continue;

    end

    fprintf('File size: %.2f kB\n', ...
        FileInfo.bytes / 1024);

    if FileInfo.bytes == 0

        fprintf('File is empty. Skipping.\n');

        continue;

    end

    %% Test file readability

    try

        TestVariables = whos('-file', CandidateFile);

        if isempty(TestVariables)

            fprintf('MAT file contains no variables. Skipping.\n');

            continue;

        end

        fprintf('Variables detected: %d\n', ...
            numel(TestVariables));

    catch ME

        fprintf('File cannot be inspected:\n%s\n', ME.message);

        fprintf('Skipping this file.\n');

        continue;

    end

    %% Try loading the file

    try

        TemporaryRadarData = load(CandidateFile);

        fprintf('File loaded successfully.\n');

        LoadedRadarData = TemporaryRadarData;

        LatestMATFile = CandidateFile;

        FileLoadedSuccessfully = true;

        break;

    catch ME

        fprintf('Unable to load this file:\n%s\n', ME.message);

        fprintf('Trying the next file...\n');

    end

end

%% 6. Stop if no valid file could be loaded

if ~FileLoadedSuccessfully

    error([ ...
        'Radar result files were found, but none could be loaded. ', ...
        'The MAT files may be corrupted or incomplete. ', ...
        'Run FiveTargetRadar again and save a new result file.' ...
        ]);

end

%% 7. Display loaded file

fprintf('\n============================================================\n');
fprintf('RADAR RESULT LOADED SUCCESSFULLY\n');
fprintf('============================================================\n');

fprintf('\nLoaded MAT file:\n%s\n', LatestMATFile);

fprintf('\nLoaded variables:\n');

disp(fieldnames(LoadedRadarData));

%% 8. Check required variables

RequiredVariables = { ...
    'RangeAxis_m', ...
    'VelocityAxis_mps', ...
    'DopplerAxis_Hz', ...
    'RangeDopplerPower', ...
    'TargetRanges_m', ...
    'TargetVelocities_mps' ...
    };

LoadedVariableNames = fieldnames(LoadedRadarData);

for VariableIndex = 1:numel(RequiredVariables)

    RequiredName = RequiredVariables{VariableIndex};

    if ~ismember(RequiredName, LoadedVariableNames)

        warning([ ...
            'Required variable is missing: ', ...
            RequiredName ...
            ]);

    end

end

%% 9. Copy loaded variables into MATLAB workspace

VariableNames = fieldnames(LoadedRadarData);

for VariableIndex = 1:numel(VariableNames)

    VariableName = VariableNames{VariableIndex};

    assignin( ...
        'base', ...
        VariableName, ...
        LoadedRadarData.(VariableName));

end

fprintf('\nLoaded variables copied to MATLAB workspace.\n');

fprintf('\n============================================================\n');