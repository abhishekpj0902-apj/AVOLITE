function emitter = emitter_model(emitterID)
%EMITTER_MODEL AVOLITE ground-truth RF emitter model.
%
% Returns the deterministic mathematical description of one emitter.
%
% E1 - Persistent radar
% E2 - Periodic radar
% E3 - Intermittent radar
% E4 - Frequency-agile radar
% E5 - Staggered-PRI radar
% E6 - Burst communication
% E7 - Intermittent communication
% E8 - Unknown/new emitter
%
% All internal quantities use SI units.
%
% MATLAB R2025b

arguments
    emitterID (1,1) double {mustBeInteger,mustBeInRange(emitterID,1,8)}
end

%% Common structure
emitter.id = emitterID;
emitter.name = "";
emitter.type = "";
emitter.domain = "";

%% RF parameters
emitter.rf.frequency_Hz = NaN;
emitter.rf.bandwidth_Hz = NaN;
emitter.rf.power_W = NaN;

%% Pulse/burst parameters
emitter.waveform.pulseWidth_s = NaN;
emitter.waveform.PRI_s = NaN;
emitter.waveform.dutyCycle = NaN;

%% Activity parameters
emitter.activity.mode = "";
emitter.activity.period_s = NaN;
emitter.activity.activeDuration_s = NaN;
emitter.activity.dutyCycle = NaN;

%% Spatial parameters
emitter.position_m = [NaN NaN NaN];
emitter.velocity_mps = [0 0 0];

emitter.angle.azimuth_rad = NaN;
emitter.angle.elevation_rad = NaN;

%% Frequency agility
emitter.agility.enabled = false;
emitter.agility.frequencies_Hz = [];
emitter.agility.dwell_s = NaN;

%% PRI agility
emitter.PRI.staggered = false;
emitter.PRI.values_s = [];

%% Unknown/new-emitter flag
emitter.unknown = false;

%% Emitter-specific configuration

switch emitterID

    case 1
        % E1: Persistent radar
        emitter.name = "E1";
        emitter.type = "Persistent Radar";
        emitter.domain = "Radar";

        emitter.rf.frequency_Hz = 10e9;
        emitter.rf.bandwidth_Hz = 20e6;
        emitter.rf.power_W = 100;

        emitter.waveform.pulseWidth_s = 1e-6;
        emitter.waveform.PRI_s = 1e-3;

        emitter.activity.mode = "continuous";
        emitter.activity.period_s = Inf;
        emitter.activity.activeDuration_s = Inf;
        emitter.activity.dutyCycle = 1;

    case 2
        % E2: Periodic radar
        emitter.name = "E2";
        emitter.type = "Periodic Radar";
        emitter.domain = "Radar";

        emitter.rf.frequency_Hz = 10.2e9;
        emitter.rf.bandwidth_Hz = 20e6;
        emitter.rf.power_W = 100;

        emitter.waveform.pulseWidth_s = 1e-6;
        emitter.waveform.PRI_s = 1e-3;

        emitter.activity.mode = "periodic";
        emitter.activity.period_s = 100e-3;
        emitter.activity.activeDuration_s = 20e-3;
        emitter.activity.dutyCycle = ...
            emitter.activity.activeDuration_s / emitter.activity.period_s;

    case 3
        % E3: Intermittent radar
        emitter.name = "E3";
        emitter.type = "Intermittent Radar";
        emitter.domain = "Radar";

        emitter.rf.frequency_Hz = 10.4e9;
        emitter.rf.bandwidth_Hz = 20e6;
        emitter.rf.power_W = 80;

        emitter.waveform.pulseWidth_s = 2e-6;
        emitter.waveform.PRI_s = 2e-3;

        emitter.activity.mode = "intermittent";
        emitter.activity.period_s = 200e-3;
        emitter.activity.activeDuration_s = 10e-3;
        emitter.activity.dutyCycle = ...
            emitter.activity.activeDuration_s / emitter.activity.period_s;

    case 4
        % E4: Frequency-agile radar
        emitter.name = "E4";
        emitter.type = "Frequency-Agile Radar";
        emitter.domain = "Radar";

        emitter.rf.frequency_Hz = 10.6e9;
        emitter.rf.bandwidth_Hz = 20e6;
        emitter.rf.power_W = 100;

        emitter.waveform.pulseWidth_s = 1e-6;
        emitter.waveform.PRI_s = 1e-3;

        emitter.activity.mode = "continuous";

        emitter.agility.enabled = true;
        emitter.agility.frequencies_Hz = ...
            [10.6 10.7 10.8 10.9] * 1e9;
        emitter.agility.dwell_s = 5e-3;

    case 5
        % E5: Staggered-PRI radar
        emitter.name = "E5";
        emitter.type = "Staggered-PRI Radar";
        emitter.domain = "Radar";

        emitter.rf.frequency_Hz = 11e9;
        emitter.rf.bandwidth_Hz = 20e6;
        emitter.rf.power_W = 100;

        emitter.waveform.pulseWidth_s = 1e-6;

        emitter.PRI.staggered = true;
        emitter.PRI.values_s = ...
            [0.8 1.0 1.2 1.0] * 1e-3;

        emitter.waveform.PRI_s = mean(emitter.PRI.values_s);

        emitter.activity.mode = "continuous";

    case 6
        % E6: Burst communication
        emitter.name = "E6";
        emitter.type = "Burst Communication";
        emitter.domain = "Communication";

        emitter.rf.frequency_Hz = 2.4e9;
        emitter.rf.bandwidth_Hz = 20e6;
        emitter.rf.power_W = 5;

        emitter.waveform.pulseWidth_s = 1e-3;
        emitter.waveform.PRI_s = NaN;

        emitter.activity.mode = "burst";
        emitter.activity.period_s = 50e-3;
        emitter.activity.activeDuration_s = 5e-3;
        emitter.activity.dutyCycle = ...
            emitter.activity.activeDuration_s / emitter.activity.period_s;

    case 7
        % E7: Intermittent communication
        emitter.name = "E7";
        emitter.type = "Intermittent Communication";
        emitter.domain = "Communication";

        emitter.rf.frequency_Hz = 2.5e9;
        emitter.rf.bandwidth_Hz = 10e6;
        emitter.rf.power_W = 3;

        emitter.waveform.pulseWidth_s = 2e-3;
        emitter.waveform.PRI_s = NaN;

        emitter.activity.mode = "intermittent";
        emitter.activity.period_s = 500e-3;
        emitter.activity.activeDuration_s = 20e-3;
        emitter.activity.dutyCycle = ...
            emitter.activity.activeDuration_s / emitter.activity.period_s;

    case 8
        % E8: Unknown/new emitter
        emitter.name = "E8";
        emitter.type = "Unknown/New Emitter";
        emitter.domain = "Unknown";

        emitter.rf.frequency_Hz = 9.5e9;
        emitter.rf.bandwidth_Hz = 5e6;
        emitter.rf.power_W = 10;

        emitter.waveform.pulseWidth_s = NaN;
        emitter.waveform.PRI_s = NaN;

        emitter.activity.mode = "unknown";

        emitter.unknown = true;
end

end
