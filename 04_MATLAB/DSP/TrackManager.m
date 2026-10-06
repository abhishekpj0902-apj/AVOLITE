function TrackTable = TrackManager(TrackData)

%=========================================================
% SARRS STUDIO
% Persistent Multi-Scan Track Manager
%
% Features
% ------------------------------------------
% ✓ Persistent track database
% ✓ Track ID preservation
% ✓ Range / velocity update
% ✓ Kalman state preservation
% ✓ Hit counting
% ✓ Miss counting
% ✓ Track confirmation
% ✓ Track aging
% ✓ Track deletion
% ✓ Multi-scan operation
% ✓ Compatible with KalmanTracker
%=========================================================

%% ========================================================
% Persistent Track Database
%=========================================================

persistent Tracks

if isempty(Tracks)

    Tracks = struct([]);

end

%% ========================================================
% Parameters
%=========================================================

ConfirmationHits = 3;

DeletionMisses = 5;

%% ========================================================
% No Input
%=========================================================

if nargin < 1 || isempty(TrackData)

    disp(' ')
    disp('=========================================')
    disp('SARRS Track Manager')
    disp('=========================================')

    disp('No track measurements received.')

    %% Update missed tracks

    for k = 1:length(Tracks)

        Tracks(k).MissCount = ...
            Tracks(k).MissCount + 1;

        Tracks(k).Age = ...
            Tracks(k).Age + 1;

        if Tracks(k).MissCount >= DeletionMisses

            Tracks(k).State = "Deleted";

            Tracks(k).Status = "Deleted";

            Tracks(k).Confirmed = false;

        end

    end

    %% Remove deleted tracks

    if ~isempty(Tracks)

        Keep = true(1,length(Tracks));

        for k = 1:length(Tracks)

            if Tracks(k).State == "Deleted"

                Keep(k) = false;

            end

        end

        Tracks = Tracks(Keep);

    end

    TrackTable = Tracks;

    return

end

%% ========================================================
% Number Of Measurements
%=========================================================

NumMeasurements = length(TrackData);

%% ========================================================
% First Scan / Empty Database
%=========================================================

if isempty(Tracks)

    % IMPORTANT:
    %
    % Directly copy TrackData so every Kalman field
    % is preserved.

    Tracks = TrackData;

    %% Initialize management fields

    for k = 1:length(Tracks)

        %% Track ID

        if ~isfield(Tracks(k),'TrackID') || ...
                isempty(Tracks(k).TrackID)

            Tracks(k).TrackID = k;

        end

        %% State

        Tracks(k).State = "Tentative";

        Tracks(k).Status = "Tentative";

        %% Scan information

        Tracks(k).ScanNumber = 1;

        Tracks(k).Age = 1;

        %% Hit / miss

        Tracks(k).HitCount = 1;

        Tracks(k).MissCount = 0;

        Tracks(k).Confirmed = false;

        %% Timestamp

        Tracks(k).LastUpdate = datetime("now");

    end

    TrackTable = Tracks;

    %% Display

    disp(' ')
    disp('=========================================')
    disp('SARRS Track Manager')
    disp('=========================================')

    fprintf('First Scan\n')
    fprintf('Tracks Created : %d\n',length(Tracks))
    fprintf('Confirmed      : 0\n')
    fprintf('Tentative      : %d\n',length(Tracks))

    return

end

%% ========================================================
% Existing Track Count
%=========================================================

NumTracks = length(Tracks);

%% ========================================================
% Increase Scan Number
%=========================================================

for k = 1:NumTracks

    if isfield(Tracks(k),'ScanNumber')

        Tracks(k).ScanNumber = ...
            Tracks(k).ScanNumber + 1;

    else

        Tracks(k).ScanNumber = 1;

    end

end

%% ========================================================
% Track Update Flags
%=========================================================

UpdatedTrack = ...
    false(1,length(Tracks));

%% ========================================================
% Process Each Measurement
%=========================================================

