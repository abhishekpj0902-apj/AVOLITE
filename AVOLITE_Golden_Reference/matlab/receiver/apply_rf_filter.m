function [x_out, filterInfo] = apply_rf_filter( ...
    x_in, ...
    sampleRate_Hz, ...
    cfg)
%APPLY_RF_FILTER Apply complex-envelope RF channel filter.
%
% Inputs:
%   x_in          : complex-envelope input signal
%   sampleRate_Hz : signal sample rate
%   cfg           : AVOLITE configuration
%
% Outputs:
%   x_out         : filtered complex-envelope signal
%   filterInfo    : filter configuration and coefficients
%
% The RF filter is represented as a digital equivalent low-pass
% channel filter around the selected RF channel.
%
% This stage does not model:
%   - receiver gain
%   - receiver noise
%   - mixer
%   - LO
%   - ADC
%
% Those effects are handled separately.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if isempty(x_in) || ~isnumeric(x_in)
    error( ...
        'apply_rf_filter:InvalidInput', ...
        'x_in must be a non-empty numeric signal.');
end

if ~isscalar(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'apply_rf_filter:InvalidSampleRate', ...
        'sampleRate_Hz must be positive.');
end

if ~isfield(cfg,'receiver') || ...
        ~isfield(cfg.receiver,'rfFilterBandwidth_Hz')

    error( ...
        'apply_rf_filter:MissingBandwidth', ...
        'RF filter bandwidth configuration is missing.');
end

bandwidth_Hz = cfg.receiver.rfFilterBandwidth_Hz;

if ~isscalar(bandwidth_Hz) || ...
        ~isfinite(bandwidth_Hz) || ...
        bandwidth_Hz <= 0

    error( ...
        'apply_rf_filter:InvalidBandwidth', ...
        'RF filter bandwidth must be positive.');
end

%% ============================================================
% NYQUIST CHECK
% =============================================================

nyquist_Hz = sampleRate_Hz / 2;

if bandwidth_Hz >= nyquist_Hz
    error( ...
        'apply_rf_filter:BandwidthExceedsNyquist', ...
        ['RF filter bandwidth must be less than the ' ...
         'Nyquist frequency for this digital reference model.']);
end

%% ============================================================
% FILTER DESIGN
% =============================================================

filterOrder = 64;

% The configured RF bandwidth is treated as the
% two-sided equivalent channel bandwidth.
%
% For the complex-envelope low-pass representation,
% the cutoff is half the channel bandwidth.

cutoffFrequency_Hz = bandwidth_Hz / 2;

normalizedCutoff = ...
    cutoffFrequency_Hz / nyquist_Hz;

% FIR low-pass filter using a Hann window.

b = fir1( ...
    filterOrder, ...
    normalizedCutoff, ...
    "low", ...
    hann(filterOrder + 1));

%% ============================================================
% FILTER SIGNAL
% =============================================================

x_column = x_in(:);

x_filtered = filter(b, 1, x_column);

%% ============================================================
% RESTORE INPUT ORIENTATION
% =============================================================

if isrow(x_in)
    x_out = transpose(x_filtered);
else
    x_out = x_filtered;
end

%% ============================================================
% FILTER INFORMATION
% =============================================================

filterInfo.type = "FIR lowpass";
filterInfo.order = filterOrder;
filterInfo.bandwidth_Hz = bandwidth_Hz;
filterInfo.cutoffFrequency_Hz = cutoffFrequency_Hz;
filterInfo.sampleRate_Hz = sampleRate_Hz;
filterInfo.normalizedCutoff = normalizedCutoff;
filterInfo.coefficients = b;

end