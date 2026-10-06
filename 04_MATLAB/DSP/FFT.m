function FFTData = FFT(InputSignal)

%=========================================================
% SARRS STUDIO
% FFT Processor
%
% Fast Fourier Transform
%=========================================================

FFTData = struct;

%% Input

InputSignal = InputSignal(:);

N = length(InputSignal);

%% FFT

Spectrum = fft(InputSignal);

SpectrumShift = fftshift(Spectrum);

Magnitude = abs(SpectrumShift);

Power = Magnitude.^2;

Phase = angle(SpectrumShift);

%% Frequency Axis

Frequency = linspace(-0.5,0.5,N);

%% Output

FFTData.Input = InputSignal;

FFTData.Output = Spectrum;

FFTData.ShiftedSpectrum = SpectrumShift;

FFTData.Magnitude = Magnitude;

FFTData.Power = Power;

FFTData.Phase = Phase;

FFTData.Frequency = Frequency;

FFTData.Peak = max(Magnitude);

[~,Index] = max(Magnitude);

FFTData.PeakIndex = Index;

end