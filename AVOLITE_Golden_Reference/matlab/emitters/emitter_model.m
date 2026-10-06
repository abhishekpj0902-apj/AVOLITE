function emitters = emitter_model()
%EMITTER_MODEL Define the AVOLITE heterogeneous emitter population.
%
% Output:
%   emitters - array of emitter definitions

%% Number of emitters

N = 8;

emitters = repmat(struct(), N, 1);

%% ============================================================
% E1 - Persistent Radar
% =============================================================

emitters(1).id = "E1";
emitters(1).name = "Persistent Radar";
emitters(1).type = "Radar";

emitters(1).frequency_Hz = 10.0e9;
emitters(1).power_W = 100;

emitters(1).pulseWidth_s = 1e-6;
emitters(1).PRI_s = 1e-3;

emitters(1).activity.period_s = Inf;
emitters(1).activity.activeDuration_s = Inf;

emitters(1).behavior = "persistent";

%% ============================================================
% E2 - Periodic Radar
% =============================================================

emitters(2).id = "E2";
emitters(2).name = "Periodic Radar";
emitters(2).type = "Radar";

emitters(2).frequency_Hz = 10.2e9;
emitters(2).power_W = 100;

emitters(2).pulseWidth_s = 1e-6;
emitters(2).PRI_s = 1e-3;

emitters(2).activity.period_s = 100e-3;
emitters(2).activity.activeDuration_s = 20e-3;

emitters(2).behavior = "periodic";

%% ============================================================
% E3 - Intermittent Radar
% =============================================================

emitters(3).id = "E3";
emitters(3).name = "Intermittent Radar";
emitters(3).type = "Radar";

emitters(3).frequency_Hz = 10.4e9;
emitters(3).power_W = 80;

emitters(3).pulseWidth_s = 2e-6;
emitters(3).PRI_s = 2e-3;

emitters(3).activity.period_s = 200e-3;
emitters(3).activity.activeDuration_s = 10e-3;

emitters(3).behavior = "intermittent";

%% ============================================================
% E4 - Frequency Agile Radar
% =============================================================

emitters(4).id = "E4";
emitters(4).name = "Frequency-Agile Radar";
emitters(4).type = "Radar";

emitters(4).frequency_Hz = 10.6e9;
emitters(4).frequencySet_Hz = ...
    [10.6e9 10.7e9 10.8e9 10.9e9];

emitters(4).frequencyDwell_s = 5e-3;

emitters(4).power_W = 100;

emitters(4).pulseWidth_s = 1e-6;
emitters(4).PRI_s = 1e-3;

emitters(4).behavior = "frequency-agile";

%% ============================================================
% E5 - Staggered PRI Radar
% =============================================================

emitters(5).id = "E5";
emitters(5).name = "Staggered-PRI Radar";
emitters(5).type = "Radar";

emitters(5).frequency_Hz = 11.0e9;

emitters(5).power_W = 100;

emitters(5).pulseWidth_s = 1e-6;

emitters(5).PRISet_s = ...
    [0.8e-3 1.0e-3 1.2e-3 1.0e-3];

emitters(5).PRI_s = emitters(5).PRISet_s(1);

emitters(5).behavior = "staggered-PRI";

%% ============================================================
% E6 - Burst Communication
% =============================================================

emitters(6).id = "E6";
emitters(6).name = "Burst Communication";
emitters(6).type = "Communication";

emitters(6).frequency_Hz = 2.4e9;
emitters(6).power_W = 5;

emitters(6).burstPeriod_s = 50e-3;
emitters(6).burstDuration_s = 5e-3;

emitters(6).behavior = "burst";

%% ============================================================
% E7 - Intermittent Communication
% =============================================================

emitters(7).id = "E7";
emitters(7).name = "Intermittent Communication";
emitters(7).type = "Communication";

emitters(7).frequency_Hz = 2.5e9;
emitters(7).power_W = 3;

emitters(7).burstPeriod_s = 500e-3;
emitters(7).burstDuration_s = 20e-3;

emitters(7).behavior = "intermittent-burst";

%% ============================================================
% E8 - Unknown / New Emitter
% =============================================================

emitters(8).id = "E8";
emitters(8).name = "Unknown-New Emitter";
emitters(8).type = "Unknown";

emitters(8).frequency_Hz = 9.5e9;
emitters(8).power_W = 10;

emitters(8).pulseWidth_s = 1e-6;
emitters(8).PRI_s = 1e-3;

emitters(8).behavior = "unknown";

end
