function ReceiverControl = CognitiveReceiver(Environment,AI)

%=========================================================
% SARRS STUDIO
% Cognitive Receiver
%
% Adaptive Cognitive Radar Receiver
% Multi-Target Version
%
% Inputs:
%   Environment  -> Environment Structure
%   AI           -> AI Decision Structure Array
%
% Output:
%   ReceiverControl
%=========================================================

%% ========================================================
% Default Receiver Configuration
%% ========================================================

ReceiverControl = struct;

ReceiverControl.LNAGain      = 30;
ReceiverControl.IFGain       = 40;
ReceiverControl.Bandwidth    = 20e6;

ReceiverControl.AGC          = "ON";
ReceiverControl.Filter       = "Normal";
ReceiverControl.Mode         = "Normal";

ReceiverControl.HighestThreat = "LOW";
ReceiverControl.State         = "Monitoring";

%% ========================================================
% Environment Adaptation
%% ========================================================

%--------------------------
% Rain Compensation
%--------------------------

if isfield(Environment,"Rain")

    switch Environment.Rain

        case 'Heavy'

            ReceiverControl.LNAGain = ...
                ReceiverControl.LNAGain + 6;

            ReceiverControl.Mode = ...
                "Rain Mode";

        case 'Moderate'

            ReceiverControl.LNAGain = ...
                ReceiverControl.LNAGain + 3;

        otherwise

    end

end

%--------------------------
% Fog Compensation
%--------------------------

if isfield(Environment,"Fog")

    switch Environment.Fog

        case 'Dense'

            ReceiverControl.LNAGain = ...
                ReceiverControl.LNAGain + 2;

        case 'Light'

            ReceiverControl.LNAGain = ...
                ReceiverControl.LNAGain + 1;

        otherwise

    end

end

%% ========================================================
% Electronic Counter Counter Measures (ECCM)
%% ========================================================

if isfield(Environment,"Jamming")

    switch Environment.Jamming

        case 'Noise Jammer'

            ReceiverControl.Filter = ...
                "Adaptive Notch";

            ReceiverControl.Bandwidth = 10e6;

            ReceiverControl.Mode = ...
                "Anti Jam";

        case 'Spot Jammer'

            ReceiverControl.Filter = ...
                "Adaptive MTI";

            ReceiverControl.Mode = ...
                "ECCM";

        case 'Barrage Jammer'

            ReceiverControl.Filter = ...
                "Adaptive MTI";

            ReceiverControl.Mode = ...
                "ECCM";

        case 'DRFM Jammer'

            ReceiverControl.Filter = ...
                "Adaptive MTI";

            ReceiverControl.Mode = ...
                "ECCM";

        otherwise

    end

end

%% ========================================================
% Multi Target Threat Evaluation
%% ========================================================

HighestThreat = "LOW";

if ~isempty(AI)

    for i = 1:length(AI)

        if ~isfield(AI(i),"ThreatLevel")
            continue
        end

        switch upper(string(AI(i).ThreatLevel))

            case "HIGH"

                HighestThreat = "HIGH";
                break

            case "MEDIUM"

                if HighestThreat ~= "HIGH"

                    HighestThreat = "MEDIUM";

                end

        end

    end

end

ReceiverControl.HighestThreat = HighestThreat;

%% ========================================================
% Receiver Optimization
%% ========================================================

switch HighestThreat

    case "HIGH"

        ReceiverControl.LNAGain = ...
            ReceiverControl.LNAGain + 5;

        ReceiverControl.IFGain = 55;

        ReceiverControl.AGC = "FAST";

        ReceiverControl.Mode = ...
            "High Threat";

    case "MEDIUM"

        ReceiverControl.LNAGain = ...
            ReceiverControl.LNAGain + 2;

        ReceiverControl.IFGain = 45;

        ReceiverControl.AGC = "ON";

        ReceiverControl.Mode = ...
            "Medium Threat";

    otherwise

        ReceiverControl.IFGain = 40;

end

%% ========================================================
% Performance Feedback
%% ========================================================

if isfield(Environment,"DetectionRate")

    if Environment.DetectionRate < 80

        ReceiverControl.LNAGain = ...
            ReceiverControl.LNAGain + 2;

        ReceiverControl.IFGain = ...
            ReceiverControl.IFGain + 3;

        ReceiverControl.Mode = ...
            "Recovery";

    end

end

%% ========================================================
% Cognitive State Machine
%% ========================================================

switch ReceiverControl.Mode

    case "High Threat"

        ReceiverControl.State = ...
            "Attack";

    case "Medium Threat"

        ReceiverControl.State = ...
            "Tracking";

    case "Recovery"

        ReceiverControl.State = ...
            "Learning";

    case "ECCM"

        ReceiverControl.State = ...
            "Counter Jamming";

    case "Anti Jam"

        ReceiverControl.State = ...
            "Counter Jamming";

    case "Rain Mode"

        ReceiverControl.State = ...
            "Weather Compensation";

    otherwise

        ReceiverControl.State = ...
            "Monitoring";

end

%% ========================================================
% Receiver Limits
%% ========================================================

ReceiverControl.LNAGain = ...
    max(20,min(40,ReceiverControl.LNAGain));

ReceiverControl.IFGain = ...
    max(30,min(60,ReceiverControl.IFGain));

%% ========================================================
% Time Stamp
%% ========================================================

ReceiverControl.Timestamp = datetime('now');

end