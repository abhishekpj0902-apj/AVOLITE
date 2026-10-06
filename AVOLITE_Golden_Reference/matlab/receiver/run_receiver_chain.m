function [y_adc, chain] = run_receiver_chain(x_array, cfg)
%RUN_RECEIVER_CHAIN Golden-reference adaptive RF receiver chain.
%
% Chain:
%   Antenna signal
%       -> Receiver gain
%       -> RF filter
%       -> Receiver noise
%       -> ADC
%
% This function operates on complex-envelope/baseband samples.
%
% No DSP detection or AI behavior is included here.

%% Validate input

if ~isnumeric(x_array)
    error('run_receiver_chain:InvalidInput', ...
        'Input antenna signal must be numeric.');
end

%% Receiver gain

[x_gain, gainInfo] = apply_receiver_gain(x_array, cfg);

%% RF filtering

[x_filtered, filterInfo] = apply_rf_filter( ...
    x_gain, ...
    cfg.receiver.adcSampleRate_Hz, ...
    cfg);

%% Receiver noise

noiseInfo = calculate_receiver_noise(cfg);

%% Add receiver noise

% Receiver noise is calculated as power [W].
% Convert to RMS voltage using the receiver reference impedance.

referenceImpedance_ohm = ...
    cfg.receiver.referenceImpedance_ohm;

noisePower_W = noiseInfo.outputNoisePower_W;

noiseRMS_V = sqrt( ...
    noisePower_W * ...
    referenceImpedance_ohm);

% For circular complex Gaussian noise:
%
% E{|n|^2} = noiseRMS_V^2
%
% Therefore:
%
% variance(I) = variance(Q) = noiseRMS_V^2 / 2

noiseSamples = sqrt(noiseRMS_V^2 / 2) .* ...
    (randn(size(x_filtered)) + ...
     1j * randn(size(x_filtered)));

x_noisy = x_filtered + noiseSamples;

chain.noiseSamples = noiseSamples;chain.noiseRMS_V = noiseRMS_V;
chain.referenceImpedance_ohm = referenceImpedance_ohm;

%% ADC

[y_adc, adcInfo] = apply_adc(x_noisy, cfg);

%% Diagnostic information

chain = struct();

chain.gain = gainInfo;
chain.filter = filterInfo;
chain.noise = noiseInfo;
chain.adc = adcInfo;

chain.input = x_array;
chain.afterGain = x_gain;
chain.afterFilter = x_filtered;
chain.afterNoise = x_noisy;
chain.output = y_adc;

chain.noiseSamples = noiseSamples;
chain.noiseRMS_V = noiseRMS_V;
chain.referenceImpedance_ohm = referenceImpedance_ohm;

end