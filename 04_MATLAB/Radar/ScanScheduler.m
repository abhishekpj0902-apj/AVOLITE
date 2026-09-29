function Scan = ScanScheduler(RadarState,Tracking,AI)

%=========================================================
% SARRS STUDIO
% Scan Scheduler
%
% Radar Resource Management (RRM)
%
% Determines:
%   • Beam Priority
%   • Revisit Time
%   • Dwell Time
%   • Scan Order
%
%=========================================================

%% Initialization

Scan = struct([]);

NumTargets = length(Tracking);

if NumTargets == 0
    return
end

%% Generate Scan Schedule

for k = 1:NumTargets

    Scan(k).TargetID = Tracking(k).ID;

    Scan(k).Range = Tracking(k).Range;

    Scan(k).Threat = AI(k).ThreatLevel;

    Scan(k).Mode = RadarState.Mode;

    %% ------------------------------
    % Priority
    %% ------------------------------

    switch AI(k).ThreatLevel

        case "HIGH"

            Scan(k).Priority = 1;

            Scan(k).RevisitTime = 0.020;      % 20 ms

            Scan(k).DwellTime = 5e-3;

        case "MEDIUM"

            Scan(k).Priority = 2;

            Scan(k).RevisitTime = 0.100;      % 100 ms

            Scan(k).DwellTime = 3e-3;

        otherwise

            Scan(k).Priority = 3;

            Scan(k).RevisitTime = 0.500;      % 500 ms

            Scan(k).DwellTime = 1e-3;

    end

end

%% Sort by Priority

Priority = [Scan.Priority];

[~,idx] = sort(Priority);

Scan = Scan(idx);

end