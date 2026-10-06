function propagation = free_space_propagation( ...
    emitter, ...
    range_m, ...
    cfg)
%FREE_SPACE_PROPAGATION Free-space RF propagation model.
%
% Inputs:
%   emitter  - emitter definition
%   range_m  - transmitter-to-receiver distance [m]
%   cfg      - AVOLITE configuration
%
% Output:
%   propagation - propagation results

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isscalar(range_m) || ...
        ~isfinite(range_m) || ...
        range_m <= 0

    error( ...
        'free_space_propagation:InvalidRange', ...
        'range_m must be a positive finite scalar.');

end

%% ============================================================
% FREQUENCY
% =============================================================

frequency_Hz = emitter.frequency_Hz;

if frequency_Hz <= 0

    error( ...
        'free_space_propagation:InvalidFrequency', ...
        'Emitter frequency must be positive.');

end

%% ============================================================
% PHYSICAL CONSTANT
% =============================================================

c_mps = cfg.constants.c_mps;

%% ============================================================
% WAVELENGTH
% =============================================================

lambda_m = ...
    c_mps / frequency_Hz;

%% ============================================================
% FREE-SPACE PATH LOSS
% =============================================================

pathLoss_linear = ...
    (4*pi*range_m/lambda_m)^2;

pathLoss_dB = ...
    10*log10(pathLoss_linear);

%% ============================================================
% FRIIS RECEIVED POWER
% =============================================================

Pt_W = emitter.power_W;

Gt_linear = 1;

Gr_linear = 1;

Lsys_linear = ...
    cfg.propagation.systemLoss_linear;

Pr_W = ...
    Pt_W * ...
    Gt_linear * ...
    Gr_linear * ...
    (lambda_m/(4*pi*range_m))^2 * ...
    Lsys_linear;

%% ============================================================
% OUTPUT
% =============================================================

propagation.emitterID = emitter.id;

propagation.frequency_Hz = frequency_Hz;

propagation.range_m = range_m;

propagation.wavelength_m = lambda_m;

propagation.transmitPower_W = Pt_W;

propagation.pathLoss_linear = pathLoss_linear;

propagation.pathLoss_dB = pathLoss_dB;

propagation.receivedPower_W = Pr_W;

propagation.receivedPower_dBm = ...
    10*log10(Pr_W/1e-3);

propagation.transmitGain_linear = Gt_linear;

propagation.receiveGain_linear = Gr_linear;

propagation.systemLoss_linear = Lsys_linear;

end