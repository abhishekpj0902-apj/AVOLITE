function RadarData = Radar(PRF)

%=========================================================
%
% SARRS STUDIO
%
% Radar Model
%
% Purpose:
%   Defines the physical radar parameters and
%   calculates basic derived parameters.
%
%=========================================================

%% ========================================================
% Default Input
%=========================================================

if nargin < 1
    PRF = 1000;
end

if PRF <= 0
    error("PRF must be greater than zero.");
end

%% ========================================================
% Physical Constant
%=========================================================

RadarData.c = 3e8;

%% ========================================================
% Radar Parameters
%=========================================================

RadarData.Frequency = 10e9;

RadarData.Power = 10000;

RadarData.Gain = 35;

RadarData.PulseWidth = 1e-6;

RadarData.PRF = PRF;

RadarData.Bandwidth = 20e6;

RadarData.SampleRate = 100e6;
%% ========================================================
% Derived Parameters
%========================================================

RadarData.Wavelength = ...
    RadarData.c / RadarData.Frequency;

RadarData.PRI = ...
    1 / RadarData.PRF;

RadarData.RangeResolution = ...
    RadarData.c / ...
    (2 * RadarData.Bandwidth);

RadarData.MaximumRange = ...
    RadarData.c / ...
    (2 * RadarData.PRF);


%% ========================================================
% Description
%========================================================

RadarData.Description = ...
    "SARRS Radar Physical Model";

end