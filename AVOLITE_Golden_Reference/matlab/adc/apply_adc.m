function [y, info] = apply_adc(x, cfg)
%APPLY_ADC Ideal complex-baseband ADC model.
%
% Inputs:
%   x   - complex analog/baseband voltage samples [V]
%   cfg - AVOLITE configuration structure
%
% Outputs:
%   y    - quantized complex ADC output [V]
%   info - ADC diagnostics and parameters
%
% Convention:
%   ADC full-scale voltage is 1 V peak-to-peak.
%   Therefore each real component has range:
%       -0.5 V <= I,Q <= +0.5 V
%
%   I and Q are quantized independently.
%
% This is an ideal quantizer model. It does not model:
%   aperture jitter
%   thermal ADC noise
%   INL
%   DNL
%   clock jitter
%   converter-specific architecture.

%% Validate configuration

requiredFields = { ...
    'adcSampleRate_Hz', ...
    'adcBits', ...
    'adcFullScale_V'};

for k = 1:numel(requiredFields)

    if ~isfield(cfg.receiver, requiredFields{k})
        error('apply_adc:MissingConfiguration', ...
            'Missing cfg.receiver.%s', requiredFields{k});
    end

end

%% ADC parameters

sampleRate_Hz = cfg.receiver.adcSampleRate_Hz;
bits = cfg.receiver.adcBits;
fullScale_V = cfg.receiver.adcFullScale_V;

if sampleRate_Hz <= 0
    error('apply_adc:InvalidSampleRate', ...
        'ADC sample rate must be positive.');
end

if bits < 1 || bits ~= floor(bits)
    error('apply_adc:InvalidResolution', ...
        'ADC resolution must be a positive integer.');
end

if fullScale_V <= 0
    error('apply_adc:InvalidFullScale', ...
        'ADC full-scale voltage must be positive.');
end

%% Quantizer parameters

numberOfLevels = 2^bits;

minVoltage_V = -fullScale_V / 2;
maxVoltage_V =  fullScale_V / 2;

quantizationStep_V = ...
    fullScale_V / numberOfLevels;

%% Preserve input shape

originalSize = size(x);

x = x(:);

%% Separate I and Q

iInput = real(x);
qInput = imag(x);

%% Clip to ADC range

iClipped = min(max(iInput, minVoltage_V), maxVoltage_V);
qClipped = min(max(qInput, minVoltage_V), maxVoltage_V);

%% Quantize

iCode = floor((iClipped - minVoltage_V) / ...
    quantizationStep_V);

qCode = floor((qClipped - minVoltage_V) / ...
    quantizationStep_V);

%% Protect upper boundary

iCode = min(iCode, numberOfLevels - 1);
qCode = min(qCode, numberOfLevels - 1);

%% Convert code back to quantized voltage

iQuantized = ...
    minVoltage_V + ...
    (iCode + 0.5) * quantizationStep_V;

qQuantized = ...
    minVoltage_V + ...
    (qCode + 0.5) * quantizationStep_V;

%% Reconstruct complex output

y = complex(iQuantized, qQuantized);

y = reshape(y, originalSize);

%% Diagnostics

info = struct();

info.sampleRate_Hz = sampleRate_Hz;
info.bits = bits;
info.fullScale_V = fullScale_V;

info.numberOfLevels = numberOfLevels;

info.minVoltage_V = minVoltage_V;
info.maxVoltage_V = maxVoltage_V;

info.quantizationStep_V = quantizationStep_V;

info.inputPeak_V = max(abs(x));

info.inputI_Min_V = min(iInput);
info.inputI_Max_V = max(iInput);

info.inputQ_Min_V = min(qInput);
info.inputQ_Max_V = max(qInput);

info.clippedI_Count = ...
    sum(iInput < minVoltage_V | iInput > maxVoltage_V);

info.clippedQ_Count = ...
    sum(qInput < minVoltage_V | qInput > maxVoltage_V);

info.totalClippedSamples = ...
    info.clippedI_Count + info.clippedQ_Count;

info.clippingOccurred = ...
    info.totalClippedSamples > 0;

end