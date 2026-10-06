function cfg = config_AVOLITE()
%CONFIG_AVOLITE Master configuration for AVOLITE.
%
% AVOLITE:
% Self-Adaptive Reconfigurable RF Receiver with
% Environment-Aware Intelligent Scan Scheduling
%
% MATLAB R2025b

%% Project information
cfg.project.name = "AVOLITE";
cfg.project.version = "0.1.0";
cfg.project.matlabVersion = "R2025b";

%% Unit conventions
cfg.units.distance = "m";
cfg.units.time = "s";
cfg.units.frequency = "Hz";
cfg.units.power = "W";
cfg.units.angleInternal = "rad";
cfg.units.angleDisplay = "deg";
cfg.units.temperature = "K";

%% Reproducibility
cfg.random.seed = 20260926;

end