function RadarState = RadarModes(Mission,Environment,Tracking,AI)

%=========================================================
% SARRS STUDIO
% Radar Modes Manager
%
% Determines the operating mode of the radar.
%
% Search
% Track While Scan
% Single Target Track
% ECCM
% Weather
% Standby
%
%=========================================================

%% Default State

RadarState.Mode = "Search";
RadarState.Reason = "Default";
RadarState.Priority = 1;

RadarState.Search = true;
RadarState.Track = false;
RadarState.ECCM = false;
RadarState.Weather = false;

%% --------------------------------------------------------
% Mission Override
%% --------------------------------------------------------

if isfield(Mission,"Mode")

    switch string(Mission.Mode)

        case "Standby"

            RadarState.Mode = "Standby";
            RadarState.Reason = "Mission";

            return

        case "Weather"

            RadarState.Mode = "Weather";
            RadarState.Reason = "Mission";
            RadarState.Weather = true;

            return

    end

end

%% --------------------------------------------------------
% Environment Check
%% --------------------------------------------------------

if isfield(Environment,"Jamming")

    if Environment.Jamming ~= "OFF"

        RadarState.Mode = "ECCM";

        RadarState.Reason = "Jamming";

        RadarState.ECCM = true;

        RadarState.Priority = 5;

        return

    end

end

%% --------------------------------------------------------
% Number of Tracks
%% --------------------------------------------------------

NumberOfTracks = length(Tracking);

if NumberOfTracks==0

    RadarState.Mode = "Search";

    RadarState.Reason = "No Target";

    RadarState.Priority = 1;

    return

end

%% --------------------------------------------------------
% Highest Threat
%% --------------------------------------------------------

HighestThreat = "LOW";

for k=1:length(AI)

    if AI(k).ThreatLevel=="HIGH"

        HighestThreat="HIGH";

        break

    end

    if AI(k).ThreatLevel=="MEDIUM"

        HighestThreat="MEDIUM";

    end

end

%% --------------------------------------------------------
% Threat Based Mode Selection
%% --------------------------------------------------------

switch HighestThreat

    case "HIGH"

        RadarState.Mode = "Single Target Track";

        RadarState.Track = true;

        RadarState.Search = false;

        RadarState.Priority = 10;

        RadarState.Reason = "High Threat";

    case "MEDIUM"

        RadarState.Mode = "Track While Scan";

        RadarState.Track = true;

        RadarState.Priority = 7;

        RadarState.Reason = "Medium Threat";

    otherwise

        RadarState.Mode = "Search";

        RadarState.Search = true;

        RadarState.Priority = 2;

        RadarState.Reason = "Routine Surveillance";

end

end