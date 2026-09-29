function Tracks = RangeAssociation(AllPRFDetections)

% ============================================================
% RANGE ASSOCIATION FOR MULTI-PRF DETECTIONS
% ============================================================

RangeTolerance = 300;    % metres

Ranges = AllPRFDetections.Range_m;
Used = false(height(AllPRFDetections), 1);

TrackID = zeros(height(AllPRFDetections), 1);
NumberOfTracks = 0;

for i = 1:height(AllPRFDetections)

    if Used(i)
        continue;
    end

    NumberOfTracks = NumberOfTracks + 1;

    ReferenceRange = Ranges(i);

    RangeMask = ...
        abs(Ranges - ReferenceRange) <= RangeTolerance & ...
        ~Used;

    Members = find(RangeMask);

    Used(Members) = true;
    TrackID(Members) = NumberOfTracks;

end

AllPRFDetections.TrackID = TrackID;

Tracks = AllPRFDetections;

fprintf("\n==============================================\n");
fprintf("MULTI-PRF RANGE ASSOCIATION\n");
fprintf("==============================================\n");

fprintf("Total detections : %d\n", height(Tracks));
fprintf("Range tracks     : %d\n", NumberOfTracks);

disp(Tracks);

fprintf("==============================================\n\n");

end