function Association = TrackAssociation(Detections, Tracks)

%=========================================================
% SARRS STUDIO
% Track Association Engine
%
% Multi-PRF Range-Velocity Nearest Neighbor Association
%
% Inputs:
%   Detections - CFAR detection structure
%   Tracks     - existing track table
%
% Outputs:
%   Association.Detections
%   Association.TrackIndices
%   Association.DetectionToTrack
%   Association.TrackToDetection
%   Association.AssociatedPairs
%   Association.UnassociatedDetections
%   Association.UnassociatedTracks
%
%=========================================================


%% ========================================================
% Association Parameters
%========================================================

RangeGate = 2000;          % metres

VelocityGate = 100;        % m/s


%% ========================================================
% Validate Inputs
%========================================================

if nargin < 1 || isempty(Detections)

    Detections = struct([]);

end


if nargin < 2 || isempty(Tracks)

    Tracks = struct([]);

end


%% ========================================================
% Number Of Objects
%========================================================

NumDetections = ...
    length(Detections);

NumTracks = ...
    length(Tracks);


%% ========================================================
% Store Original Detections
%========================================================

Association.Detections = ...
    Detections;


%% ========================================================
% Initialize Association Tables
%========================================================

Association.DetectionToTrack = ...
    zeros(NumDetections,1);

Association.TrackToDetection = ...
    zeros(NumTracks,1);

Association.TrackIndices = ...
    zeros(NumDetections,1);

Association.AssociatedPairs = ...
    zeros(0,2);

Association.UnassociatedDetections = ...
    (1:NumDetections)';

Association.UnassociatedTracks = ...
    (1:NumTracks)';


%% ========================================================
% No Detections
%========================================================

if NumDetections == 0

    Association.NumberOfAssociations = 0;

    Association.NumberOfNewDetections = 0;

    Association.NumberOfDetections = 0;

    Association.NumberOfTracks = NumTracks;

    Association.RangeGate = RangeGate;

    Association.VelocityGate = VelocityGate;

    Association.Description = ...
        "Nearest Neighbor Range-Velocity Track Association";

    return

end


%% ========================================================
% No Existing Tracks
%========================================================

if NumTracks == 0

    Association.NumberOfAssociations = 0;

    Association.NumberOfNewDetections = ...
        NumDetections;

    Association.NumberOfDetections = ...
        NumDetections;

    Association.NumberOfTracks = 0;

    Association.RangeGate = RangeGate;

    Association.VelocityGate = VelocityGate;

    Association.Description = ...
        "Nearest Neighbor Range-Velocity Track Association";

    disp(' ');
    disp('=========================================');
    disp('Track Association Engine');
    disp('=========================================');

    fprintf('Detections       : %d\n', ...
        NumDetections);

    fprintf('Existing Tracks  : 0\n');

    fprintf('Associations     : 0\n');

    fprintf('New Detections   : %d\n', ...
        NumDetections);

    return

end


%% ========================================================
% Association Cost Matrix
%=========================================================

Cost = ...
    inf(NumDetections,NumTracks);


%% ========================================================
% Calculate Detection-Track Cost
%=========================================================

for d = 1:NumDetections

    %% Detection Range

    DetectionRange = ...
        GetRange(Detections(d));


    %% Detection Velocity

    DetectionVelocity = ...
        GetVelocity(Detections(d));


    %% Compare With Existing Tracks

    for t = 1:NumTracks

        %% Ignore deleted tracks

        if isfield(Tracks(t),'State')

            if string(Tracks(t).State) == "Deleted"

                continue

            end

        end


        %% Track Range

        TrackRange = ...
            GetRange(Tracks(t));


        %% Track Velocity

        TrackVelocity = ...
            GetVelocity(Tracks(t));


        %% Differences

        RangeDifference = ...
            abs(DetectionRange - TrackRange);

        VelocityDifference = ...
            abs(DetectionVelocity - TrackVelocity);


        %% Range + Velocity Gate

        if RangeDifference <= RangeGate && ...
                VelocityDifference <= VelocityGate

            %% Normalized range cost

            RangeCost = ...
                RangeDifference / RangeGate;


            %% Normalized velocity cost

            VelocityCost = ...
                VelocityDifference / VelocityGate;


            %% Combined cost

            Cost(d,t) = ...
                RangeCost + VelocityCost;

        end

    end

end


