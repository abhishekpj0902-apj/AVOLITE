function AssociationData = TargetAssociation(CFARData,TrackTable)

%=========================================================
% SARRS STUDIO
% Multi-PRF Target Association
%
% Associates current CFAR detections with existing tracks.
%
% Association Method:
%   Nearest-Neighbor
%
% Association Parameters:
%   Range Gate
%   Velocity Gate
%
% Input:
%   CFARData
%   TrackTable
%
% Output:
%   AssociationData
%
%=========================================================


%% ========================================================
% Association Parameters
%=========================================================

RangeGate = 2000;          % metres

VelocityGate = 100;        % m/s


%% ========================================================
% Initialize Output Structure
%=========================================================

AssociationData = struct();

AssociationData.Detections = struct([]);

AssociationData.TrackIndices = [];

AssociationData.AssociatedRanges = [];

AssociationData.AssociatedVelocities = [];

AssociationData.UnassociatedIndices = [];

AssociationData.UnassociatedTracks = [];

AssociationData.AssociatedPairs = [];

AssociationData.NumberOfAssociations = 0;

AssociationData.NumberOfNewDetections = 0;

AssociationData.NumberOfTargets = 0;

AssociationData.NumberOfTracks = 0;

AssociationData.TargetDetected = false;

AssociationData.RangeGate = RangeGate;

AssociationData.VelocityGate = VelocityGate;

AssociationData.Description = ...
    "Multi-PRF Range-Velocity Nearest Neighbor Association";


%% ========================================================
% Validate CFAR Input
%=========================================================

if nargin < 1 || isempty(CFARData)

    disp(' ');
    disp('=========================================');
    disp('Multi-PRF Target Association');
    disp('=========================================');

    disp('No CFAR data received.');

    return

end


if ~isstruct(CFARData)

    error( ...
        'TargetAssociation: CFARData must be a structure.');

end


%% ========================================================
% Extract CFAR Detections
%=========================================================

if ~isfield(CFARData,'Targets')

    error( ...
        'TargetAssociation: CFARData.Targets not found.');

end


Detections = ...
    CFARData.Targets;


NumDetections = ...
    length(Detections);


AssociationData.Detections = ...
    Detections;


AssociationData.NumberOfTargets = ...
    NumDetections;


AssociationData.TargetDetected = ...
    NumDetections > 0;


%% ========================================================
% Extract Existing Track Table
%=========================================================

if nargin < 2 || isempty(TrackTable)

    Tracks = struct([]);

else

    Tracks = TrackTable;

end


NumTracks = ...
    length(Tracks);


AssociationData.NumberOfTracks = ...
    NumTracks;


%% ========================================================
% No Detections
%=========================================================

if NumDetections == 0

    disp(' ');
    disp('=========================================');
    disp('Multi-PRF Target Association');
    disp('=========================================');

    fprintf('Detections       : 0\n');

    fprintf('Existing Tracks  : %d\n', ...
        NumTracks);

    fprintf('Associations     : 0\n');

    fprintf('New Detections   : 0\n');

    return

end


%% ========================================================
% No Existing Tracks
%=========================================================

if NumTracks == 0

    AssociationData.TrackIndices = ...
        zeros(NumDetections,1);


    AssociationData.AssociatedRanges = ...
        nan(NumDetections,1);


    AssociationData.AssociatedVelocities = ...
        nan(NumDetections,1);


    AssociationData.UnassociatedIndices = ...
        (1:NumDetections)';


    AssociationData.UnassociatedTracks = ...
        [];


    AssociationData.AssociatedPairs = ...
        zeros(0,2);


    AssociationData.NumberOfAssociations = ...
        0;


    AssociationData.NumberOfNewDetections = ...
        NumDetections;


    %% Display

    disp(' ');
    disp('=========================================');
    disp('Multi-PRF Target Association');
    disp('=========================================');

    fprintf('Detections       : %d\n', ...
        NumDetections);

    fprintf('Existing Tracks  : 0\n');

    fprintf('Range Gate       : %.0f m\n', ...
        RangeGate);

    fprintf('Velocity Gate    : %.1f m/s\n', ...
        VelocityGate);

    fprintf('Associations     : 0\n');

    fprintf('New Detections   : %d\n', ...
        NumDetections);


    %% Detection Summary

    disp(' ');

    for d = 1:NumDetections

        DetectionRange = ...
            GetDetectionRange(Detections(d));


        DetectionVelocity = ...
            GetDetectionVelocity(Detections(d));


        fprintf( ...
            'Detection %d -> NEW | Range %.1f m | Velocity %.2f m/s\n',...
            d,...
            DetectionRange,...
            DetectionVelocity);

    end


    return

