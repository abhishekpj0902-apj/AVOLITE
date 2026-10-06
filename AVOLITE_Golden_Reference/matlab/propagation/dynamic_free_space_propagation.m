function propagation = dynamic_free_space_propagation( ...
    emitter, range_m, t_s, cfg)
%DYNAMIC_FREE_SPACE_PROPAGATION
% Time-varying free-space propagation using emitter ground truth.
%
% Inputs:
%   emitter  - emitter definition
%   range_m  - emitter-receiver range [m]
%   t_s      - time [s]
%   cfg      - AVOLITE configuration
%
% Output:
%   propagation - time-dependent propagation state

%% Input validation

if ~isscalar(range_m) || ...
        ~isfinite(range_m) || ...
        range_m <= 0

    error( ...
        'dynamic_free_space_propagation:InvalidRange', ...
        'range_m must be positive.');

end

if ~isscalar(t_s) || ...
        ~isfinite(t_s) || ...
        t_s < 0

    error( ...
        'dynamic_free_space_propagation:InvalidTime', ...
        't_s must be a non-negative finite scalar.');

end

%% Obtain time-dependent emitter state

state = emitter_state(emitter,t_s);

%% Physical constants

c_mps = cfg.constants.c_mps;

%% Time-dependent frequency

frequency_Hz = state.frequency_Hz;

%% Wavelength

lambda_m = ...
    c_mps / frequency_Hz;

%% Free-space path loss

pathLoss_linear = ...
    (4*pi*range_m/lambda_m)^2;

pathLoss_dB = ...
    10*log10(pathLoss_linear);

%% Received power

Pt_W = state.power_W;

Gt_linear = 1;
Gr_linear = 1;
Lsys_linear = cfg.propagation.systemLoss_linear;

Pr_W = ...
    Pt_W * ...
    Gt_linear * ...
    Gr_linear * ...
    (lambda_m/(4*pi*range_m))^2 * ...
    Lsys_linear;

%% Output

propagation.emitterID = state.id;

propagation.time_s = t_s;

propagation.active = state.active;

propagation.pulse_active = state.pulse_active;

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