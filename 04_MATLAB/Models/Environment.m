function EnvironmentData = Environment()

%=========================================================
% SARRS STUDIO
% Environment Model
%
% Creates the simulation environment.
%
%=========================================================

%% Atmospheric Conditions

EnvironmentData.Temperature = 30;      % Celsius

EnvironmentData.Humidity = 60;         % %

EnvironmentData.Pressure = 1013;       % hPa

EnvironmentData.Wind = 10;             % km/h

%% Weather

EnvironmentData.Rain = 'None';

EnvironmentData.Fog = 'None';

EnvironmentData.Cloud = 'Clear';

%% Terrain

EnvironmentData.Terrain = 'Open Field';

%% Electronic Environment

EnvironmentData.Jamming = 'OFF';

EnvironmentData.Interference = 'LOW';

EnvironmentData.Clutter = 'LOW';

%% Propagation Loss

EnvironmentData.RainLoss = 0;

EnvironmentData.FogLoss = 0;

EnvironmentData.AtmosphericLoss = 0;

%% Visibility

EnvironmentData.Visibility = 100;

%% Time

EnvironmentData.Time = datetime("now");

end