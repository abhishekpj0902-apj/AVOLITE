function Allocation = ResourceAllocator(Priority)

%=========================================================
% SARRS STUDIO
% Resource Allocator
%
% Allocates Radar Resources to Targets
%=========================================================

Allocation = struct([]);

if isempty(Priority)
    return;
end

for i = 1:length(Priority)

    Allocation(i).TrackID = Priority(i).TrackID;

    Allocation(i).Priority = Priority(i).Priority;

    Allocation(i).ThreatLevel = ...
        Priority(i).ThreatLevel;

    switch Priority(i).ThreatLevel

        case "HIGH"

            Allocation(i).BeamTime = 100;
            Allocation(i).TrackingRate = 50;
            Allocation(i).TransmitPower = 100;
            Allocation(i).ReceiverGain = 45;
            Allocation(i).RadarMode = "TRACK";

        case "MEDIUM"

            Allocation(i).BeamTime = 60;
            Allocation(i).TrackingRate = 20;
            Allocation(i).TransmitPower = 70;
            Allocation(i).ReceiverGain = 40;
            Allocation(i).RadarMode = "SCAN";

        otherwise

            Allocation(i).BeamTime = 30;
            Allocation(i).TrackingRate = 5;
            Allocation(i).TransmitPower = 40;
            Allocation(i).ReceiverGain = 35;
            Allocation(i).RadarMode = "SEARCH";

    end

end

end