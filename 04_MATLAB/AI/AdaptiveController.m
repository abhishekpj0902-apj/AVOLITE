function Receiver = AdaptiveController(Receiver,ReceiverControl)

%=========================================================
% SARRS STUDIO
% Adaptive Controller
%
% Applies AI receiver settings
%=========================================================

Receiver.LNAGain = ReceiverControl.LNAGain;
Receiver.IFGain = ReceiverControl.IFGain;

Receiver.Bandwidth = ReceiverControl.Bandwidth;

Receiver.AGC = ReceiverControl.AGC;
Receiver.Filter = ReceiverControl.Filter;
Receiver.Mode = ReceiverControl.Mode;

Receiver.Status = "Adaptive";

end