for i = 1:NumMeasurements

    %% ----------------------------------------------------
    % Find Track ID
    %-----------------------------------------------------

    if isfield(TrackData(i),'TrackID')

        MeasurementTrackID = ...
            TrackData(i).TrackID;

    else

        MeasurementTrackID = 0;

    end

    %% ----------------------------------------------------
    % Search Existing Track
    %-----------------------------------------------------

    ExistingTrack = 0;

    for j = 1:length(Tracks)

        if Tracks(j).TrackID == ...
                MeasurementTrackID

            ExistingTrack = j;

            break

        end

    end

    %% ====================================================
    % EXISTING TRACK
    %=====================================================

    if ExistingTrack > 0

        j = ExistingTrack;

        %% Preserve existing Track ID

        TrackID = Tracks(j).TrackID;

        %% ------------------------------------------------
        % Update measurement fields
        %-------------------------------------------------

        Tracks(j).Range = ...
            TrackData(i).Range;

        if isfield(TrackData(i),'Velocity')

            Tracks(j).Velocity = ...
                TrackData(i).Velocity;

        end

        if isfield(TrackData(i),'Doppler')

            Tracks(j).Doppler = ...
                TrackData(i).Doppler;

        end

        if isfield(TrackData(i),'Amplitude')

            Tracks(j).Amplitude = ...
                TrackData(i).Amplitude;

        end

        if isfield(TrackData(i),'RangeIndex')

            Tracks(j).RangeIndex = ...
                TrackData(i).RangeIndex;

        end

        if isfield(TrackData(i),'VelocityIndex')

            Tracks(j).VelocityIndex = ...
                TrackData(i).VelocityIndex;

        end

        %% ------------------------------------------------
        % Copy Kalman fields
        %-------------------------------------------------

        if isfield(TrackData(i),'StateEstimate')

            Tracks(j).StateEstimate = ...
                TrackData(i).StateEstimate;

        end

        if isfield(TrackData(i),'StateCovariance')

            Tracks(j).StateCovariance = ...
                TrackData(i).StateCovariance;

        end

        if isfield(TrackData(i),'PredictedRange')

            Tracks(j).PredictedRange = ...
                TrackData(i).PredictedRange;

        end

        if isfield(TrackData(i),'PredictedVelocity')

            Tracks(j).PredictedVelocity = ...
                TrackData(i).PredictedVelocity;

        end

        if isfield(TrackData(i),'FilteredRange')

            Tracks(j).FilteredRange = ...
                TrackData(i).FilteredRange;

        end

        if isfield(TrackData(i),'FilteredVelocity')

            Tracks(j).FilteredVelocity = ...
                TrackData(i).FilteredVelocity;

        end

        if isfield(TrackData(i),'InnovationRange')

            Tracks(j).InnovationRange = ...
                TrackData(i).InnovationRange;

        end

        if isfield(TrackData(i),'InnovationVelocity')

            Tracks(j).InnovationVelocity = ...
                TrackData(i).InnovationVelocity;

        end

        if isfield(TrackData(i),'KalmanGain')

            Tracks(j).KalmanGain = ...
                TrackData(i).KalmanGain;

        end

        if isfield(TrackData(i),'Covariance')

            Tracks(j).Covariance = ...
                TrackData(i).Covariance;

        end

        if isfield(TrackData(i),'MeasuredPosition')

            Tracks(j).MeasuredPosition = ...
                TrackData(i).MeasuredPosition;

        end

        if isfield(TrackData(i),'PredictedPosition')

            Tracks(j).PredictedPosition = ...
                TrackData(i).PredictedPosition;

        end

        if isfield(TrackData(i),'FilteredPosition')

            Tracks(j).FilteredPosition = ...
                TrackData(i).FilteredPosition;

        end

        %% ------------------------------------------------
        % Management Counters
        %-------------------------------------------------

        Tracks(j).Age = ...
            Tracks(j).Age + 1;

        Tracks(j).HitCount = ...
            Tracks(j).HitCount + 1;

        Tracks(j).MissCount = 0;

        Tracks(j).LastUpdate = datetime("now");

        %% ------------------------------------------------
        % Confirmation
        %-------------------------------------------------

        if Tracks(j).HitCount >= ConfirmationHits

            Tracks(j).Confirmed = true;

            Tracks(j).State = "Confirmed";

            Tracks(j).Status = "Confirmed";

        else

            Tracks(j).Confirmed = false;

            Tracks(j).State = "Tentative";

            Tracks(j).Status = "Tentative";

        end

        %% Mark updated

        UpdatedTrack(j) = true;

    %% ====================================================
    % NEW TRACK
    %=====================================================

    else

        %% Copy complete measurement structure

        NewTrack = TrackData(i);

        %% ------------------------------------------------
        % Generate new Track ID
        %-------------------------------------------------

        if isempty(Tracks)

            NewTrack.TrackID = 1;

        else

            ExistingIDs = ...
                [Tracks.TrackID];

            NewTrack.TrackID = ...
                max(ExistingIDs) + 1;

        end

        %% ------------------------------------------------
        % Initialize management fields
        %-------------------------------------------------

        NewTrack.State = "Tentative";

        NewTrack.Status = "Tentative";

        NewTrack.ScanNumber = 1;

        NewTrack.Age = 1;

        NewTrack.HitCount = 1;

        NewTrack.MissCount = 0;

        NewTrack.Confirmed = false;

        NewTrack.LastUpdate = datetime("now");

        %% ------------------------------------------------
        % IMPORTANT
        %
        % MATLAB structure arrays require identical fields.
        %
        % Add missing fields from existing Tracks before
        % inserting NewTrack.
        %-------------------------------------------------

        ExistingFields = fieldnames(Tracks);

        NewFields = fieldnames(NewTrack);

        %% Fields existing in database but missing in NewTrack

        for f = 1:length(ExistingFields)

            FieldName = ExistingFields{f};

            if ~isfield(NewTrack,FieldName)

                NewTrack.(FieldName) = [];

            end

        end

        %% Fields in NewTrack but missing in database
        %
        % Add the field to every existing track.

        for f = 1:length(NewFields)

            FieldName = NewFields{f};

            if ~isfield(Tracks,FieldName)

                for q = 1:length(Tracks)

                    Tracks(q).(FieldName) = [];

                end

            end

        end

        %% ------------------------------------------------
        % Insert New Track
        %-------------------------------------------------

        Tracks(end+1) = NewTrack;

        UpdatedTrack(end+1) = true;

    end

