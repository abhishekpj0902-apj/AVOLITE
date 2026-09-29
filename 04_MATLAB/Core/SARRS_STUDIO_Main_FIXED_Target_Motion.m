%% ============================================================
% SARRS STUDIO
%
% Smart AI Radar Research Simulator
%
% Main Simulation Engine
%
% Version : 1.0
%
%==============================================================

clear;
clc;
close all;

%% ============================================================
% Reset Persistent Simulation States
%==============================================================

clear TrackManager;
clear TargetAssociation;
clear KalmanTracker;
%% ============================================================
% Multi-Scan Configuration
%==============================================================

TotalScans = 10;

ScanInterval = 1.0;

%% ========================================================
% Tracking Initialization
%=========================================================

TrackTable = struct([]);
disp(' ')
disp('=========================================')
disp('         MULTI-SCAN RADAR MODE')
disp('=========================================')

fprintf('Total Scans   : %d\n',TotalScans);
fprintf('Scan Interval : %.1f s\n',ScanInterval);

disp(' ')

%% ============================================================
% Project Information
%==============================================================

disp(' ')
disp('=========================================')
disp('         SARRS STUDIO')
disp(' Smart AI Radar Research Simulator')
disp('=========================================')
disp(' ')

Simulation.StartTime = datetime("now");

Simulation.Version = "1.0";

Simulation.Status = "Initializing";

disp("Simulation Started")
disp(Simulation.StartTime)

disp(' ')

%% ============================================================
% Add Project Folders
%==============================================================

ProjectPath = fileparts(mfilename('fullpath'));

ProjectRoot = fileparts(ProjectPath);

addpath(genpath(ProjectRoot));

disp("Project Path Added")
disp(ProjectRoot)

disp(' ')

%% ============================================================
% Load Configuration
%==============================================================

disp("Loading Configuration...")

SimulationConfig;
RadarConfig;
ReceiverConfig;
EnvironmentConfig;
DisplayConfig;
LoggingConfig;

disp("Configuration Loaded")

disp(' ')

%% ============================================================
% Initialize Managers
%==============================================================

disp("Initializing Managers...")

disp("Environment Manager")
disp("Radar Manager")
disp("Receiver Manager")
disp("DSP Manager")
disp("Target Manager")
disp("Visualization Manager")
disp("Data Manager")
disp("Mission Manager")

disp(' ')

Simulation.Status = "Managers Initialized";

%% ============================================================
% Simulation Ready
%==============================================================

disp('=========================================')
disp("Initialization Complete")
disp('=========================================')

disp(' ')

%% ============================================================
% Environment Initialization
%==============================================================

disp('=========================================')
disp('Initializing Environment')
disp('=========================================')

Environment = Environment();

disp('Environment Created')
disp(Environment)

disp(' ')

%% ============================================================
% Mission Initialization
%==============================================================

disp('=========================================')
disp('Initializing Mission')
disp('=========================================')

Mission = Mission();

disp('Mission Ready')
disp(Mission)

disp(' ')

%% ============================================================
% Target Initialization
%==============================================================

disp('=========================================')
disp('Initializing Targets')
disp('=========================================')

Target = Target();
%% ========================================================
% VERIFY TARGET MOTION HISTORY
%=========================================================

disp(' ')
disp('=========================================')
disp('VERIFYING TARGET MOTION HISTORY')
disp('=========================================')

for k = 1:length(Target)

    fprintf('\nTarget %d\n',k)

    fprintf('Velocity : %.2f m/s\n', ...
        Target(k).Velocity);

    if isfield(Target(k),'Distance')

        fprintf('Distance samples : %d\n', ...
            numel(Target(k).Distance));

        fprintf('Scan 1 Distance  : %.3f m\n', ...
            Target(k).Distance(1));

        if numel(Target(k).Distance) >= 2
            fprintf('Scan 2 Distance  : %.3f m\n', ...
                Target(k).Distance(2));
        end

        if numel(Target(k).Distance) >= 10
            fprintf('Scan 10 Distance : %.3f m\n', ...
                Target(k).Distance(10));
        end

    else

        disp('NO Distance history')

    end

