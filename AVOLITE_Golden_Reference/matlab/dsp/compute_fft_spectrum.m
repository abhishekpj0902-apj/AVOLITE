function [spectrum, info] = compute_fft_spectrum(x, sampleRate_Hz, cfg)
%COMPUTE_FFT_SPECTRUM Compute single-sided complex-baseband FFT spectrum.
%
% AVOLITE Golden Reference
%
% Inputs:
%   x               : complex digital signal
%   sampleRate_Hz   : signal sample rate [Hz]
%   cfg             : AVOLITE configuration
%
% Outputs:
%   spectrum        : spectrum data structure
%   info            : FFT diagnostics and configuration
%
% Processing:
%
%   Input signal
%       |
%       v
%   Windowing
%       |
%       v
%   Zero padding (optional)
%       |
%       v
%   FFT
%       |
%       v
%   Frequency axis / magnitude
%
% Current Golden Reference:
%
%   FFT size = 4096
%   Window   = Hann
%   Zero pad = disabled
%
% Complex-baseband convention is used.
% Therefore the returned frequency axis spans:
%
%   -Fs/2 ... +Fs/2
%
% No detection or CFAR processing is performed here.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if isempty(x) || ~isnumeric(x)

    error( ...
        'compute_fft_spectrum:InvalidInput', ...
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
        'compute_fft_spectrum:InvalidSampleRate', ...
        'sampleRate_Hz must be a positive finite scalar.');

end

%% ============================================================
% CONFIGURATION VALIDATION
% =============================================================

if ~isstruct(cfg)

    error( ...
        'compute_fft_spectrum:InvalidConfiguration', ...
        'cfg must be a structure.');

end

if ~isfield(cfg,'dsp') || ...
        ~isstruct(cfg.dsp)

    error( ...
        'compute_fft_spectrum:MissingDSPConfiguration', ...
        'DSP configuration is missing.');

end

%% ============================================================
% FFT SIZE
% ============================================================

if ~isfield(cfg.dsp,'fftSize')

    error( ...
        'compute_fft_spectrum:MissingFFTSize', ...
        'FFT size configuration is missing.');

end

fftSize = cfg.dsp.fftSize;

if ~isscalar(fftSize) || ...
        ~isnumeric(fftSize) || ...
        ~isfinite(fftSize) || ...
        fftSize < 2 || ...
        fftSize ~= floor(fftSize)

    error( ...
        'compute_fft_spectrum:InvalidFFTSize', ...
        'FFT size must be an integer greater than or equal to two.');

end

%% ============================================================
% WINDOW CONFIGURATION
% ============================================================

if ~isfield(cfg.dsp,'window')

    error( ...
        'compute_fft_spectrum:MissingWindow', ...
        'FFT window configuration is missing.');

end

windowType = lower(string(cfg.dsp.window));

%% ============================================================
% ZERO PADDING CONFIGURATION
% ============================================================

if ~isfield(cfg.dsp,'enableZeroPadding')

    error( ...
        'compute_fft_spectrum:MissingZeroPadding', ...
        'Zero-padding configuration is missing.');

end

enableZeroPadding = ...
    logical(cfg.dsp.enableZeroPadding);

%% ============================================================
% PRESERVE INPUT ORIENTATION
% =============================================================

inputWasRow = isrow(x);

x_column = x(:);

inputSamples = numel(x_column);

%% ============================================================
% WINDOW
% =============================================================

switch windowType

    case "hann"

        window = hann(inputSamples);

    case "rectangular"

        window = ones(inputSamples,1);

    otherwise

        error( ...
            'compute_fft_spectrum:UnsupportedWindow', ...
            ['Unsupported FFT window: ' char(windowType) ...
             '. Supported windows are "hann" and "rectangular".']);

end

%% ============================================================
% WINDOWED SIGNAL
% =============================================================

x_windowed = ...
    x_column .* window;

%% ============================================================
% FFT LENGTH
% =============================================================

if enableZeroPadding

    fftLength = max(fftSize,inputSamples);

else

    fftLength = fftSize;

end

%% ============================================================
% FFT
% =============================================================

X = fft( ...
    x_windowed, ...
    fftLength);

%% ============================================================
% SHIFT ZERO FREQUENCY TO CENTER
% =============================================================

X_shifted = fftshift(X);

%% ============================================================
% FREQUENCY AXIS
% =============================================================

frequency_Hz = ...
    (-fftLength/2 : fftLength/2-1).' * ...
    (sampleRate_Hz / fftLength);

%% ============================================================
% MAGNITUDE
% =============================================================

magnitude = abs(X_shifted);

%% ============================================================
% NORMALIZED MAGNITUDE
% ============================================================
%
% Normalize by the coherent gain of the window and
% number of samples so that a bin-centered complex
% tone approximately reports its input amplitude.

windowCoherentGain = ...
    sum(window);

magnitudeNormalized = ...
    magnitude / windowCoherentGain;

%% ============================================================
% MAGNITUDE IN dB
% =============================================================

magnitude_dB = ...
    20*log10(max(magnitudeNormalized, ...
                 realmin));

%% ============================================================
% PEAK DETECTION
% ============================================================

[peakMagnitude, peakIndex] = ...
    max(magnitudeNormalized);

peakFrequency_Hz = ...
    frequency_Hz(peakIndex);

peakMagnitude_dB = ...
    magnitude_dB(peakIndex);

%% ============================================================
% OUTPUT STRUCTURE
% =============================================================

spectrum = struct();

spectrum.frequency_Hz = ...
    frequency_Hz;

spectrum.fft = ...
    X_shifted;

spectrum.magnitude = ...
    magnitude;

spectrum.magnitudeNormalized = ...
    magnitudeNormalized;

spectrum.magnitude_dB = ...
    magnitude_dB;

spectrum.peakFrequency_Hz = ...
    peakFrequency_Hz;

spectrum.peakMagnitude = ...
    peakMagnitude;

spectrum.peakMagnitude_dB = ...
    peakMagnitude_dB;

%% ============================================================
% INFORMATION STRUCTURE
% =============================================================

info = struct();

info.inputSampleRate_Hz = ...
    sampleRate_Hz;

info.outputSampleRate_Hz = ...
    sampleRate_Hz;

info.inputSamples = ...
    inputSamples;

info.fftSize = ...
    fftSize;

info.fftLength = ...
    fftLength;

info.window = ...
    windowType;

info.windowSamples = ...
    inputSamples;

info.windowCoherentGain = ...
    windowCoherentGain;

info.zeroPaddingEnabled = ...
    enableZeroPadding;

info.frequencyResolution_Hz = ...
    sampleRate_Hz / fftLength;

info.frequencyRange_Hz = ...
    [frequency_Hz(1), frequency_Hz(end)];

info.peakFrequency_Hz = ...
    peakFrequency_Hz;

info.peakMagnitude = ...
    peakMagnitude;

info.peakMagnitude_dB = ...
    peakMagnitude_dB;

%% ============================================================
% ORIENTATION INFORMATION
% =============================================================

info.inputWasRow = ...
    inputWasRow;

end