end

%% ========================================================
% Process Missed Tracks
%=========================================================

for k = 1:length(Tracks)

    %% Skip updated tracks

    if k <= length(UpdatedTrack)

        if UpdatedTrack(k)

            continue

        end

    end

    %% Missed track

    Tracks(k).MissCount = ...
        Tracks(k).MissCount + 1;

    Tracks(k).Age = ...
        Tracks(k).Age + 1;

    %% Delete after too many misses

    if Tracks(k).MissCount >= DeletionMisses

        Tracks(k).State = "Deleted";

        Tracks(k).Status = "Deleted";

        Tracks(k).Confirmed = false;

    end

end

%% ========================================================
% Remove Deleted Tracks
%=========================================================

if ~isempty(Tracks)

    KeepTrack = ...
        true(1,length(Tracks));

    for k = 1:length(Tracks)

        if Tracks(k).State == "Deleted"

            KeepTrack(k) = false;

        end

    end

    Tracks = Tracks(KeepTrack);

end

%% ========================================================
% Output
%=========================================================

TrackTable = Tracks;

%% ========================================================
% Display
%=========================================================

disp(' ')
disp('=========================================')
disp('SARRS Track Manager')
disp('=========================================')

fprintf('Tracks In Database : %d\n', ...
    length(TrackTable));

ConfirmedCount = 0;

TentativeCount = 0;

DeletedCount = 0;

for k = 1:length(TrackTable)

    if TrackTable(k).State == "Confirmed"

        ConfirmedCount = ...
            ConfirmedCount + 1;

    elseif TrackTable(k).State == "Tentative"

        TentativeCount = ...
            TentativeCount + 1;

    elseif TrackTable(k).State == "Deleted"

        DeletedCount = ...
            DeletedCount + 1;

    end

end

fprintf('Confirmed          : %d\n', ...
    ConfirmedCount);

fprintf('Tentative          : %d\n', ...
    TentativeCount);

fprintf('Deleted            : %d\n', ...
    DeletedCount);

%% ========================================================
% Track Summary
%=========================================================

for k = 1:length(TrackTable)

    if isfield(TrackTable(k),'FilteredRange')

        DisplayRange = ...
            TrackTable(k).FilteredRange;

    else

        DisplayRange = ...
            TrackTable(k).Range;

    end

    if isfield(TrackTable(k),'FilteredVelocity')

        DisplayVelocity = ...
            TrackTable(k).FilteredVelocity;

    elseif isfield(TrackTable(k),'Velocity')

        DisplayVelocity = ...
            TrackTable(k).Velocity;

    else

        DisplayVelocity = 0;

    end

    fprintf( ...
        'Track %d | Range %.2f m | Velocity %.2f m/s | Hits %d | Misses %d | %s\n', ...
        TrackTable(k).TrackID, ...
        DisplayRange, ...
        DisplayVelocity, ...
        TrackTable(k).HitCount, ...
        TrackTable(k).MissCount, ...
        TrackTable(k).State);

end

end