end


%% ========================================================
% Initialize Association Arrays
%=========================================================

TrackIndices = ...
    zeros(NumDetections,1);


AssociatedRanges = ...
    nan(NumDetections,1);


AssociatedVelocities = ...
    nan(NumDetections,1);


DetectionUsed = ...
    false(NumDetections,1);


TrackUsed = ...
    false(NumTracks,1);


%% ========================================================
% Association Cost Matrix
%=========================================================

Cost = ...
    inf(NumDetections,NumTracks);


%% ========================================================
% Calculate Association Cost
%=========================================================

for d = 1:NumDetections


    %% ----------------------------------------------------
    % Detection Range
    %-----------------------------------------------------

    DetectionRange = ...
        GetDetectionRange(Detections(d));


    %% ----------------------------------------------------
    % Detection Velocity
    %-----------------------------------------------------

    DetectionVelocity = ...
        GetDetectionVelocity(Detections(d));


    %% ----------------------------------------------------
    % Compare With Existing Tracks
    %-----------------------------------------------------

    for t = 1:NumTracks


        %% Ignore deleted tracks

        if isfield(Tracks(t),'State')

            if Tracks(t).State == "Deleted"

                continue

            end

        end


        %% ------------------------------------------------
        % Track Range
        %-------------------------------------------------

        TrackRange = ...
            GetTrackRange(Tracks(t));


        %% ------------------------------------------------
        % Track Velocity
        %-------------------------------------------------

        TrackVelocity = ...
            GetTrackVelocity(Tracks(t));


        %% ------------------------------------------------
        % Calculate Differences
        %-------------------------------------------------

        RangeDifference = ...
            abs( ...
            DetectionRange - TrackRange);


        VelocityDifference = ...
            abs( ...
            DetectionVelocity - TrackVelocity);


        %% ------------------------------------------------
        % Apply Gating
        %-------------------------------------------------

        if RangeDifference <= RangeGate && ...
                VelocityDifference <= VelocityGate


            %% Normalized Range Cost

            RangeCost = ...
                RangeDifference / RangeGate;


            %% Normalized Velocity Cost

            VelocityCost = ...
                VelocityDifference / VelocityGate;


            %% Combined Cost

            Cost(d,t) = ...
                RangeCost + VelocityCost;

        end

    end

end


%% ========================================================
% Nearest-Neighbor Association
%=========================================================

AssociatedPairs = ...
    zeros(0,2);


while true


    %% ----------------------------------------------------
    % Find Minimum Cost
    %-----------------------------------------------------

    [MinimumCost,LinearIndex] = ...
        min(Cost(:));


    %% ----------------------------------------------------
    % Stop If No Valid Association
    %-----------------------------------------------------

    if isempty(MinimumCost) || ...
            isinf(MinimumCost)

        break

    end


    %% ----------------------------------------------------
    % Convert Linear Index
    %-----------------------------------------------------

    [DetectionIndex,TrackIndex] = ...
        ind2sub( ...
        size(Cost),...
        LinearIndex);


    %% ----------------------------------------------------
    % Get Track ID
    %-----------------------------------------------------

    if isfield(Tracks(TrackIndex),'TrackID')

        TrackID = ...
            Tracks(TrackIndex).TrackID;

    else

        TrackID = ...
            TrackIndex;

    end


    %% ----------------------------------------------------
    % Store Track ID
    %-----------------------------------------------------

    TrackIndices(DetectionIndex) = ...
        TrackID;


    %% ----------------------------------------------------
    % Store Associated Range
    %-----------------------------------------------------

    AssociatedRanges(DetectionIndex) = ...
        GetTrackRange(Tracks(TrackIndex));


    %% ----------------------------------------------------
    % Store Associated Velocity
    %-----------------------------------------------------

    AssociatedVelocities(DetectionIndex) = ...
        GetTrackVelocity(Tracks(TrackIndex));


    %% ----------------------------------------------------
    % Store Association Pair
    %-----------------------------------------------------

    AssociatedPairs(end+1,:) = ...
        [DetectionIndex TrackIndex];


    %% ----------------------------------------------------
    % Mark Detection Used
    %-----------------------------------------------------

    DetectionUsed(DetectionIndex) = ...
        true;


    %% ----------------------------------------------------
    % Mark Track Used
    %-----------------------------------------------------

    TrackUsed(TrackIndex) = ...
        true;


    %% ----------------------------------------------------
    % Remove Detection From Cost Matrix
    %-----------------------------------------------------

    Cost(DetectionIndex,:) = ...
        inf;


    %% ----------------------------------------------------
    % Remove Track From Cost Matrix
    %-----------------------------------------------------

    Cost(:,TrackIndex) = ...
        inf;

