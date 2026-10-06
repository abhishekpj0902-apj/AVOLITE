function RDMap = RangeDopplerMap(InputSignal,Radar)

%=========================================================
% SARRS STUDIO
% Range Doppler Map
%
% Generates 2D Range-Doppler Matrix
%=========================================================

RDMap = struct;

%% Input

Signal = InputSignal(:);

%% Parameters

NRange = length(Signal);

NDoppler = 128;

%% Create 2D Matrix

SignalMatrix = repmat(Signal,1,NDoppler);

%% Doppler FFT

RD = fftshift(fft2(SignalMatrix));

Magnitude = abs(RD);

%% Range Axis

fs = Radar.SampleRate;

if isempty(fs)

    fs = 100e6;

end

RangeAxis = (0:NRange-1);

RangeAxis = RangeAxis * Radar.c /(2*fs);

%% Doppler Axis

PRF = Radar.PRF;

FrequencyAxis = linspace(-PRF/2,PRF/2,NDoppler);

VelocityAxis = FrequencyAxis * Radar.Wavelength /2;

%% Peak

[PeakValue,Index] = max(Magnitude(:));

[row,col] = ind2sub(size(Magnitude),Index);

%% Store

RDMap.Matrix = Magnitude;

RDMap.RangeAxis = RangeAxis;

RDMap.DopplerAxis = FrequencyAxis;

RDMap.VelocityAxis = VelocityAxis;

RDMap.PeakValue = PeakValue;

RDMap.PeakRange = RangeAxis(row);

RDMap.PeakVelocity = VelocityAxis(col);

RDMap.Size = size(Magnitude);

end