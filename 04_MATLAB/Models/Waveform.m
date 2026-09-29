function WaveformData = Waveform(Radar)

%=========================================================
%
% SARRS STUDIO
% Radar Pulse Waveform Generator
%
% Purpose:
%   Generates a rectangular complex-baseband radar pulse
%   using the parameters supplied by the Radar model.
%
% Input:
%   Radar : Radar parameter structure from Radar.m
%
% Output:
%   WaveformData : Generated waveform and parameters
%
%=========================================================


%% ========================================================
% Validate Input
%=========================================================

if nargin < 1
    error("Radar parameter structure is required.");
end

RequiredFields = {
    'SampleRate'
    'PRI'
    'PulseWidth'
    'Frequency'
    'PRF'
};

for k = 1:length(RequiredFields)

    if ~isfield(Radar, RequiredFields{k})

        error("Radar structure is missing field: %s", ...
            RequiredFields{k});

    end

end


%% ========================================================
% Radar Parameters
%=========================================================

Fs = Radar.SampleRate;

PRI = Radar.PRI;

PW = Radar.PulseWidth;

fc = Radar.Frequency;

PRF = Radar.PRF;


%% ========================================================
% Time Vector
%=========================================================

% Generate samples inside one PRI.
%
% The final sample is excluded so that the waveform
% contains exactly one PRI without an extra sample.

Time = 0:1/Fs:(PRI - 1/Fs);

N = length(Time);


%% ========================================================
% Empty Signal
%=========================================================

Signal = zeros(1, N);


%% ========================================================
% Number of Pulse Samples
%=========================================================

PulseSamples = round(PW * Fs);

% Ensure the pulse does not exceed the PRI.

PulseSamples = min(PulseSamples, N);


%% ========================================================
% Generate Complex Baseband Pulse
%=========================================================

% The radar carrier frequency is 10 GHz, while the
% simulation sample rate is 100 MHz.
%
% Therefore, the 10 GHz RF carrier is not directly
% sampled here.
%
% Instead, a complex-baseband rectangular pulse is used.
% Doppler effects are introduced later in Echo.m.

Pulse = ones(1, PulseSamples);


%% ========================================================
% Insert Pulse into PRI
%=========================================================

Signal(1:PulseSamples) = Pulse;


%% ========================================================
% Normalize Signal
%=========================================================

MaximumAmplitude = max(abs(Signal));

if MaximumAmplitude > 0

    Signal = Signal / MaximumAmplitude;

end


%% ========================================================
% Output Parameters
%=========================================================

WaveformData.Time = Time;

WaveformData.SampleRate = Fs;

WaveformData.NumberOfSamples = N;

WaveformData.Signal = Signal;

WaveformData.PulseSamples = PulseSamples;

WaveformData.PRF = PRF;

WaveformData.PRI = PRI;

WaveformData.PulseWidth = PW;

WaveformData.CarrierFrequency = fc;

WaveformData.Description = ...
    "Complex Baseband Radar Pulse";


end