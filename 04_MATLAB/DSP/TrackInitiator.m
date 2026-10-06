function Tracks = TrackInitiator(AssociationData)

%=========================================================
% SARRS STUDIO
% Track Initiator
%
% Converts CFAR detections into track measurements.
%
% Supports:
%   ✓ Range
%   ✓ Velocity
%   ✓ Doppler
%   ✓ Amplitude
%   ✓ Track ID
%   ✓ Association status
%=========================================================


%% ========================================================
% Initialize
%=========================================================

Tracks = struct([]);


%% ========================================================
% Validate
%=========================================================

if nargin < 1 || isempty(AssociationData)

    disp('No association data available.');

    return

end


if ~isfield(AssociationData,'Detections')

    error( ...
        'TrackInitiator: AssociationData.Detections not found.');

end


Detections = ...
    AssociationData.Detections;


NumDetections = ...
    length(Detections);


if NumDetections == 0

    disp('No tracks initiated.');

    return

end


%% ========================================================
% Association IDs
%=========================================================

if isfield(AssociationData,'TrackIndices')

    TrackIDs = ...
        AssociationData.TrackIndices;

else

    TrackIDs = ...
        zeros(NumDetections,1);

end


%% ========================================================
% Create Track Measurements
%=========================================================

for k = 1:NumDetections

    Detection = ...
        Detections(k);


    %% Track ID

    if TrackIDs(k) > 0

        Tracks(k).TrackID = ...
            TrackIDs(k);

        Tracks(k).AssociationStatus = ...
            "Associated";

    else

        Tracks(k).TrackID = ...
            k;

        Tracks(k).AssociationStatus = ...
            "New";

    end


    %% Detection index

    Tracks(k).DetectionIndex = ...
        k;


    %% Range

    Tracks(k).Range = ...
        double(Detection.Range);


    %% Velocity

    if isfield(Detection,'Velocity')

        Tracks(k).Velocity = ...
            double(Detection.Velocity);

    else

        Tracks(k).Velocity = 0;

    end


    %% Doppler

    if isfield(Detection,'Doppler')

        Tracks(k).Doppler = ...
            double(Detection.Doppler);

    else

        Tracks(k).Doppler = ...
            2 * Tracks(k).Velocity / 0.03;

    end


    %% Amplitude

    if isfield(Detection,'Amplitude')

        Tracks(k).Amplitude = ...
            double(Detection.Amplitude);

    else

        Tracks(k).Amplitude = 0;

    end


    %% Range Index

    if isfield(Detection,'RangeIndex')

        Tracks(k).RangeIndex = ...
            Detection.RangeIndex;

    end


    %% Velocity Index

    if isfield(Detection,'VelocityIndex')

        Tracks(k).VelocityIndex = ...
            Detection.VelocityIndex;

    end


    %% Track state

    Tracks(k).State = ...
        "Tentative";


    Tracks(k).Status = ...
        "Tentative";


    %% Counters

    Tracks(k).Age = 1;

    Tracks(k).HitCount = 1;

    Tracks(k).MissCount = 0;

    Tracks(k).Confirmed = false;


    %% Time

    Tracks(k).LastUpdate = ...
        datetime("now");

end


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Track Initiator');
disp('=========================================');

fprintf('Detections Received : %d\n',NumDetections);

fprintf('Track Measurements  : %d\n',length(Tracks));


for k = 1:length(Tracks)

    fprintf( ...
        'Detection %d -> Track %d | Range %.1f m | Velocity %.2f m/s | %s\n',...
        k,...
        Tracks(k).TrackID,...
        Tracks(k).Range,...
        Tracks(k).Velocity,...
        Tracks(k).AssociationStatus);

end

end