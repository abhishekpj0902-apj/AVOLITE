function MissionData = Mission()

%=========================================================
% SARRS STUDIO
% Mission Model
%
% Defines the radar mission profile.
%
%=========================================================

%% Mission Information

MissionData.Name = "Default Mission";

MissionData.Mode = "Search";

MissionData.Type = "Ground Based Radar";

MissionData.Priority = "Normal";

%% Operational Parameters

MissionData.StartTime = datetime("now");

MissionData.Duration = 60;          % seconds

MissionData.Status = "Running";

%% Mission Objectives

MissionData.Search = true;

MissionData.Track = true;

MissionData.Classify = true;

MissionData.Identify = true;

MissionData.Engage = false;

%% Threat Level

MissionData.ThreatLevel = "LOW";

%% Coverage

MissionData.MaxRange = 150000;      % meters

MissionData.ScanSector = 360;       % degrees

MissionData.ElevationCoverage = 90; % degrees

%% Radar Operation

MissionData.AllowECCM = true;

MissionData.AllowBeamSteering = true;

MissionData.AllowTracking = true;

MissionData.AllowAI = true;

MissionData.AllowLogging = true;

end