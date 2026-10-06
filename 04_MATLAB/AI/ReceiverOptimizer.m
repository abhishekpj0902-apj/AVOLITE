function ReceiverControl = ReceiverOptimizer(Mission,Radar)

%=========================================================
% SARRS STUDIO
% Receiver Optimizer
%
% Adaptive Receiver Control
%=========================================================

ReceiverControl.LNAGain = 30;
ReceiverControl.IFGain = 40;
ReceiverControl.Bandwidth = Radar.Bandwidth;

ReceiverControl.AGC = "ON";
ReceiverControl.Filter = "Normal";
ReceiverControl.Mode = "Normal";

ReceiverControl.HighestThreat = Mission.HighestThreat;

switch Mission.HighestThreat

    case "HIGH"

        ReceiverControl.LNAGain = 35;
        ReceiverControl.IFGain = 50;

        ReceiverControl.Filter = "Narrow";
        ReceiverControl.Mode = "High Threat";

    case "MEDIUM"

        ReceiverControl.LNAGain = 32;
        ReceiverControl.IFGain = 45;

        ReceiverControl.Filter = "Adaptive";
        ReceiverControl.Mode = "Medium Threat";

    otherwise

        ReceiverControl.LNAGain = 30;
        ReceiverControl.IFGain = 40;

        ReceiverControl.Filter = "Normal";
        ReceiverControl.Mode = "Normal";

end

end