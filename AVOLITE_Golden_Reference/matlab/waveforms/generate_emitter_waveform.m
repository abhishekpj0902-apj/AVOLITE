function [x, metadata] = generate_emitter_waveform( ...
    emitter, t_s, sampleRate_Hz)
%GENERATE_EMITTER_WAVEFORM Generate normalized complex-envelope waveform.
%
% Inputs:
%   emitter        - emitter definition from emitter_model()
%   t_s            - time vector [s]
%   sampleRate_Hz  - waveform sample rate [Hz]
%
% Outputs:
%   x              - normalized complex-envelope waveform
%   metadata       - waveform physical metadata
%
% Representation:
%   x(n) = 1 + 0j during an active pulse/burst
%   x(n) = 0 + 0j otherwise
%
% The actual RF carrier frequency is NOT directly sampled.
% It is stored in metadata.frequency_Hz.
%
% This is the AVOLITE Golden Reference complex-envelope model.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if nargin ~= 3
    error( ...
        'generate_emitter_waveform:InvalidInput', ...
        ['Expected three inputs: emitter, t_s, ', ...
         'sampleRate_Hz.']);
end

if isempty(t_s)
    error( ...
        'generate_emitter_waveform:EmptyTimeVector', ...
        'Time vector t_s cannot be empty.');
end

if ~isscalar(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'generate_emitter_waveform:InvalidSampleRate', ...
        'sampleRate_Hz must be a positive finite scalar.');

end

%% ============================================================
% TIME VECTOR
% =============================================================

t_s = t_s(:);

N = length(t_s);

%% Verify monotonic time vector

if N > 1

    dt = diff(t_s);

    if any(dt <= 0)

        error( ...
            'generate_emitter_waveform:InvalidTimeVector', ...
            't_s must be strictly increasing.');

    end

end

%% Verify consistency between time vector and sample rate

if N > 1

    measuredSampleRate_Hz = ...
        1 / mean(diff(t_s));

    relativeError = ...
        abs(measuredSampleRate_Hz - sampleRate_Hz) ...
        / sampleRate_Hz;

    if relativeError > 1e-9

        error( ...
            'generate_emitter_waveform:SampleRateMismatch', ...
            ['Time vector sample spacing does not match ', ...
             'sampleRate_Hz.']);

    end

end

%% ============================================================
% INITIALIZE COMPLEX-ENVELOPE WAVEFORM
% =============================================================

x = complex(zeros(N,1));

%% ============================================================
% METADATA
% =============================================================

metadata.id = emitter.id;

metadata.name = emitter.name;

metadata.type = emitter.type;

metadata.frequency_Hz = ...
    zeros(N,1);

metadata.power_W = ...
    emitter.power_W * ones(N,1);

metadata.pulse_active = ...
    false(N,1);

metadata.sampleCount = N;

metadata.sampleRate_Hz = sampleRate_Hz;

metadata.timeStep_s = ...
    1 / sampleRate_Hz;

metadata.startTime_s = ...
    t_s(1);

metadata.endTime_s = ...
    t_s(end);

%% ============================================================
% GENERATE WAVEFORM
% =============================================================

for n = 1:N

    %% --------------------------------------------------------
    % Ground-truth emitter state
    % ---------------------------------------------------------

    state = emitter_state( ...
        emitter, ...
        t_s(n));

    %% --------------------------------------------------------
    % Physical RF frequency
    % ---------------------------------------------------------

    metadata.frequency_Hz(n) = ...
        state.frequency_Hz;

    %% --------------------------------------------------------
    % Discrete-time pulse decision
    % ---------------------------------------------------------

    metadata.pulse_active(n) = ...
        waveform_sample_state( ...
            emitter, ...
            t_s(n), ...
            sampleRate_Hz);

    %% --------------------------------------------------------
    % Normalized complex envelope
    % ---------------------------------------------------------

    if metadata.pulse_active(n)

        x(n) = complex(1,0);

    else

        x(n) = complex(0,0);

    end

end

%% ============================================================
% ADDITIONAL METADATA
% =============================================================

metadata.activeSampleCount = ...
    nnz(metadata.pulse_active);

metadata.dutyCycle = ...
    metadata.activeSampleCount / N;

end