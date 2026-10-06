function [ProjectRoot, Paths] = InitializeSARRSPath()
% ============================================================
% InitializeSARRSPath
%
% SARRS STUDIO MATLAB PROJECT PATH INITIALIZATION
%
% Purpose:
%   1. Find the SARRS project root
%   2. Add all project folders to MATLAB path
%   3. Give project folders priority over MATLAB toolbox conflicts
%   4. Clear path cache
%   5. Verify important project files
%
% Expected project structure:
%
% D:\SARRS_STUDIO
%       |
%       +---04_MATLAB
%       |      +---Core
%       |      +---Config
%       |      +---Models
%       |      +---DSP
%       |
%       +---17_Telemetry
%
% ============================================================

    clc;

    %% --------------------------------------------------------
    % FIND THIS FILE LOCATION
    % ---------------------------------------------------------

    ThisFile = mfilename('fullpath');

    if isempty(ThisFile)
        error( ...
            'InitializeSARRSPath:FileLocationError', ...
            'MATLAB could not determine the location of this file.');
    end

    ThisFolder = fileparts(ThisFile);

    % This file is located in:
    %
    % D:\SARRS_STUDIO\04_MATLAB\Core
    %
    CoreFolder = ThisFolder;

    % Move from Core to 04_MATLAB
    MATLABFolder = fileparts(CoreFolder);

    % Move from 04_MATLAB to SARRS_STUDIO
    ProjectRoot = fileparts(MATLABFolder);

    %% --------------------------------------------------------
    % VERIFY PROJECT ROOT
    % ---------------------------------------------------------

    if ~isfolder(ProjectRoot)

        error( ...
            'InitializeSARRSPath:ProjectRootNotFound', ...
            'Project root was not found: %s', ...
            ProjectRoot);

    end

    ExpectedMATLABFolder = fullfile(ProjectRoot, '04_MATLAB');

    if ~isfolder(ExpectedMATLABFolder)

        error( ...
            'InitializeSARRSPath:MATLABFolderNotFound', ...
            '04_MATLAB folder was not found inside: %s', ...
            ProjectRoot);

    end

    %% --------------------------------------------------------
    % DEFINE IMPORTANT PROJECT FOLDERS
    % ---------------------------------------------------------

    Paths = struct();

    Paths.ProjectRoot = ProjectRoot;

    Paths.MATLAB = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB');

    Paths.Core = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Core');

    Paths.Config = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Config');

    Paths.Models = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Models');

    Paths.DSP = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'DSP');

    Paths.Functions = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Functions');

    Paths.Classes = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Classes');

    Paths.Receiver = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Receiver');

    Paths.Radar = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Radar');

    Paths.Utilities = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Utilities');

    Paths.Visualization = fullfile( ...
        ProjectRoot, ...
        '04_MATLAB', ...
        'Visualization');

    Paths.Telemetry = fullfile( ...
        ProjectRoot, ...
        '17_Telemetry');

    Paths.Results = fullfile( ...
        ProjectRoot, ...
        '08_Results');

    Paths.ResultDoc = fullfile( ...
        ProjectRoot, ...
        'Result_doc');

    %% --------------------------------------------------------
    % ADD COMPLETE PROJECT TREE
    % ---------------------------------------------------------

    addpath(genpath(ProjectRoot));

    %% --------------------------------------------------------
    % GIVE PROJECT FOLDERS HIGH PRIORITY
    % ---------------------------------------------------------

    PriorityFolders = { ...
        Paths.Core, ...
        Paths.Config, ...
        Paths.Models, ...
        Paths.DSP, ...
        Paths.Functions, ...
        Paths.Classes, ...
        Paths.Receiver, ...
        Paths.Radar, ...
        Paths.Utilities, ...
        Paths.Visualization, ...
        Paths.Telemetry ...
    };

    for k = 1:numel(PriorityFolders)

        CurrentFolder = PriorityFolders{k};

        if isfolder(CurrentFolder)

            addpath(CurrentFolder, '-begin');

        end

    end

    %% --------------------------------------------------------
    % REFRESH MATLAB PATH
    % ---------------------------------------------------------

    rehash path;

    %% --------------------------------------------------------
    % PRINT PROJECT INFORMATION
    % ---------------------------------------------------------

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('             SARRS STUDIO PATH INITIALIZED\n');
    fprintf('============================================================\n');
    fprintf('Project Root : %s\n', ProjectRoot);
    fprintf('MATLAB Root  : %s\n', Paths.MATLAB);
    fprintf('Models       : %s\n', Paths.Models);
    fprintf('DSP          : %s\n', Paths.DSP);
    fprintf('Telemetry    : %s\n', Paths.Telemetry);
    fprintf('============================================================\n');
    fprintf('\n');

    %% --------------------------------------------------------
    % VERIFY IMPORTANT FILES
    % ---------------------------------------------------------

    ImportantFiles = { ...
        fullfile(Paths.Config, 'SimulationConfig.m'), ...
        fullfile(Paths.Config, 'RadarConfig.m'), ...
        fullfile(Paths.Config, 'ReceiverConfig.m'), ...
        fullfile(Paths.Config, 'EnvironmentConfig.m'), ...
        fullfile(Paths.Config, 'DisplayConfig.m'), ...
        fullfile(Paths.Config, 'LoggingConfig.m'), ...
        fullfile(Paths.Models, 'Environment.m'), ...
        fullfile(Paths.Models, 'Mission.m'), ...
        fullfile(Paths.Models, 'Target.m'), ...
        fullfile(Paths.Models, 'Radar.m'), ...
        fullfile(Paths.Models, 'Waveform.m'), ...
        fullfile(Paths.Models, 'Receiver.m'), ...
        fullfile(Paths.Models, 'MatchedFilter.m'), ...
        fullfile(Paths.DSP, 'MultiPRFPulseScheduler.m'), ...
        fullfile(Paths.DSP, 'MTI.m'), ...
        fullfile(Paths.DSP, 'MTD.m'), ...
        fullfile(Paths.DSP, 'RangeDopplerProcessor.m'), ...
        fullfile(Paths.DSP, 'RangeDopplerCFAR.m'), ...
        fullfile(Paths.DSP, 'DopplerEstimator.m'), ...
        fullfile(Paths.DSP, 'PulseIntegrator.m'), ...
        fullfile(Paths.DSP, 'TargetAssociation.m'), ...
        fullfile(Paths.DSP, 'TrackInitiator.m'), ...
        fullfile(Paths.DSP, 'KalmanTracker.m'), ...
        fullfile(Paths.DSP, 'TrackManager.m'), ...
        fullfile(Paths.Telemetry, 'SARRS_Telemetry.m'), ...
        fullfile(Paths.Telemetry, 'SARRS_AdaptiveController.m'), ...
        fullfile(Paths.Telemetry, 'SARRS_ResultsLogger.m') ...
    };

    fprintf('FILE VERIFICATION\n');
    fprintf('-----------------\n');

    MissingCount = 0;

    for k = 1:numel(ImportantFiles)

        CurrentFile = ImportantFiles{k};

        if isfile(CurrentFile)

            fprintf('[FOUND]   %s\n', CurrentFile);

        else

            fprintf('[MISSING] %s\n', CurrentFile);
            MissingCount = MissingCount + 1;

        end

    end

    fprintf('\n');

    if MissingCount == 0

        fprintf('All important SARRS files were found.\n');

    else

        fprintf( ...
            'Warning: %d important file(s) were not found.\n', ...
            MissingCount);

    end

    %% --------------------------------------------------------
    % VERIFY NAME CONFLICTS
    % ---------------------------------------------------------

    fprintf('\n');
    fprintf('MATLAB FUNCTION RESOLUTION\n');
    fprintf('--------------------------\n');

    fprintf('\nEnvironment:\n');
    which Environment -all

    fprintf('\nMission:\n');
    which Mission -all

    fprintf('\nTarget:\n');
    which Target -all

    fprintf('\nRadar:\n');
    which Radar -all

    fprintf('\nReceiver:\n');
    which Receiver -all

    fprintf('\nWaveform:\n');
    which Waveform -all

    fprintf('\nMatchedFilter:\n');
    which MatchedFilter -all

    fprintf('\nSARRS_Telemetry:\n');
    which SARRS_Telemetry -all

    fprintf('\nInitialization complete.\n');
    fprintf('============================================================\n');

end