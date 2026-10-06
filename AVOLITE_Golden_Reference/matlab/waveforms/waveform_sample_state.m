function pulseActive = waveform_sample_state( ...
    emitter, t_s, sampleRate_Hz)
%WAVEFORM_SAMPLE_STATE Determine discrete-time pulse state.
%
% Inputs:
%   emitter        - emitter definition
%   t_s            - sample time [s]
%   sampleRate_Hz  - waveform sample rate [Hz]
%
% Output:
%   pulseActive    - logical pulse/burst state
%
% Purpose:
%   Convert physical pulse timing into a discrete-time decision
%   while avoiding floating-point errors at exact boundaries.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if nargin ~= 3
    error( ...
        'waveform_sample_state:InvalidInput', ...
        ['Expected emitter, t_s, and sampleRate_Hz.']);
end

if ~isscalar(t_s) || ~isfinite(t_s)

    error( ...
        'waveform_sample_state:InvalidTime', ...
        't_s must be a finite scalar.');

end

if ~isscalar(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'waveform_sample_state:InvalidSampleRate', ...
        'sampleRate_Hz must be positive.');

end

%% ============================================================
% DISCRETE SAMPLE INDEX
% =============================================================

sampleIndex = round(t_s * sampleRate_Hz);

%% Reconstruct exact discrete sample time

t_sample_s = ...
    sampleIndex / sampleRate_Hz;

%% ============================================================
% DEFAULT STATE
% =============================================================

pulseActive = false;

%% ============================================================
% E1 - PERSISTENT RADAR
% =============================================================

if emitter.id == "E1"

    PRI_s = emitter.PRI_s;

    PRI_samples = ...
        round(PRI_s * sampleRate_Hz);

    pulseSamples = ...
        round(emitter.pulseWidth_s * sampleRate_Hz);

    if pulseSamples < 1
        pulseSamples = 1;
    end

    positionInPRI = ...
        mod(sampleIndex, PRI_samples);

    pulseActive = ...
        positionInPRI < pulseSamples;

%% ============================================================
% E2 - PERIODIC RADAR
% =============================================================

elseif emitter.id == "E2"

    %% Determine activity period using discrete time

    periodSamples = ...
        round(emitter.activity.period_s * ...
        sampleRate_Hz);

    activeSamples = ...
        round(emitter.activity.activeDuration_s * ...
        sampleRate_Hz);

    periodPosition = ...
        mod(sampleIndex, periodSamples);

    emitterActive = ...
        periodPosition < activeSamples;

    if emitterActive

        PRI_samples = ...
            round(emitter.PRI_s * sampleRate_Hz);

        pulseSamples = ...
            round(emitter.pulseWidth_s * sampleRate_Hz);

        if pulseSamples < 1
            pulseSamples = 1;
        end

        positionInPRI = ...
            mod(sampleIndex, PRI_samples);

        pulseActive = ...
            positionInPRI < pulseSamples;

    end

%% ============================================================
% E3 - INTERMITTENT RADAR
% =============================================================

elseif emitter.id == "E3"

    periodSamples = ...
        round(emitter.activity.period_s * ...
        sampleRate_Hz);

    activeSamples = ...
        round(emitter.activity.activeDuration_s * ...
        sampleRate_Hz);

    periodPosition = ...
        mod(sampleIndex, periodSamples);

    emitterActive = ...
        periodPosition < activeSamples;

    if emitterActive

        PRI_samples = ...
            round(emitter.PRI_s * sampleRate_Hz);

        pulseSamples = ...
            round(emitter.pulseWidth_s * sampleRate_Hz);

        if pulseSamples < 1
            pulseSamples = 1;
        end

        positionInPRI = ...
            mod(sampleIndex, PRI_samples);

        pulseActive = ...
            positionInPRI < pulseSamples;

    end

%% ============================================================
% E4 - FREQUENCY-AGILE RADAR
% =============================================================

elseif emitter.id == "E4"

    PRI_samples = ...
        round(emitter.PRI_s * sampleRate_Hz);

    pulseSamples = ...
        round(emitter.pulseWidth_s * sampleRate_Hz);

    if pulseSamples < 1
        pulseSamples = 1;
    end

    positionInPRI = ...
        mod(sampleIndex, PRI_samples);

    pulseActive = ...
        positionInPRI < pulseSamples;

%% ============================================================
% E5 - STAGGERED PRI RADAR
% =============================================================

elseif emitter.id == "E5"

    priSet_s = emitter.PRISet_s;

    %% Convert physical PRI values to integer sample counts

    priSamples = ...
        round(priSet_s * sampleRate_Hz);

    %% Pulse width in samples

    pulseSamples = ...
        round(emitter.pulseWidth_s * sampleRate_Hz);

    if pulseSamples < 1
        pulseSamples = 1;
    end

    %% Complete stagger pattern length

    patternSamples = ...
        sum(priSamples);

    %% Position within repeating pattern

    sampleInPattern = ...
        mod(sampleIndex, patternSamples);

    %% Cumulative PRI boundaries in samples

    boundaries = ...
        [0 cumsum(priSamples)];

    %% Determine current PRI interval

    priIndex = find( ...
        sampleInPattern >= boundaries(1:end-1) & ...
        sampleInPattern < boundaries(2:end), ...
        1, ...
        'first');

    %% Numerical protection at exact pattern boundary

    if isempty(priIndex)

        priIndex = length(priSamples);

    end

    %% Position within current PRI

    positionInPRI = ...
        sampleInPattern - boundaries(priIndex);

    %% Pulse decision

    pulseActive = ...
        positionInPRI < pulseSamples;

%% ============================================================
% E6 - BURST COMMUNICATION
% =============================================================

elseif emitter.id == "E6"

    periodSamples = ...
        round(emitter.burstPeriod_s * ...
        sampleRate_Hz);

    burstSamples = ...
        round(emitter.burstDuration_s * ...
        sampleRate_Hz);

    periodPosition = ...
        mod(sampleIndex, periodSamples);

    pulseActive = ...
        periodPosition < burstSamples;

%% ============================================================
% E7 - INTERMITTENT COMMUNICATION
% =============================================================

elseif emitter.id == "E7"

    periodSamples = ...
        round(emitter.burstPeriod_s * ...
        sampleRate_Hz);

    burstSamples = ...
        round(emitter.burstDuration_s * ...
        sampleRate_Hz);

    periodPosition = ...
        mod(sampleIndex, periodSamples);

    pulseActive = ...
        periodPosition < burstSamples;

%% ============================================================
% E8 - UNKNOWN / NEW EMITTER
% =============================================================

elseif emitter.id == "E8"

    PRI_samples = ...
        round(emitter.PRI_s * sampleRate_Hz);

    pulseSamples = ...
        round(emitter.pulseWidth_s * sampleRate_Hz);

    if pulseSamples < 1
        pulseSamples = 1;
    end

    positionInPRI = ...
        mod(sampleIndex, PRI_samples);

    pulseActive = ...
        positionInPRI < pulseSamples;

else

    error( ...
        'waveform_sample_state:UnknownEmitter', ...
        'Unknown emitter ID: %s', emitter.id);

end

end