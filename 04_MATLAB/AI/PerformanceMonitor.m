function Performance = PerformanceMonitor(Detection,Radar)

%=========================================================
% SARRS STUDIO
% Performance Monitor
%
% Monitors radar performance
%=========================================================

Performance = struct;

Performance.TotalTargets = Detection.NumberOfTargets;

Performance.TargetDetected = Detection.TargetDetected;

if Detection.TargetDetected

    Performance.DetectionRate = 100;

else

    Performance.DetectionRate = 0;

end

Performance.Power = Radar.Power;

Performance.Bandwidth = Radar.Bandwidth;

Performance.MaximumRange = Radar.MaximumRange;

Performance.Status = "NORMAL";

if Performance.DetectionRate < 80

    Performance.Status = "LOW PERFORMANCE";

elseif Performance.DetectionRate == 100

    Performance.Status = "OPTIMAL";

end

end