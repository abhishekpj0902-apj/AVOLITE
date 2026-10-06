function coord = coordinate_system()
%COORDINATE_SYSTEM AVOLITE global coordinate-system convention.
%
% Internal simulation convention:
%   Position    : metres
%   Velocity    : metres/second
%   Distance    : metres
%   Time        : seconds
%   Frequency   : Hz
%   Power       : W
%   Angles      : radians
%
% Azimuth:
%   Angle in XY plane measured from +X toward +Y.
%
% Elevation:
%   Angle measured upward from the XY plane.
%
% MATLAB R2025b

%% Coordinate frame
coord.frame.name = "Cartesian";
coord.frame.axes = ["X", "Y", "Z"];

%% Position and velocity
coord.position.unit = "m";
coord.velocity.unit = "m/s";

%% Angular convention
coord.angle.internalUnit = "rad";
coord.angle.displayUnit = "deg";

coord.angle.azimuth.referenceAxis = "+X";
coord.angle.azimuth.positiveDirection = "+Y";

coord.angle.elevation.referencePlane = "XY";
coord.angle.elevation.positiveDirection = "+Z";

%% Other SI units
coord.distance.unit = "m";
coord.time.unit = "s";
coord.frequency.unit = "Hz";
coord.power.unit = "W";
coord.temperature.unit = "K";

end