end

disp("Number of Targets")
disp(length(Target))

disp(' ')

%% ============================================================
% Radar Initialization
%==============================================================

disp('=========================================')
disp('Initializing Radar')
disp('=========================================')

Radar = Radar();
%% ========================================================
% Radar Operating Configuration
%=========================================================

RadarConfigData = RadarConfig();


%% Calculate Multi-PRF Limits

RadarConfigData.MaxUnambiguousRange = ...
    Radar.c ./ ...
    (2 * RadarConfigData.PRFList);

RadarConfigData.MaxUnambiguousVelocity = ...
    Radar.Wavelength .* ...
    RadarConfigData.PRFList / 4;

PRFData = MultiPRFPulseScheduler( ...
    RadarConfigData);
disp(' ');
disp('=========================================');
disp('Radar Operating Configuration');
disp('=========================================');

fprintf('Mode              : %s\n', ...
    RadarConfigData.Mode);

fprintf('Primary PRF       : %.0f Hz\n', ...
    RadarConfigData.PrimaryPRF);

fprintf('Number of PRFs    : %d\n', ...
    RadarConfigData.NumPRFs);

fprintf('Required Range    : %.1f km\n', ...
    RadarConfigData.RequiredMaximumRange/1000);

fprintf('Required Velocity : %.1f m/s\n', ...
    RadarConfigData.RequiredMaximumVelocity);

disp(' ');
disp('Multi-PRF Limits');

for k = 1:RadarConfigData.NumPRFs

    fprintf( ...
        'PRF %d : %.0f Hz | Range = %.2f km | Vmax = +/- %.2f m/s\n',...
        k,...
        RadarConfigData.PRFList(k),...
        RadarConfigData.MaxUnambiguousRange(k)/1000,...
        RadarConfigData.MaxUnambiguousVelocity(k));

end
disp(Radar)

disp(' ')

%% ============================================================
% Waveform Generation
%==============================================================

disp('=========================================')
disp('Generating Waveform')
disp('=========================================')

Waveform = Waveform(Radar);

disp(Waveform)

disp(' ')

%% ============================================================
% TARGET MOTION HISTORY
%==============================================================
% Store target range at EVERY scan so visualization shows the
% complete target motion instead of only the final TrackTable state.
%==============================================================

