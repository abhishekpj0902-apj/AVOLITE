function Track = Tracking(TargetData,Detection)

%=========================================================
% SARRS STUDIO
% Module 9
% Target Tracking
%=========================================================

Track.ID = 1;

Track.Range = TargetData.Distance(1);

Track.X = TargetData.X(1);

Track.Y = TargetData.Y(1);

Track.Z = TargetData.Z(1);

Track.Velocity = TargetData.Velocity;

Track.Heading = TargetData.Heading;

Track.Status = "TRACK";

Track.Time = TargetData.Time;

Track.HistoryX = TargetData.X;

Track.HistoryY = TargetData.Y;

Track.HistoryZ = TargetData.Z;

Track.Confidence = 100;

end