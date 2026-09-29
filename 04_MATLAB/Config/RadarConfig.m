function Config = RadarConfig()

%=========================================================
% SARRS STUDIO
% Radar Configuration
%
% Purpose:
%   Stores configurable radar operating modes and
%   multi-PRF parameters.
%
% Radar.m
%   -> Physical radar model
%
% RadarConfig.m
%   -> Operating configuration
%=========================================================


%% ========================================================
% Primary Operating Configuration
%========================================================

Config.Mode = "MultiPRF";

Config.PrimaryPRF = 1000;


%% ========================================================
% Multi-PRF Configuration
%========================================================

Config.PRFList = [800 900 1000];

Config.NumPRFs = ...
    length(Config.PRFList);


%% ========================================================
% Radar Requirements
%========================================================

Config.RequiredMaximumRange = ...
    150000;

Config.RequiredMaximumVelocity = ...
    450;


%% ========================================================
% Doppler Processing
%========================================================

Config.DopplerProcessing = ...
    "MultiPRF";

Config.DopplerAmbiguityResolution = true;


%% ========================================================
% Multi-Pulse Configuration
%========================================================

Config.NumPulses = 64;


%% ========================================================
% Tracking Configuration
%========================================================

Config.EnableTracking = true;

Config.EnableKalman = true;

Config.EnableTrackAssociation = true;


%% ========================================================
% CFAR Configuration
%========================================================

Config.EnableCFAR = true;

Config.CFARThreshold = 0.40;


%% ========================================================
% Radar Range / Velocity Limits
%========================================================

% These are calculated later using RadarData.

Config.MaxUnambiguousRange = [];

Config.MaxUnambiguousVelocity = [];


%% ========================================================
% Description
%========================================================

Config.Description = ...
    "SARRS Radar Operating Configuration";

end