%% ========================================================
% Nearest Neighbor Association
%=========================================================

AssociatedPairs = ...
    zeros(0,2);


while true

    %% Find minimum valid cost

    [MinimumCost,LinearIndex] = ...
        min(Cost(:));


    %% No valid association

    if isempty(MinimumCost) || ...
            isinf(MinimumCost)

        break

    end


    %% Convert linear index

    [DetectionIndex,TrackIndex] = ...
        ind2sub( ...
            size(Cost), ...
            LinearIndex);


    %% Store association

    Association.DetectionToTrack(DetectionIndex) = ...
        TrackIndex;

    Association.TrackToDetection(TrackIndex) = ...
        DetectionIndex;


    AssociatedPairs(end+1,:) = ...
        [DetectionIndex TrackIndex];


    %% Track ID

    if isfield(Tracks(TrackIndex),'TrackID')

        Association.TrackIndices(DetectionIndex) = ...
            Tracks(TrackIndex).TrackID;

    else

        Association.TrackIndices(DetectionIndex) = ...
            TrackIndex;

    end


    %% Remove assigned detection

    Cost(DetectionIndex,:) = ...
        inf;


    %% Remove assigned track

    Cost(:,TrackIndex) = ...
        inf;

end


%% ========================================================
% Store Associated Pairs
%=========================================================

Association.AssociatedPairs = ...
    AssociatedPairs;


%% ========================================================
% Unassociated Detections
%=========================================================

Association.UnassociatedDetections = ...
    find( ...
    Association.DetectionToTrack == 0);


%% ========================================================
% Unassociated Tracks
%=========================================================

Association.UnassociatedTracks = ...
    find( ...
    Association.TrackToDetection == 0);


%% ========================================================
% Statistics
%=========================================================

Association.NumberOfAssociations = ...
    size(AssociatedPairs,1);

Association.NumberOfNewDetections = ...
    length(Association.UnassociatedDetections);

Association.NumberOfDetections = ...
    NumDetections;

Association.NumberOfTracks = ...
    NumTracks;


%% ========================================================
% Parameters
%=========================================================

Association.RangeGate = ...
    RangeGate;

Association.VelocityGate = ...
    VelocityGate;


Association.Description = ...
    "Nearest Neighbor Range-Velocity Track Association";


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Track Association Engine');
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
    Association.NumberOfAssociations);

fprintf('New Detections   : %d\n', ...
    Association.NumberOfNewDetections);

fprintf('Unmatched Tracks : %d\n', ...
    length(Association.UnassociatedTracks));


%% ========================================================
% Association Summary
%=========================================================

if ~isempty(AssociatedPairs)

    disp(' ');
    disp('Associated Detection -> Track');

    for k = 1:size(AssociatedPairs,1)

        DetectionIndex = ...
            AssociatedPairs(k,1);

        TrackIndex = ...
            AssociatedPairs(k,2);

        TrackID = ...
            Association.TrackIndices(DetectionIndex);

        fprintf( ...
            'Detection %d -> Track %d\n', ...
            DetectionIndex, ...
            TrackID);

    end

end


%% ========================================================
% New Detection Summary
%=========================================================

if ~isempty(Association.UnassociatedDetections)

    disp(' ');
    disp('New Detections');

    for k = 1:length( ...
            Association.UnassociatedDetections)

        DetectionIndex = ...
            Association.UnassociatedDetections(k);

        fprintf( ...
            'Detection %d -> NEW\n', ...
            DetectionIndex);

    end

end

end


%% ========================================================
% Helper Function
% Get Range
%=========================================================

function Range = GetRange(Object)

if isfield(Object,'Range')

    Range = ...
        double(Object.Range);

elseif isfield(Object,'FilteredRange')

    Range = ...
        double(Object.FilteredRange);

elseif isfield(Object,'PredictedRange')

    Range = ...
        double(Object.PredictedRange);

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
% Get Velocity
%=========================================================

function Velocity = GetVelocity(Object)

if isfield(Object,'Velocity')

    Velocity = ...
        double(Object.Velocity);

elseif isfield(Object,'FilteredVelocity')

    Velocity = ...
        double(Object.FilteredVelocity);

elseif isfield(Object,'PredictedVelocity')

    Velocity = ...
        double(Object.PredictedVelocity);

elseif isfield(Object,'Speed')

    Velocity = ...
        double(Object.Speed);

else

    Velocity = 0;

end

end