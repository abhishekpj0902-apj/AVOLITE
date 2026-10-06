function [t_s, x, metadata] = generate_emitter_waveform( ...
    emitterID, startTime_s, duration_s, sampleRate_Hz)
%GENERATE_EMITTER_WAVEFORM Generate AVOLITE emitter waveform.
%
% Inputs:
%   emitterID       : Emitter number 1...8
%   startTime_s     : Absolute simulation start time [s]
%   duration_s      : Waveform duration [s]
%   sampleRate_Hz   : Complex-envelope sample rate [Hz]
%
% Outputs:
%   t_s             : Absolute time vector [s]
%   x               : Complex-envelope waveform
%   metadata        : Ground-truth waveform information
%
% The RF carrier frequency is represented in metadata and through
% the complex-envelope phase where appropriate.
%
% MATLAB R2025b

arguments
    emitterID (1,1) double ...
        {mustBeInteger,mustBeInRange(emitterID,1,8)}

    startTime_s (1,1) double ...
        {mustBeNonnegative}

    duration_s (1,1) double ...
        {mustBePositive}

    sampleRate_Hz (1,1) double ...
        {mustBePositive}
end

%% Emitter configuration
emitter = emitter_model(emitterID);

%% Number of samples
numberOfSamples = floor(duration_s * sampleRate_Hz) + 1;

%% Relative and absolute time
t_relative_s = (0:numberOfSamples-1).' / sampleRate_Hz;

t_s = startTime_s + t_relative_s;

%% Initialize waveform
x = complex(zeros(numberOfSamples,1));

%% Initialize metadata
metadata.emitterID = emitterID;
metadata.name = emitter.name;
metadata.type = emitter.type;

metadata.carrierFrequency_Hz = ...
    emitter.rf.frequency_Hz;

metadata.sampleRate_Hz = sampleRate_Hz;

metadata.startTime_s = startTime_s;
metadata.duration_s = duration_s;

metadata.active = false(numberOfSamples,1);
metadata.frequency_Hz = ...
    zeros(numberOfSamples,1);

metadata.pulse_active = ...
    false(numberOfSamples,1);

%% Generate sample-by-sample ground-truth state
for n = 1:numberOfSamples

    state = emitter_state( ...
        emitterID, ...
        t_s(n));

    metadata.active(n) = state.active;

    metadata.frequency_Hz(n) = ...
        state.frequency_Hz;

    metadata.pulse_active(n) = ...
        state.pulse_active;
%% Generate complex-envelope signal
if state.active

    switch emitterID

        case {1,2,3,4,5}

            % Radar pulse envelope
            if state.pulse_active
                x(n) = 1 + 0j;
            end

        case {6,7}

            % Communication burst envelope
            if state.active
                x(n) = 1 + 0j;
            end

        case 8

            % Unknown/new emitter baseline envelope
            if state.active
                x(n) = 1 + 0j;
            end

    end

end

%% Normalize waveform
maxAmplitude = max(abs(x));

if maxAmplitude > 0
    x = x ./ maxAmplitude;
end

metadata.peakAmplitude = max(abs(x));
metadata.rmsAmplitude = rms(abs(x));

end