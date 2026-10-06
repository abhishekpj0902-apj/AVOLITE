function AIData = AI(TrackData)

%=========================================
% AI Decision Engine
%=========================================

AIData.TargetType = TrackData.Status;

AIData.Range = TrackData.Range;

if TrackData.Range < 20000

    AIData.ThreatLevel = 'HIGH';
    AIData.Action = 'ENGAGE';

elseif TrackData.Range < 50000

    AIData.ThreatLevel = 'MEDIUM';
    AIData.Action = 'TRACK';

else

    AIData.ThreatLevel = 'LOW';
    AIData.Action = 'MONITOR';

end

end