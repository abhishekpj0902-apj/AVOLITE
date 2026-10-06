function state = emitter_state(emitterID, time_s)
%EMITTER_STATE Return ground-truth time-varying emitter state.
%
% Inputs:
%   emitterID : Emitter number, 1...8
%   time_s    : Simulation time in seconds
%
% Output:
%   state     : Ground-truth emitter state at time_s
%
% This function is part of the AVOLITE mathematical reference model.
%
% MATLAB R2025b

arguments
    emitterID (1,1) double {mustBeInteger,mustBeInRange(emitterID,1,8)}
    time_s (1,1) double {mustBeNonnegative}
end

%% Load static emitter configuration
emitter = emitter_model(emitterID);

%% Basic state
state.id = emitter.id;
state.name = emitter.name;
state.type = emitter.type;

%% Simulation time
state.time_s = time_s;

%% Default values
state.active = false;
state.frequency_Hz = emitter.rf.frequency_Hz;

state.pulse_active = false;
state.pulse_index = NaN;

state.PRI_s = emitter.waveform.PRI_s;

%% ------------------------------------------------------------
%  E1 - Persistent radar
% -------------------------------------------------------------
if emitterID == 1

    state.active = true;

    if ~isnan(emitter.waveform.PRI_s)
        state.PRI_s = emitter.waveform.PRI_s;

        state.pulse_index = floor( ...
            time_s / state.PRI_s);

        time_in_PRI = mod(time_s,state.PRI_s);

        state.pulse_active = ...
            time_in_PRI < emitter.waveform.pulseWidth_s;
    end

%% ------------------------------------------------------------
%  E2 - Periodic radar
% -------------------------------------------------------------
elseif emitterID == 2

    period_s = emitter.activity.period_s;
    activeDuration_s = emitter.activity.activeDuration_s;

    time_in_period = mod(time_s,period_s);

    state.active = ...
        time_in_period < activeDuration_s;

    state.PRI_s = emitter.waveform.PRI_s;

    if state.active

        state.pulse_index = floor( ...
            time_s / state.PRI_s);

        time_in_PRI = mod(time_s,state.PRI_s);

        state.pulse_active = ...
            time_in_PRI < emitter.waveform.pulseWidth_s;
    end

%% ------------------------------------------------------------
%  E3 - Intermittent radar
% -------------------------------------------------------------
elseif emitterID == 3

    period_s = emitter.activity.period_s;
    activeDuration_s = emitter.activity.activeDuration_s;

    time_in_period = mod(time_s,period_s);

    state.active = ...
        time_in_period < activeDuration_s;

    state.PRI_s = emitter.waveform.PRI_s;

    if state.active

        state.pulse_index = floor( ...
            time_s / state.PRI_s);

        time_in_PRI = mod(time_s,state.PRI_s);

        state.pulse_active = ...
            time_in_PRI < emitter.waveform.pulseWidth_s;
    end

%% ------------------------------------------------------------
%  E4 - Frequency-agile radar
% -------------------------------------------------------------
elseif emitterID == 4

    state.active = true;

    dwell_s = emitter.agility.dwell_s;
    frequencies_Hz = emitter.agility.frequencies_Hz;

    frequency_index = ...
        mod(floor(time_s / dwell_s), ...
        numel(frequencies_Hz)) + 1;

    state.frequency_Hz = ...
        frequencies_Hz(frequency_index);

    state.PRI_s = emitter.waveform.PRI_s;

    state.pulse_index = floor( ...
        time_s / state.PRI_s);

    time_in_PRI = mod(time_s,state.PRI_s);

    state.pulse_active = ...
        time_in_PRI < emitter.waveform.pulseWidth_s;

    state.frequency_index = frequency_index;

%% ------------------------------------------------------------
%  E5 - Staggered PRI radar
% -------------------------------------------------------------
elseif emitterID == 5

    state.active = true;

    PRI_values_s = emitter.PRI.values_s;

    number_of_PRI_values = numel(PRI_values_s);

    % Determine staggered PRI index
    % using pulse count approximation.
    pulse_index = 0;
    elapsed_s = 0;

    while true

        current_index = ...
            mod(pulse_index,number_of_PRI_values) + 1;

        current_PRI_s = PRI_values_s(current_index);

        if elapsed_s + current_PRI_s > time_s
            break;
        end

        elapsed_s = elapsed_s + current_PRI_s;
        pulse_index = pulse_index + 1;

    end

    state.pulse_index = pulse_index;
    state.PRI_s = current_PRI_s;

    time_since_pulse_start_s = ...
        time_s - elapsed_s;

    state.pulse_active = ...
        time_since_pulse_start_s < ...
        emitter.waveform.pulseWidth_s;

%% ------------------------------------------------------------
%  E6 - Burst communication
% -------------------------------------------------------------
elseif emitterID == 6

    period_s = emitter.activity.period_s;
    activeDuration_s = emitter.activity.activeDuration_s;

    time_in_period = mod(time_s,period_s);

    state.active = ...
        time_in_period < activeDuration_s;

    state.pulse_active = state.active;

%% ------------------------------------------------------------
%  E7 - Intermittent communication
% -------------------------------------------------------------
elseif emitterID == 7

    period_s = emitter.activity.period_s;
    activeDuration_s = emitter.activity.activeDuration_s;

    time_in_period = mod(time_s,period_s);

    state.active = ...
        time_in_period < activeDuration_s;

    state.pulse_active = state.active;

%% ------------------------------------------------------------
%  E8 - Unknown / new emitter
% -------------------------------------------------------------
elseif emitterID == 8

    state.active = true;

    % E8 intentionally has an initially unknown waveform model.
    state.pulse_active = true;

end

%% Ground-truth RF power
if state.active
    state.power_W = emitter.rf.power_W;
else
    state.power_W = 0;
end

%% Ground-truth activity probability
% This is TRUE simulation information and must NOT be supplied
% directly to the AI later.
state.groundTruthActivity = state.active;

end