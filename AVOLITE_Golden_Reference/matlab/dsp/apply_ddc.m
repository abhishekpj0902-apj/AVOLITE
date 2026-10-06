function [y, info] = apply_ddc(x, sampleRate_Hz, loFrequency_Hz, cfg)
%APPLY_DDC Digital down-conversion to complex baseband.
%
% AVOLITE Golden Reference
%
% Inputs:
%   x               : complex digital input samples
%   sampleRate_Hz   : input sample rate [Hz]
%   loFrequency_Hz  : digital LO frequency [Hz]
%   cfg             : AVOLITE configuration
%
% Outputs:
%   y               : complex down-converted output
%   info             : DDC diagnostics and filter parameters
%
% Processing:
%
%   Input complex samples
%          |
%          v
%   Complex NCO / mixer
%          |
%          v
%   FIR low-pass filter
%          |
%          v
%   Complex baseband output
%
% Frequency relationship:
%
%   f_out = f_in - f_LO
%
% This implementation does NOT decimate.
% Therefore:
%
%   output sample rate = input sample rate
%
% Important:
%   AVOLITE uses a complex-envelope representation.
%   This function does not directly sample or process
%   a 10 GHz RF carrier.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if isempty(x) || ~isnumeric(x)

    error( ...
        'apply_ddc:InvalidInput', ...
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
        'apply_ddc:InvalidSampleRate', ...
        'sampleRate_Hz must be a positive finite scalar.');

end


%% ============================================================
% LO VALIDATION
% =============================================================

if ~isscalar(loFrequency_Hz) || ...
        ~isnumeric(loFrequency_Hz) || ...
        ~isfinite(loFrequency_Hz)

    error( ...
        'apply_ddc:InvalidLO', ...
        'loFrequency_Hz must be a finite scalar.');

end


%% ============================================================
% NYQUIST CHECK
% =============================================================

nyquist_Hz = sampleRate_Hz / 2;

if abs(loFrequency_Hz) >= nyquist_Hz

    error( ...
        'apply_ddc:LOExceedsNyquist', ...
        ['Magnitude of digital LO frequency must be ' ...
         'less than the Nyquist frequency.']);

end


%% ============================================================
% CONFIGURATION VALIDATION
% =============================================================

if ~isstruct(cfg)

    error( ...
        'apply_ddc:InvalidConfiguration', ...
        'cfg must be a structure.');

end


if ~isfield(cfg,'dsp') || ...
        ~isstruct(cfg.dsp) || ...
        ~isfield(cfg.dsp,'ddc')

    error( ...
        'apply_ddc:MissingConfiguration', ...
        'DDC configuration is missing.');

end


if ~isfield(cfg.dsp.ddc,'filterBandwidth_Hz')

    error( ...
        'apply_ddc:MissingBandwidth', ...
        'DDC filter bandwidth is missing.');

end


if ~isfield(cfg.dsp.ddc,'filterOrder')

    error( ...
        'apply_ddc:MissingFilterOrder', ...
        'DDC filter order is missing.');

end


bandwidth_Hz = cfg.dsp.ddc.filterBandwidth_Hz;

filterOrder = cfg.dsp.ddc.filterOrder;


%% ============================================================
% BANDWIDTH VALIDATION
% =============================================================

if ~isscalar(bandwidth_Hz) || ...
        ~isnumeric(bandwidth_Hz) || ...
        ~isfinite(bandwidth_Hz) || ...
        bandwidth_Hz <= 0

    error( ...
        'apply_ddc:InvalidBandwidth', ...
        'DDC filter bandwidth must be a positive finite scalar.');

end


if bandwidth_Hz >= sampleRate_Hz

    error( ...
        'apply_ddc:InvalidBandwidth', ...
        ['DDC filter bandwidth must be smaller than ' ...
         'the sample rate.']);

end


%% ============================================================
% FILTER ORDER VALIDATION
% =============================================================

if ~isscalar(filterOrder) || ...
        ~isnumeric(filterOrder) || ...
        ~isfinite(filterOrder) || ...
        filterOrder < 1 || ...
        filterOrder ~= floor(filterOrder)

    error( ...
        'apply_ddc:InvalidFilterOrder', ...
        'DDC filter order must be a positive integer.');

end


%% ============================================================
% PRESERVE INPUT ORIENTATION
% =============================================================

inputWasRow = isrow(x);

x_column = x(:);

N = numel(x_column);


%% ============================================================
% SAMPLE INDEX
% =============================================================

n = (0:N-1).';


%% ============================================================
% DIGITAL NCO / LOCAL OSCILLATOR
% ============================================================
%
% The negative sign performs down-conversion:
%
%   exp(+j 2*pi*f_in*t)
%       *
%   exp(-j 2*pi*f_LO*t)
%
% gives:
%
%   exp(+j 2*pi*(f_in-f_LO)*t)

nco = exp( ...
    -1j * ...
    2*pi * ...
    loFrequency_Hz * ...
    n / sampleRate_Hz);


%% ============================================================
% COMPLEX MIXER
% =============================================================

x_mixed = x_column .* nco;


%% ============================================================
% LOW-PASS FILTER DESIGN
% ============================================================
%
% Configured bandwidth is treated as the two-sided
% retained channel bandwidth.
%
% Therefore:
%
%   cutoff = bandwidth / 2

cutoffFrequency_Hz = bandwidth_Hz / 2;

normalizedCutoff = ...
    cutoffFrequency_Hz / nyquist_Hz;


if normalizedCutoff >= 1

    error( ...
        'apply_ddc:InvalidNormalizedCutoff', ...
        'Normalized DDC cutoff must be less than one.');

end


%% ============================================================
% FIR LOW-PASS FILTER
% =============================================================

window = hann(filterOrder + 1);

b = fir1( ...
    filterOrder, ...
    normalizedCutoff, ...
    "low", ...
    window);


%% ============================================================
% FILTER SIGNAL
% =============================================================

y_column = filter( ...
    b, ...
    1, ...
    x_mixed);


%% ============================================================
% RESTORE INPUT ORIENTATION
% =============================================================

if inputWasRow

    y = transpose(y_column);

else

    y = y_column;

end


%% ============================================================
% DDC INFORMATION
% =============================================================

info = struct();

% Basic configuration
info.inputSampleRate_Hz = sampleRate_Hz;

info.outputSampleRate_Hz = sampleRate_Hz;

info.loFrequency_Hz = loFrequency_Hz;

info.filterBandwidth_Hz = bandwidth_Hz;

info.filterOrder = filterOrder;

% Filter characteristics
info.cutoffFrequency_Hz = ...
    cutoffFrequency_Hz;

info.normalizedCutoff = ...
    normalizedCutoff;

info.coefficients = b;

% NCO information
info.ncoType = "complex_exponential";

info.mixingDirection = "downconversion";

% Processing information
info.decimationEnabled = false;

info.decimationFactor = 1;

info.inputSamples = N;

info.outputSamples = numel(y);


%% ============================================================
% FREQUENCY RELATIONSHIP
% =============================================================

info.frequencyRelationship = ...
    "f_out = f_in - f_LO";


end