TargetHistory = struct();
TargetHistory.Scan = (1:TotalScans)';
TargetHistory.Time = ((0:TotalScans-1)' * ScanInterval);
TargetHistory.Range = nan(TotalScans,length(Target));

%% ============================================================
% MULTI-SCAN LOOP
%==============================================================

for CurrentScan = 1:TotalScans

    %% ========================================================
    % Scan Header
    %=========================================================

    disp(' ')
    disp('=========================================')

    fprintf('              SCAN %d\n',CurrentScan)

    disp('=========================================')

    fprintf('Scan Number : %d\n',CurrentScan)
%% ========================================================
% Echo Generation
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Generating Echo')
disp('-----------------------------------------')

EchoData = MultiPulseEcho( ...
    Target,...
    Radar,...
    Waveform,...
    CurrentScan,...
    PRFData);

disp(EchoData)

%% ========================================================
% Receiver Processing
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Receiver Processing')
disp('-----------------------------------------')

ReceiverData = Receiver(EchoData);

disp(ReceiverData)

    %% ========================================================
    % Matched Filter
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Matched Filter')
    disp('-----------------------------------------')

   Matched = MatchedFilter( ...
    ReceiverData,...
    Waveform,...
    Radar);

    disp(Matched)

    disp("Detected Peaks")
    disp(Matched.NumberOfPeaks)

    disp("Peak Ranges (m)")

    if ~isempty(Matched.PeakRanges)

        disp(Matched.PeakRanges')

    end

    %% ========================================================
    % Range Estimation
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Range Estimation')
    disp('-----------------------------------------')

    RangeData = RangeEstimator( ...
        Matched,...
        Radar);

    disp(RangeData)
%% ========================================================
% FFT Processing
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('FFT Processing')
disp('-----------------------------------------')

% Diagnostic FFT on first pulse only.
% Doppler FFT is performed later by MTD.

FFTData = FFT(Matched.Output(:,1));

disp(FFTData)

%% ========================================================
% MTI Processing
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('MTI Processing')
disp('-----------------------------------------')

% MTI operates across slow-time / pulses.

MTIData = MTI(Matched);

disp(MTIData)

%% ========================================================
% MTD Processing
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('MTD Processing')
disp('-----------------------------------------')

% MTD performs Doppler FFT across pulse dimension.

MTDData = MTD( ...
    MTIData,...
    Radar);

disp(MTDData)

    %% ========================================================
    % Range Doppler Processing
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Range Doppler Processing')
    disp('-----------------------------------------')

    RDMap = RangeDopplerProcessor( ...
        Matched,...
        Radar);

    disp(RDMap)

    %% ========================================================
    % 2D CFAR
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('2D CFAR')
    disp('-----------------------------------------')

    CFAR2D = RangeDopplerCFAR(RDMap);

    disp(CFAR2D)

    %% ========================================================
    % Doppler Estimation
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Doppler Estimation')
    disp('-----------------------------------------')

    DopplerData = DopplerEstimator( ...
        MTDData,...
        Radar);

    disp(DopplerData)

    %% ========================================================
    % Pulse Integration
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Pulse Integration')
    disp('-----------------------------------------')

  PulseData = PulseIntegrator( ...
    Matched.Output,...
    "NonCoherent",...
    64);

    disp(PulseData)

    %% ========================================================
    % Target Detection
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Target Detection')
    disp('-----------------------------------------')

    CFARData.Signal = PulseData.Output;

    CFARData.Index = Matched.PeakIndices;

    CFARData.Peaks = Matched.Peaks;

    CFARData.NumberOfTargets = ...
        Matched.NumberOfPeaks;

    CFARData.TargetDetected = ...
        Matched.NumberOfPeaks > 0;

    CFARData.Range = ...
        RangeData.PeakRanges;

    CFARData.NoiseFloor = ...
        mean(abs(PulseData.Output));

    CFARData.EstimatedSNR = ...
        PulseData.IntegrationGain;

    if isempty(Matched.Peaks)

        CFARData.PeakValue = 0;

    else

        CFARData.PeakValue = ...
            max(Matched.Peaks);

    end

    disp(CFARData)

    %% ========================================================
    % Target Association
    %=========================================================

    disp(' ')
    disp('-----------------------------------------')
    disp('Target Association')
    disp('-----------------------------------------')

%% ========================================================
% Multi-PRF Track Detection Preparation
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Track Detection Preparation')
disp('-----------------------------------------')

%% Convert CFAR detections into tracking input

TrackingCFAR = struct();

TrackingCFAR.Targets = ...
    CFAR2D.Targets;

TrackingCFAR.NumberOfTargets = ...
    CFAR2D.NumberOfTargets;

TrackingCFAR.TargetDetected = ...
    CFAR2D.TargetDetected;

%% Axes come from Range-Doppler Map

TrackingCFAR.RangeAxis = ...
    RDMap.RangeAxis;

TrackingCFAR.VelocityAxis = ...
    RDMap.VelocityAxis;

TrackingCFAR.DopplerAxis = ...
    RDMap.DopplerAxis;

TrackingCFAR.Description = ...
    "CFAR Detection Input for Tracking";

fprintf('CFAR Targets Passed To Tracking : %d\n', ...
    TrackingCFAR.NumberOfTargets);

%% ========================================================
% Target Association
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Multi-PRF Target Association')
disp('-----------------------------------------')

AssociationData = TargetAssociation( ...
    TrackingCFAR,...
    TrackTable);

disp(AssociationData)


%% ========================================================
% Track Initiation
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Track Initiation')
disp('-----------------------------------------')

TrackData = TrackInitiator( ...
    AssociationData);

disp(TrackData)


%% ========================================================
% Kalman Tracking
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Range-Velocity Kalman Tracking')
disp('-----------------------------------------')

TrackData = KalmanTracker( ...
    TrackData);

disp('========== KALMAN TRACK DATA ==========')

disp(TrackData)


%% ========================================================
% Track Management
%=========================================================

disp(' ')
disp('-----------------------------------------')
disp('Persistent Track Management')
disp('-----------------------------------------')

TrackTable = TrackManager( ...
    TrackData);

disp('========== TRACK TABLE ==========')

disp(TrackTable)

%% ========================================================
% STORE TARGET POSITION FOR THIS SCAN
%=========================================================

for TargetIndex = 1:length(Target)

    if isfield(Target(TargetIndex),'Distance') && ...
            numel(Target(TargetIndex).Distance) >= CurrentScan

        TargetHistory.Range(CurrentScan,TargetIndex) = ...
            Target(TargetIndex).Distance(CurrentScan);

    elseif isfield(Target(TargetIndex),'Position') && ...
            size(Target(TargetIndex).Position,2) >= CurrentScan

        PositionNow = Target(TargetIndex).Position(:,CurrentScan);

        TargetHistory.Range(CurrentScan,TargetIndex) = ...
            norm(PositionNow);

    else

        warning('No target range history for Target %d at Scan %d.', ...
            TargetIndex,CurrentScan);

    end
end

fprintf('\nTarget motion at Scan %d:\n',CurrentScan);

for TargetIndex = 1:length(Target)

    if ~isnan(TargetHistory.Range(CurrentScan,TargetIndex))

        fprintf('  Target %d : %.3f km\n', ...
            TargetIndex,...
            TargetHistory.Range(CurrentScan,TargetIndex)/1000);

    end
end

    %% ========================================================
    % Scan Summary
    %=========================================================

    disp(' ')
    disp('=========================================')
    disp('             SCAN SUMMARY')
    disp('=========================================')

    fprintf('Scan Number : %d\n',CurrentScan)

    fprintf('Detections  : %d\n', ...
        CFARData.NumberOfTargets)

    fprintf('Tracks      : %d\n', ...
        length(TrackTable))

    if ~isempty(TrackTable)

        for k = 1:length(TrackTable)

            fprintf( ...
                'Track %d | Range = %.1f m | Status = %s\n',...
                TrackTable(k).TrackID,...
                TrackTable(k).Range,...
                string(TrackTable(k).Status));

        end

    end

    %% ========================================================
    % Pause Between Scans
    %=========================================================

    if CurrentScan < TotalScans

        fprintf('\nWaiting %.1f seconds for next scan...\n', ...
            ScanInterval);

        pause(ScanInterval);

    end

end

%% ============================================================
% VISUALIZATION
%==============================================================

disp(' ')
disp('=========================================')
disp('Visualization')
disp('=========================================')

SignalPlots( ...
    Waveform,...
    EchoData,...
    ReceiverData,...
    Matched);

AScope(Matched);

BScope(TrackTable);

PPIDisplay(TrackTable,Radar);

TrajectoryPlot(TrackTable);
TargetMotionHistoryPlot(TargetHistory);

ThreatDisplay(TrackTable);

EngineeringConsole( ...
    Environment,...
    Mission,...
    Radar,...
    ReceiverData,...
    Matched,...
    CFARData,...
    TrackTable);

Logger( ...
    Environment,...
    Mission,...
    Radar,...
    TrackTable);

%% ============================================================
% Final Mission Report
%==============================================================

ResultViewer( ...
    Environment,...
    Mission,...
    Radar,...
    Target,...
    Matched,...
    CFARData,...
    TrackTable);

%% ============================================================
%  SARRS FINAL RESULT EXPORT
%  ============================================================

outputDir = 'D:\SARRS_STUDIO\Result_doc';

exportSARRSResults(results, outputDir);