function Beamformer = AESABeamformer(Beam)

%=========================================================
% SARRS STUDIO
% AESA Beamformer
%
% Digital Beamforming Module
%
% Computes:
%   • Steering Vector
%   • Phase Shift
%   • Amplitude Weight
%   • Beam Weight Matrix
%
%=========================================================

%% Radar Parameters

Frequency = 10e9;          % 10 GHz

c = 3e8;

lambda = c/Frequency;

d = lambda/2;              % Element spacing

NumElements = 64;          % 8x8 Linear Equivalent

Beamformer = struct([]);

if isempty(Beam)
    return
end

%% --------------------------------------------
% Process Every Beam
%% --------------------------------------------

for k = 1:length(Beam)

    theta = deg2rad(Beam(k).Azimuth);

    %% Steering Vector

    SteeringVector = zeros(NumElements,1);

    PhaseShift = zeros(NumElements,1);

    Amplitude = ones(NumElements,1);

    for n = 1:NumElements

        phase = ...
            -2*pi*(n-1)*d*sin(theta)/lambda;

        PhaseShift(n) = phase;

        SteeringVector(n) = exp(1j*phase);

    end

    %% Windowing

    Weight = SteeringVector;

    %% Normalize

    Weight = Weight ./ norm(Weight);

    %% Save

    Beamformer(k).TargetID = Beam(k).TargetID;

    Beamformer(k).Azimuth = Beam(k).Azimuth;

    Beamformer(k).Elevation = Beam(k).Elevation;

    Beamformer(k).BeamWidth = Beam(k).BeamWidth;

    Beamformer(k).PhaseShift = PhaseShift;

    Beamformer(k).Amplitude = Amplitude;

    Beamformer(k).Weight = Weight;

    Beamformer(k).NumElements = NumElements;

end

end