end


%% ========================================================
% Find New / Unassociated Detections
%=========================================================

UnassociatedIndices = ...
    find(~DetectionUsed);


%% ========================================================
% Find Unmatched Existing Tracks
%=========================================================

UnassociatedTracks = ...
    find(~TrackUsed);


%% ========================================================
% Store Association Results
%=========================================================

AssociationData.TrackIndices = ...
    TrackIndices;


AssociationData.AssociatedRanges = ...
    AssociatedRanges;


AssociationData.AssociatedVelocities = ...
    AssociatedVelocities;


AssociationData.UnassociatedIndices = ...
    UnassociatedIndices;


AssociationData.UnassociatedTracks = ...
    UnassociatedTracks;


AssociationData.AssociatedPairs = ...
    AssociatedPairs;


AssociationData.NumberOfAssociations = ...
    sum(DetectionUsed);


AssociationData.NumberOfNewDetections = ...
    length(UnassociatedIndices);


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Multi-PRF Target Association');
disp('=========================================');

fprintf('Detections       : %d\n', ...
    NumDetections);

fprintf('Existing Tracks  : %d\n', ...
    NumTracks);

fprintf('Range Gate       : %.0f m\n', ...
    RangeGate);

fprintf('Velocity Gate    : %.1f m/s\n', ...
    VelocityGate);

fprintf('Associations     : %d\n', ...
    AssociationData.NumberOfAssociations);

fprintf('New Detections   : %d\n', ...
    AssociationData.NumberOfNewDetections);

fprintf('Unmatched Tracks : %d\n', ...
    length(UnassociatedTracks));


%% ========================================================
% Association Summary
%=========================================================

disp(' ');

for d = 1:NumDetections


    DetectionRange = ...
        GetDetectionRange(Detections(d));


    DetectionVelocity = ...
        GetDetectionVelocity(Detections(d));


    if TrackIndices(d) > 0

        fprintf( ...
            'Detection %d -> Track %d | Range %.1f m | Velocity %.2f m/s\n',...
            d,...
            TrackIndices(d),...
            DetectionRange,...
            DetectionVelocity);

    else

        fprintf( ...
            'Detection %d -> NEW | Range %.1f m | Velocity %.2f m/s\n',...
            d,...
            DetectionRange,...
            DetectionVelocity);

    end

end


end


%% ========================================================
% Helper Function
% Get Detection Range
%=========================================================

function Range = GetDetectionRange(Object)

if isfield(Object,'Range')

    Range = ...
        double(Object.Range);

elseif isfield(Object,'Position')

    Position = ...
        double(Object.Position);

    Range = ...
        Position(1);

else

    Range = 0;

end

end


%% ========================================================
% Helper Function
% Get Detection Velocity
%=========================================================

function Velocity = GetDetectionVelocity(Object)

if isfield(Object,'Velocity')

    Velocity = ...
        double(Object.Velocity);

elseif isfield(Object,'Speed')

    Velocity = ...
        double(Object.Speed);

else

    Velocity = 0;

end

end


%% ========================================================
% Helper Function
% Get Track Range
%=========================================================

function Range = GetTrackRange(Object)

if isfield(Object,'FilteredRange')

    Range = ...
        double(Object.FilteredRange);

elseif isfield(Object,'PredictedRange')

    Range = ...
        double(Object.PredictedRange);

elseif isfield(Object,'Range')

    Range = ...
        double(Object.Range);

elseif isfield(Object,'Position')

    Position = ...
        double(Object.Position);

    Range = ...
        Position(1);

else

    Range = 0;

end

end


%% ========================================================
% Helper Function
% Get Track Velocity
%=========================================================

function Velocity = GetTrackVelocity(Object)

if isfield(Object,'FilteredVelocity')

    Velocity = ...
        double(Object.FilteredVelocity);

elseif isfield(Object,'PredictedVelocity')

    Velocity = ...
        double(Object.PredictedVelocity);

elseif isfield(Object,'Velocity')

    Velocity = ...
        double(Object.Velocity);

elseif isfield(Object,'Speed')

    Velocity = ...
        double(Object.Speed);

else

    Velocity = 0;

end

end