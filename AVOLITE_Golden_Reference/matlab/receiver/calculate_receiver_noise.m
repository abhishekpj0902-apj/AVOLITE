function noise = calculate_receiver_noise(cfg)
%CALCULATE_RECEIVER_NOISE Calculate receiver thermal noise.
%
% Calculates:
%   - thermal noise power
%   - receiver noise factor
%   - equivalent input-referred noise power
%   - equivalent output-referred noise power
%
% Noise model:
%
%   P_thermal = k*T*B
%
%   F = 10^(NF_dB/10)
%
%   P_total_input = k*T*B*F
%
%   P_total_output = P_total_input*G
%
% This function performs deterministic noise-power calculations.
% Random noise generation is handled separately.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isfield(cfg,'constants') || ...
        ~isfield(cfg.constants,'k_B_J_per_K')

    error( ...
        'calculate_receiver_noise:MissingBoltzmann', ...
        'Boltzmann constant is missing.');
end

if ~isfield(cfg,'receiver')
    error( ...
        'calculate_receiver_noise:MissingReceiver', ...
        'Receiver configuration is missing.');
end

requiredFields = {
    'temperature_K'
    'noiseFigure_dB'
    'rfFilterBandwidth_Hz'
    'gain_dB'
    };

for k = 1:length(requiredFields)

    if ~isfield(cfg.receiver,requiredFields{k})

        error( ...
            'calculate_receiver_noise:MissingField', ...
            'Missing receiver field: %s', ...
            requiredFields{k});

    end

end

%% ============================================================
% PARAMETERS
% =============================================================

k_B = cfg.constants.k_B_J_per_K;

T_K = cfg.receiver.temperature_K;

NF_dB = cfg.receiver.noiseFigure_dB;

B_Hz = cfg.receiver.rfFilterBandwidth_Hz;

G_dB = cfg.receiver.gain_dB;

if T_K <= 0
    error( ...
        'calculate_receiver_noise:InvalidTemperature', ...
        'Receiver temperature must be positive.');
end

if B_Hz <= 0
    error( ...
        'calculate_receiver_noise:InvalidBandwidth', ...
        'Noise bandwidth must be positive.');
end

%% ============================================================
% THERMAL NOISE
% =============================================================

P_thermal_W = ...
    k_B * T_K * B_Hz;

%% ============================================================
% NOISE FACTOR
% =============================================================

F_linear = ...
    10^(NF_dB/10);

%% ============================================================
% INPUT-REFERRED TOTAL NOISE
% =============================================================

P_noise_input_W = ...
    P_thermal_W * F_linear;

%% ============================================================
% RECEIVER POWER GAIN
% =============================================================

G_linear = ...
    10^(G_dB/10);

%% ============================================================
% OUTPUT-REFERRED NOISE
% =============================================================

P_noise_output_W = ...
    P_noise_input_W * G_linear;

%% ============================================================
% dBm CONVERSION
% =============================================================

noise.inputThermalPower_W = ...
    P_thermal_W;

noise.inputThermalPower_dBm = ...
    10*log10(P_thermal_W/1e-3);

noise.noiseFigure_dB = ...
    NF_dB;

noise.noiseFactor_linear = ...
    F_linear;

noise.inputNoisePower_W = ...
    P_noise_input_W;

noise.inputNoisePower_dBm = ...
    10*log10(P_noise_input_W/1e-3);

noise.gain_dB = ...
    G_dB;

noise.gain_linear = ...
    G_linear;

noise.outputNoisePower_W = ...
    P_noise_output_W;

noise.outputNoisePower_dBm = ...
    10*log10(P_noise_output_W/1e-3);

noise.temperature_K = ...
    T_K;

noise.bandwidth_Hz = ...
    B_Hz;

end