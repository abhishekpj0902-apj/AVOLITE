function [x_out, receiver] = apply_receiver_gain(x_in, cfg)
%APPLY_RECEIVER_GAIN Apply configurable receiver gain to a complex signal.
%
% Inputs:
%   x_in : complex-envelope input signal
%   cfg  : AVOLITE configuration
%
% Outputs:
%   x_out    : gain-scaled complex-envelope signal
%   receiver : receiver gain information
%
% This stage models gain only.
% Noise, filtering, mixing, and ADC are handled separately.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if isempty(x_in) || ~isnumeric(x_in)
    error( ...
        'apply_receiver_gain:InvalidInput', ...
        'x_in must be a non-empty numeric signal.');
end

if ~isfield(cfg,'receiver') || ...
        ~isfield(cfg.receiver,'gain_dB')

    error( ...
        'apply_receiver_gain:MissingGain', ...
        'Receiver gain configuration is missing.');
end

gain_dB = cfg.receiver.gain_dB;

if ~isscalar(gain_dB) || ~isfinite(gain_dB)
    error( ...
        'apply_receiver_gain:InvalidGain', ...
        'Receiver gain must be finite scalar.');
end

%% ============================================================
% GAIN CALCULATION
% =============================================================

gain_linear_power = 10^(gain_dB / 10);

gain_linear_amplitude = 10^(gain_dB / 20);

%% ============================================================
% APPLY AMPLITUDE GAIN
% =============================================================

x_out = x_in .* gain_linear_amplitude;

%% ============================================================
% RECEIVER INFORMATION
% =============================================================

receiver.gain_dB = gain_dB;

receiver.gain_linear_power = ...
    gain_linear_power;

receiver.gain_linear_amplitude = ...
    gain_linear_amplitude;

end