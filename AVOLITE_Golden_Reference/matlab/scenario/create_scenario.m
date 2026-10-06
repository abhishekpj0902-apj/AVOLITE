function scenario = create_scenario(cfg)
%CREATE_SCENARIO Create deterministic AVOLITE reference scenario.
%
% Inputs:
%   cfg      - AVOLITE configuration structure
%
% Outputs:
%   scenario - complete scenario definition

%% ============================================================
% RECEIVER
% =============================================================

scenario.receiver.id = "RX01";

scenario.receiver.position_m = [0; 0; 0];

scenario.receiver.azimuth_rad = 0;

scenario.receiver.elevation_rad = 0;

%% ============================================================
% EMITTER POSITIONS
% =============================================================

positions_m = [
     1000,     0,     0;
      800,   600,     0;
      600,   800,     0;
    -1000,   500,     0;
      500, -1000,     0;
      300,   400,     0;
     -400,   300,     0;
      700,  -700,     0
];

scenario.emitters.position_m = positions_m;

scenario.emitters.numberOfEmitters = size(positions_m,1);

%% ============================================================
% CALCULATE GEOMETRY
% =============================================================

rx = scenario.receiver.position_m(:);

nEmitters = scenario.emitters.numberOfEmitters;

scenario.emitters.range_m = zeros(nEmitters,1);

scenario.emitters.azimuth_rad = zeros(nEmitters,1);

scenario.emitters.elevation_rad = zeros(nEmitters,1);

for i = 1:nEmitters

    p = positions_m(i,:).';

    relativePosition = p - rx;

    range_m = norm(relativePosition);

    horizontalRange_m = hypot( ...
        relativePosition(1), ...
        relativePosition(2));

    azimuth_rad = atan2( ...
        relativePosition(2), ...
        relativePosition(1));

    elevation_rad = atan2( ...
        relativePosition(3), ...
        horizontalRange_m);

    scenario.emitters.range_m(i) = range_m;

    scenario.emitters.azimuth_rad(i) = azimuth_rad;

    scenario.emitters.elevation_rad(i) = elevation_rad;

end

%% ============================================================
% ENVIRONMENT
% =============================================================

scenario.environment.temperature_K = ...
    cfg.environment.temperature_K;

scenario.environment.atmosphericLoss_dB_per_km = 0;

scenario.environment.multipathEnabled = ...
    cfg.propagation.enableMultipath;

scenario.environment.fadingEnabled = ...
    cfg.propagation.enableFading;

scenario.environment.interferenceEnabled = ...
    cfg.propagation.enableInterference;

scenario.environment.noiseEnabled = ...
    cfg.propagation.enableNoise;

%% ============================================================
% SIMULATION TIME
% =============================================================

scenario.time.startTime_s = ...
    cfg.simulation.startTime_s;

scenario.time.stopTime_s = ...
    cfg.simulation.stopTime_s;

scenario.time.sampleRate_Hz = ...
    cfg.simulation.sampleRate_Hz;

scenario.time.timeStep_s = ...
    cfg.simulation.timeStep_s;

end