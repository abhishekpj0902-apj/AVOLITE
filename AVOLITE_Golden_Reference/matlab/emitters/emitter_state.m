function state = emitter_state(emitter, t_s)
%EMITTER_STATE Calculate time-varying ground-truth emitter state.
%
% Inputs:
%   emitter - one emitter definition from emitter_model()
%   t_s     - simulation time in seconds
%
% Output:
%   state   - ground-truth state at time t_s

%% Basic information

state.id = emitter.id;
state.name = emitter.name;
state.type = emitter.type;
state.time_s = t_s;

%% Default values

state.active = false;
state.pulse_active = false;

state.frequency_Hz = emitter.frequency_Hz;
state.power_W = emitter.power_W;

state.PRI_s = NaN;

state.pulse_index = NaN;

state.groundTruthActivity = false;

%% ============================================================
% E1 - Persistent Radar
% =============================================================

if emitter.id == "E1"

    state.active = true;
    state.groundTruthActivity = true;

    state.PRI_s = emitter.PRI_s;

    % Pulse timing within PRI
    pulsePosition_s = mod(t_s, emitter.PRI_s);

    state.pulse_active = ...
        pulsePosition_s < emitter.pulseWidth_s;

    state.pulse_index = ...
        floor(t_s / emitter.PRI_s) + 1;

%% ============================================================
% E2 - Periodic Radar
% =============================================================

elseif emitter.id == "E2"

    phase_s = mod(t_s, emitter.activity.period_s);

    state.active = ...
        phase_s < emitter.activity.activeDuration_s;

    state.groundTruthActivity = state.active;

    state.PRI_s = emitter.PRI_s;

    if state.active

        pulsePosition_s = mod(t_s, emitter.PRI_s);

        state.pulse_active = ...
            pulsePosition_s < emitter.pulseWidth_s;

        state.pulse_index = ...
            floor(t_s / emitter.PRI_s) + 1;

    end

%% ============================================================
% E3 - Intermittent Radar
% =============================================================

elseif emitter.id == "E3"

    phase_s = mod(t_s, emitter.activity.period_s);

    state.active = ...
        phase_s < emitter.activity.activeDuration_s;

    state.groundTruthActivity = state.active;

    state.PRI_s = emitter.PRI_s;

    if state.active

        pulsePosition_s = mod(t_s, emitter.PRI_s);

        state.pulse_active = ...
            pulsePosition_s < emitter.pulseWidth_s;

        state.pulse_index = ...
            floor(t_s / emitter.PRI_s) + 1;

    end

%% ============================================================
% E4 - Frequency Agile Radar
% =============================================================

elseif emitter.id == "E4"

    state.active = true;
    state.groundTruthActivity = true;

    % Determine current frequency slot
    numberOfFrequencies = ...
        length(emitter.frequencySet_Hz);

    frequencyIndex = ...
        mod(floor(t_s / emitter.frequencyDwell_s), ...
        numberOfFrequencies) + 1;

    state.frequency_Hz = ...
        emitter.frequencySet_Hz(frequencyIndex);

    state.frequency_index = frequencyIndex;

    state.PRI_s = emitter.PRI_s;

    pulsePosition_s = mod(t_s, emitter.PRI_s);

    state.pulse_active = ...
        pulsePosition_s < emitter.pulseWidth_s;

    state.pulse_index = ...
        floor(t_s / emitter.PRI_s) + 1;

%% ============================================================
% E5 - Staggered PRI Radar
% =============================================================

elseif emitter.id == "E5"

    state.active = true;
    state.groundTruthActivity = true;

    priSet_s = emitter.PRISet_s;

    numberOfPRIValues = length(priSet_s);

    % Duration of one complete stagger pattern
    patternDuration_s = sum(priSet_s);

    % Position inside the repeating pattern
    timeInPattern_s = mod(t_s, patternDuration_s);

    % Cumulative pulse-boundary times
    boundaries_s = [0 cumsum(priSet_s)];

    % Determine which PRI interval contains the current time
    priIndex = find( ...
        timeInPattern_s >= boundaries_s(1:end-1) & ...
        timeInPattern_s < boundaries_s(2:end), ...
        1, 'first');

    % Numerical protection at exact pattern boundary
    if isempty(priIndex)
        priIndex = numberOfPRIValues;
    end

    state.PRI_index = priIndex;

    state.PRI_s = priSet_s(priIndex);

    % Time since beginning of current PRI
    timeIntoPRI_s = ...
        timeInPattern_s - boundaries_s(priIndex);

    % Current pulse is active for pulse width
    state.pulse_active = ...
        timeIntoPRI_s < emitter.pulseWidth_s;

    % Pulse index within the repeating stagger pattern
    state.pulse_index = priIndex;

%% ============================================================
% E6 - Burst Communication
% =============================================================

elseif emitter.id == "E6"

    phase_s = mod(t_s, emitter.burstPeriod_s);

    state.active = ...
        phase_s < emitter.burstDuration_s;

    state.groundTruthActivity = state.active;

    state.pulse_active = state.active;

%% ============================================================
% E7 - Intermittent Communication
% =============================================================

elseif emitter.id == "E7"

    phase_s = mod(t_s, emitter.burstPeriod_s);

    state.active = ...
        phase_s < emitter.burstDuration_s;

    state.groundTruthActivity = state.active;

    state.pulse_active = state.active;

%% ============================================================
% E8 - Unknown / New Emitter
% =============================================================

elseif emitter.id == "E8"

    state.active = true;
    state.groundTruthActivity = true;

    state.PRI_s = emitter.PRI_s;

    pulsePosition_s = mod(t_s, emitter.PRI_s);

    state.pulse_active = ...
        pulsePosition_s < emitter.pulseWidth_s;

    state.pulse_index = ...
        floor(t_s / emitter.PRI_s) + 1;

end

end