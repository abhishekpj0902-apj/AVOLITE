function Beam = BeamSteering(Scan,Tracking)

%=========================================================
% SARRS STUDIO
% Beam Steering
%
% Computes:
%   • Azimuth
%   • Elevation
%   • Slant Range
%   • Beam Width
%   • Beam Direction
%
%=========================================================

Beam = struct([]);

NumTargets = length(Scan);

if NumTargets == 0
    return
end

for k = 1:NumTargets

    %% Target Position

    X = Tracking(k).X(1);
    Y = Tracking(k).Y(1);
    Z = Tracking(k).Z(1);

    %% Slant Range

    R = sqrt(X^2 + Y^2 + Z^2);

    %% Azimuth

    Azimuth = atan2d(Y,X);

    %% Elevation

    Elevation = atan2d(Z,sqrt(X^2+Y^2));

    %% Beam Width

    switch Scan(k).Threat

        case "HIGH"

            BeamWidth = 1.0;

        case "MEDIUM"

            BeamWidth = 2.0;

        otherwise

            BeamWidth = 4.0;

    end

    %% Store Results

    Beam(k).TargetID = Scan(k).TargetID;

    Beam(k).Range = R;

    Beam(k).Azimuth = Azimuth;

    Beam(k).Elevation = Elevation;

    Beam(k).BeamWidth = BeamWidth;

    Beam(k).Priority = Scan(k).Priority;

    Beam(k).Mode = Scan(k).Mode;

end

end