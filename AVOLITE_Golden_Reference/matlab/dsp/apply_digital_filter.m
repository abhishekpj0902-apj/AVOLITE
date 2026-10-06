function [y, info] = apply_digital_filter(x, sampleRate_Hz, cfg)
%APPLY_DIGITAL_FILTER Apply configured digital low-pass filter.
%
% AVOLITE Golden Reference
%
% Inputs:
%   x               : complex digital input signal
%   sampleRate_Hz   : input sample rate [Hz]
%   cfg             : AVOLITE configuration
%
% Outputs:
%   y               : filtered output signal
%   info            : filter diagnostics
%
% Processing:
%
%   Input signal
%       |
%       v
%   FIR low-pass filter
%       |
%       v
%   Filtered signal
%
% The filter configuration is taken from:
%
%   cfg.dsp.filter
%
% Current Golden Reference configuration:
%
%   Type       = lowpass
%   Cutoff     = 5 MHz
%   Order      = 64
%
% No decimation is performed.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if isempty(x) || ~isnumeric(x)

    error( ...
        'apply_digital_filter:InvalidInput', ...
        'Input signal must be a non-empty numeric signal.');

end

%% ============================================================
% SAMPLE RATE VALIDATION
% =============================================================

if ~isscalar(sampleRate_Hz) || ...
        ~isnumeric(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'apply_digital_filter:InvalidSampleRate', ...
        'sampleRate_Hz must be a positive finite scalar.');

end

%% ============================================================
% CONFIGURATION VALIDATION
% =============================================================

if ~isstruct(cfg)

    error( ...
        'apply_digital_filter:InvalidConfiguration', ...
        'cfg must be a structure.');

end

if ~isfield(cfg,'dsp') || ...
        ~isstruct(cfg.dsp) || ...
        ~isfield(cfg.dsp,'filter')

    error( ...
        'apply_digital_filter:MissingConfiguration', ...
        'Digital filter configuration is missing.');

end

filterCfg = cfg.dsp.filter;

%% ============================================================
% ENABLE CHECK
% =============================================================

if ~isfield(filterCfg,'enable')

    error( ...
        'apply_digital_filter:MissingEnable', ...
        'Digital filter enable configuration is missing.');

end

if ~filterCfg.enable

    y = x;

    info = struct();

    info.enabled = false;
    info.filterType = "bypass";
    info.inputSampleRate_Hz = sampleRate_Hz;
    info.outputSampleRate_Hz = sampleRate_Hz;
    info.inputSamples = numel(x);
    info.outputSamples = numel(y);
    info.decimationEnabled = false;
    info.decimationFactor = 1;

    return;

end

%% ============================================================
% FILTER TYPE
% =============================================================

if ~isfield(filterCfg,'type')

    error( ...
        'apply_digital_filter:MissingType', ...
        'Digital filter type is missing.');

end

filterType = string(filterCfg.type);

if lower(filterType) ~= "lowpass"

    error( ...
        'apply_digital_filter:UnsupportedType', ...
        'Only lowpass filtering is currently supported.');

end

%% ============================================================
% CUTOFF FREQUENCY
% =============================================================

if ~isfield(filterCfg,'cutoffFrequency_Hz')

    error( ...
        'apply_digital_filter:MissingCutoff', ...
        'Digital filter cutoff frequency is missing.');

end

cutoffFrequency_Hz = ...
    filterCfg.cutoffFrequency_Hz;

%% ============================================================
% CUTOFF VALIDATION
% =============================================================

nyquist_Hz = sampleRate_Hz / 2;

if ~isscalar(cutoffFrequency_Hz) || ...
        ~isnumeric(cutoffFrequency_Hz) || ...
        ~isfinite(cutoffFrequency_Hz) || ...
        cutoffFrequency_Hz <= 0

    error( ...
        'apply_digital_filter:InvalidCutoff', ...
        'Cutoff frequency must be a positive finite scalar.');

end

if cutoffFrequency_Hz >= nyquist_Hz

    error( ...
        'apply_digital_filter:InvalidCutoff', ...
        ['Cutoff frequency must be smaller than ' ...
         'the Nyquist frequency.']);

end

%% ============================================================
% FILTER ORDER
% =============================================================

if ~isfield(filterCfg,'order')

    error( ...
        'apply_digital_filter:MissingOrder', ...
        'Digital filter order is missing.');

end

filterOrder = filterCfg.order;

if ~isscalar(filterOrder) || ...
        ~isnumeric(filterOrder) || ...
        ~isfinite(filterOrder) || ...
        filterOrder < 1 || ...
        filterOrder ~= floor(filterOrder)

    error( ...
        'apply_digital_filter:InvalidOrder', ...
        'Digital filter order must be a positive integer.');

end

%% ============================================================
% PRESERVE INPUT ORIENTATION
% =============================================================

inputWasRow = isrow(x);

x_column = x(:);

N = numel(x_column);

%% ============================================================
% NORMALIZED CUTOFF
% ============================================================

normalizedCutoff = ...
    cutoffFrequency_Hz / nyquist_Hz;

if normalizedCutoff <= 0 || ...
        normalizedCutoff >= 1

    error( ...
        'apply_digital_filter:InvalidNormalizedCutoff', ...
        'Normalized cutoff must be between zero and one.');

end

%% ============================================================
% FIR FILTER DESIGN
% ============================================================
%
% Hann-windowed FIR.
%
% The cutoff frequency is the -6 dB-style FIR design
% transition reference generated by fir1.

window = hann(filterOrder + 1);

b = fir1( ...
    filterOrder, ...
    normalizedCutoff, ...
    "low", ...
    window);

%% ============================================================
% FILTER
% =============================================================

y_column = filter( ...
    b, ...
    1, ...
    x_column);

%% ============================================================
% RESTORE INPUT ORIENTATION
% =============================================================

if inputWasRow

    y = transpose(y_column);

else

    y = y_column;

end

%% ============================================================
% FILTER INFORMATION
% =============================================================

info = struct();

info.enabled = true;

info.filterType = "lowpass";

info.inputSampleRate_Hz = ...
    sampleRate_Hz;

info.outputSampleRate_Hz = ...
    sampleRate_Hz;

info.cutoffFrequency_Hz = ...
    cutoffFrequency_Hz;

info.nyquistFrequency_Hz = ...
    nyquist_Hz;

info.normalizedCutoff = ...
    normalizedCutoff;

info.filterOrder = ...
    filterOrder;

info.coefficients = ...
    b;

info.window = ...
    "hann";

info.inputSamples = ...
    N;

info.outputSamples = ...
    numel(y);

info.decimationEnabled = ...
    false;

info.decimationFactor = ...
    1;

info.groupDelay_samples = ...
    filterOrder / 2;

info.groupDelay_s = ...
    (filterOrder / 2) / sampleRate_Hz;

end