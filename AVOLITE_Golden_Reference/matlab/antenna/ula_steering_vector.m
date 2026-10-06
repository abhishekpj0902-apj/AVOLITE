function a = ula_steering_vector( ...
    array, ...
    frequency_Hz, ...
    azimuth_rad)
%ULA_STEERING_VECTOR Calculate ULA plane-wave steering vector.
%
% Inputs:
%   array        - ULA geometry structure
%   frequency_Hz - RF frequency [Hz]
%   azimuth_rad  - arrival azimuth [rad]
%
% Output:
%   a            - normalized complex steering vector [N x 1]
%
% Model:
%
%   lambda = c / f
%
%   k = 2*pi/lambda
%
%   phase_m = k*x_m*sin(theta)
%
%   a_m = exp(-j*phase_m)

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isscalar(frequency_Hz) || ...
        ~isfinite(frequency_Hz) || ...
        frequency_Hz <= 0

    error( ...
        'ula_steering_vector:InvalidFrequency', ...
        'frequency_Hz must be positive.');

end

if ~isscalar(azimuth_rad) || ...
        ~isfinite(azimuth_rad)

    error( ...
        'ula_steering_vector:InvalidAzimuth', ...
        'azimuth_rad must be finite.');

end

%% ============================================================
% CONSTANT
% =============================================================

c_mps = 299792458;

%% ============================================================
% WAVELENGTH
% =============================================================

lambda_m = ...
    c_mps / frequency_Hz;

%% ============================================================
% WAVE NUMBER
% =============================================================

k_rad_per_m = ...
    2*pi / lambda_m;

%% ============================================================
% ELEMENT POSITIONS
% =============================================================

x_m = array.position_m(:,1);

%% ============================================================
% SPATIAL PHASE
% =============================================================

phase_rad = ...
    k_rad_per_m .* x_m .* sin(azimuth_rad);

%% ============================================================
% STEERING VECTOR
% =============================================================

a = exp(-1j * phase_rad);

%% ============================================================
% NORMALIZATION
% =============================================================

a = a / sqrt(array.numberOfElements);

end