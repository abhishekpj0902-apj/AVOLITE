function DetectionData = Detection(CFARResult)

%=========================================================
% SARRS STUDIO
% Detection Module
% Uses CFAR Detection Results
%=========================================================

DetectionData.Signal = CFARResult.Signal;

DetectionData.Threshold = CFARResult.Threshold;

DetectionData.Index = CFARResult.Index;

DetectionData.TargetDetected = CFARResult.TargetDetected;

% Number of detections
DetectionData.NumberOfTargets = length(CFARResult.Index);

end