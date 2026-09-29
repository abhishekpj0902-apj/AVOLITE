function Config = SimulationConfig(cfg)

%=========================================================
% SARRS STUDIO
% Simulation Configuration
%
% Purpose:
%   Provides simulation, waveform, sampling, noise,
%   receiver, and target-model parameters.
%=========================================================

if nargin < 1 || isempty(cfg)
    cfg = struct();
end

%% General simulation settings

Config.EnableNoise = true;
Config.RandomSeed = 10;

Config.NumScans = getField(cfg, "TotalScans", 20);
Config.ScanPeriod = getField(cfg, "ScanPeriod", 0.1);

%% Electromagnetic parameters

Config.SpeedOfLight = 299792458;
Config.CarrierFrequency = 10e9;
Config.Wavelength = ...
    Config.SpeedOfLight / Config.CarrierFrequency;

%% Waveform parameters

Config.Bandwidth = 20e6;
Config.PulseWidth = 10e-6;
Config.SampleRate = 50e6;
Config.NumFastTimeSamples = 2048;

Config.PulseRepetitionFrequency = 1000;
Config.NumPulses = 64;

%% Receiver parameters

Config.ReceiverGain = 30;
Config.NoiseFigure = 5;
Config.ADCResolution = 12;
Config.ADCFullScale = 1;

%% Noise parameters

Config.NoisePower = 1e-3;
Config.InputSignalPower = 1;

%% Processing parameters

Config.EnableRangeProcessing = true;
Config.EnableDopplerProcessing = true;
Config.EnableCFAR = true;
Config.EnableTracking = true;

%% Display parameters

Config.EnableRealtimeDisplay = true;
Config.EnableConsoleOutput = true;

%% Description

Config.Description = ...
    "SARRS simulation configuration";

end


function value = getField(s, fieldName, defaultValue)

if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end

end