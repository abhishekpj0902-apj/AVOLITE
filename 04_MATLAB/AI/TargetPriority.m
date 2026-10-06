function Priority = TargetPriority(Threat)

%=========================================================
% SARRS STUDIO
% Target Priority
%
% Sorts Targets by Threat Score
%=========================================================

Priority = Threat;

if isempty(Priority)
    return;
end

Scores = [Priority.ThreatScore];

[~, Order] = sort(Scores,'descend');

Priority = Priority(Order);

for i = 1:length(Priority)

    Priority(i).Priority = i;

    switch Priority(i).ThreatLevel

        case "HIGH"
            Priority(i).RecommendedAction = ...
                "Immediate Tracking";

        case "MEDIUM"
            Priority(i).RecommendedAction = ...
                "Continuous Monitoring";

        otherwise
            Priority(i).RecommendedAction = ...
                "Routine Surveillance";

    end

end

end