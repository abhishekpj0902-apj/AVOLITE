function Mission = MissionPlanner(Allocation)

%=========================================================
% SARRS STUDIO
% Mission Planner
%
% Cognitive Radar Mission Decision Engine
%=========================================================

Mission.Mode = "SEARCH";
Mission.Command = "Continue Searching";
Mission.HighestThreat = "LOW";
Mission.NumberOfTargets = 0;

if isempty(Allocation)
    return;
end

Mission.NumberOfTargets = length(Allocation);

highest = "LOW";

for i = 1:length(Allocation)

    if Allocation(i).ThreatLevel == "HIGH"
        highest = "HIGH";
        break;

    elseif Allocation(i).ThreatLevel == "MEDIUM"

        if highest ~= "HIGH"
            highest = "MEDIUM";
        end

    end

end

Mission.HighestThreat = highest;

switch highest

    case "HIGH"

        Mission.Mode = "TRACK";
        Mission.Command = ...
            "Lock Highest Threat Target";

    case "MEDIUM"

        Mission.Mode = "TRACK WHILE SCAN";
        Mission.Command = ...
            "Track Priority Targets";

    otherwise

        Mission.Mode = "SEARCH";
        Mission.Command = ...
            "Continue Surveillance";

end

end