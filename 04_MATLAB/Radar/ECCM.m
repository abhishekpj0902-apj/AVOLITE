function ECCMControl = ECCM(Environment,ReceiverControl)

%=========================================================
% SARRS STUDIO
% Electronic Counter-Counter Measures (ECCM)
%
% Handles:
%   • Noise Jamming
%   • Spot Jamming
%   • Barrage Jamming
%   • DRFM Jamming
%
%=========================================================

%% Default Configuration

ECCMControl.Enabled = false;

ECCMControl.Mode = "Normal";

ECCMControl.Filter = ReceiverControl.Filter;

ECCMControl.Bandwidth = ReceiverControl.Bandwidth;

ECCMControl.FrequencyHop = false;

ECCMControl.RandomPRI = false;

ECCMControl.RandomPulseWidth = false;

ECCMControl.BeamNulling = false;

ECCMControl.NotchFilter = false;

ECCMControl.AdaptiveThreshold = false;

ECCMControl.Description = "No Electronic Attack";

%% ------------------------------------------
% Jamming Detection
%% ------------------------------------------

switch string(Environment.Jamming)

    case "OFF"

        return

    case "Noise Jammer"

        ECCMControl.Enabled = true;

        ECCMControl.Mode = "Noise ECCM";

        ECCMControl.NotchFilter = true;

        ECCMControl.AdaptiveThreshold = true;

        ECCMControl.Description = ...
            "Noise jammer suppressed";

    case "Spot Jammer"

        ECCMControl.Enabled = true;

        ECCMControl.Mode = "Spot ECCM";

        ECCMControl.FrequencyHop = true;

        ECCMControl.NotchFilter = true;

        ECCMControl.Description = ...
            "Frequency hopping enabled";

    case "Barrage Jammer"

        ECCMControl.Enabled = true;

        ECCMControl.Mode = "Barrage ECCM";

        ECCMControl.FrequencyHop = true;

        ECCMControl.RandomPRI = true;

        ECCMControl.Description = ...
            "Wideband anti-jam mode";

    case "DRFM Jammer"

        ECCMControl.Enabled = true;

        ECCMControl.Mode = "DRFM ECCM";

        ECCMControl.RandomPRI = true;

        ECCMControl.RandomPulseWidth = true;

        ECCMControl.BeamNulling = true;

        ECCMControl.Description = ...
            "Anti-deception mode";

    otherwise

        ECCMControl.Enabled = true;

        ECCMControl.Mode = "Unknown Jammer";

        ECCMControl.FrequencyHop = true;

        ECCMControl.RandomPRI = true;

        ECCMControl.NotchFilter = true;

        ECCMControl.Description = ...
            "Generic ECCM";

end

%% ------------------------------------------
% Update Receiver Parameters
%% ------------------------------------------

if ECCMControl.Enabled

    ECCMControl.Filter = "Adaptive";

    ECCMControl.Bandwidth = ...
        ReceiverControl.Bandwidth * 0.8;

end

end