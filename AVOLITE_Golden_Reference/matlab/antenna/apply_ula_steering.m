function x_array = apply_ula_steering( ...
    x_waveform, ...
    array, ...
    frequency_Hz, ...
    azimuth_rad)
%APPLY_ULA_STEERING Apply ULA spatial phase response to a waveform.
%
% Inputs:
%   x_waveform    : Nx1 complex-envelope waveform
%   array         : ULA geometry structure
%   frequency_Hz  : emitter RF frequency
%   azimuth_rad   : emitter azimuth
%
% Output:
%   x_array       : NxM array-received signal
%                   N = time samples
%                   M = antenna elements
%
% The output contains only the spatial steering effect.
% Propagation amplitude, noise, interference, receiver gain,
% and ADC effects are handled by later models.

%% ------------------------------------------------------------
% INPUT VALIDATION
% ------------------------------------------------------------

if ~isvector(x_waveform) || isempty(x_waveform)
    error( ...
        'apply_ula_steering:InvalidWaveform', ...
        'x_waveform must be a non-empty vector.');
end

if ~isfield(array,'numberOfElements') || ...
        ~isfield(array,'position_m')

    error( ...
        'apply_ula_steering:InvalidArray', ...
        'array must contain numberOfElements and position_m.');
end

if size(array.position_m,1) ~= array.numberOfElements
    error( ...
        'apply_ula_steering:ArraySizeMismatch', ...
        'Array position count does not match numberOfElements.');
end

%% ------------------------------------------------------------
% CONVERT WAVEFORM TO COLUMN VECTOR
% ------------------------------------------------------------

x_waveform = x_waveform(:);

numberOfSamples = length(x_waveform);

numberOfElements = array.numberOfElements;

%% ------------------------------------------------------------
% CALCULATE STEERING VECTOR
% ------------------------------------------------------------

a = ula_steering_vector( ...
    array, ...
    frequency_Hz, ...
    azimuth_rad);

%% ------------------------------------------------------------
% APPLY SPATIAL RESPONSE
% ------------------------------------------------------------

% Each time sample is multiplied by the spatial steering
% vector. The result is:
%
%       x_array[n,m] = x_waveform[n] * a[m]
%
% Therefore:
%
%       size(x_array) = samples x antenna elements

x_array = x_waveform * transpose(a);

%% ------------------------------------------------------------
% OUTPUT VALIDATION
% ------------------------------------------------------------

if size(x_array,1) ~= numberOfSamples
    error( ...
        'apply_ula_steering:OutputSampleMismatch', ...
        'Unexpected output sample count.');
end

if size(x_array,2) ~= numberOfElements
    error( ...
        'apply_ula_steering:OutputElementMismatch', ...
        'Unexpected output element count.');
end

end