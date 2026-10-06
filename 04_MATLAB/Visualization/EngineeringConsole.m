function EngineeringConsole( ...
    Environment,...
    Mission,...
    Radar,...
    Receiver,...
    Matched,...
    CFAR,...
    TrackData)

%=========================================================
% SARRS STUDIO
% Engineering Console
%
% Engineering Diagnostics Window
%=========================================================

figure(...
    'Name','Engineering Console',...
    'NumberTitle','off',...
    'Color',[0.1 0.1 0.1],...
    'Position',[150 80 1100 700]);

axis off

%% ======================================================
% Title
%======================================================

text(0.02,0.97,...
    'SARRS STUDIO ENGINEERING CONSOLE',...
    'Color','y',...
    'FontSize',18,...
    'FontWeight','bold');

%% ======================================================
% Radar Parameters
%======================================================

text(0.02,0.90,'RADAR','Color','c',...
    'FontWeight','bold','FontSize',14);

text(0.02,0.86,sprintf('Frequency        : %.2f GHz',Radar.Frequency/1e9),'Color','w');
text(0.02,0.83,sprintf('Transmit Power   : %.0f W',Radar.Power),'Color','w');
text(0.02,0.80,sprintf('Gain             : %.1f dB',Radar.Gain),'Color','w');
text(0.02,0.77,sprintf('Bandwidth        : %.1f MHz',Radar.Bandwidth/1e6),'Color','w');
text(0.02,0.74,sprintf('PRF              : %.0f Hz',Radar.PRF),'Color','w');
text(0.02,0.71,sprintf('Pulse Width      : %.2f us',Radar.PulseWidth*1e6),'Color','w');
text(0.02,0.68,sprintf('Range Resolution : %.2f m',Radar.RangeResolution),'Color','w');

%% ======================================================
% Environment
%======================================================

text(0.36,0.90,'ENVIRONMENT','Color','c',...
    'FontWeight','bold','FontSize',14);

text(0.36,0.86,sprintf('Temperature : %.1f C',Environment.Temperature),'Color','w');
text(0.36,0.83,sprintf('Humidity    : %.1f %%',Environment.Humidity),'Color','w');
text(0.36,0.80,sprintf('Pressure    : %.0f hPa',Environment.Pressure),'Color','w');
text(0.36,0.77,sprintf('Wind Speed  : %.1f',Environment.Wind),'Color','w');
text(0.36,0.74,['Terrain     : ',char(Environment.Terrain)],'Color','w');
text(0.36,0.71,['Jamming     : ',char(Environment.Jamming)],'Color','w');
text(0.36,0.68,['Clutter     : ',char(Environment.Clutter)],'Color','w');

%% ======================================================
% Mission
%======================================================

text(0.70,0.90,'MISSION','Color','c',...
    'FontWeight','bold','FontSize',14);

text(0.70,0.86,['Mode     : ',char(Mission.Mode)],'Color','w');
text(0.70,0.83,['Type     : ',char(Mission.Type)],'Color','w');
text(0.70,0.80,['Priority : ',char(Mission.Priority)],'Color','w');
text(0.70,0.77,sprintf('Max Range : %.0f m',Mission.MaxRange),'Color','w');

%% ======================================================
% Receiver
%======================================================

text(0.02,0.56,'RECEIVER','Color','c',...
    'FontWeight','bold','FontSize',14);

text(0.02,0.52,sprintf('LNA Gain      : %.1f dB',Receiver.LNAGain),'Color','w');
text(0.02,0.49,sprintf('Noise Figure  : %.1f dB',Receiver.NoiseFigure),'Color','w');
text(0.02,0.46,sprintf('IF Gain       : %.1f dB',Receiver.IFGain),'Color','w');
text(0.02,0.43,sprintf('Total Gain    : %.1f dB',Receiver.TotalGain),'Color','w');

%% ======================================================
% Detection Statistics
%======================================================

text(0.36,0.56,'DETECTION','Color','c',...
    'FontWeight','bold','FontSize',14);

text(0.36,0.52,sprintf('Matched Peaks : %d',Matched.NumberOfPeaks),'Color','w');
text(0.36,0.49,sprintf('CFAR Targets  : %d',CFAR.NumberOfTargets),'Color','w');
text(0.36,0.46,sprintf('Noise Floor   : %.4f',CFAR.NoiseFloor),'Color','w');
text(0.36,0.43,sprintf('Estimated SNR : %.1f dB',CFAR.EstimatedSNR),'Color','w');

%% ======================================================
% Tracking
%======================================================

text(0.70,0.56,'TRACKING','Color','c',...
    'FontWeight','bold','FontSize',14);

text(0.70,0.52,sprintf('Tracks : %d',length(TrackData)),'Color','w');

if isempty(TrackData)

    text(0.70,0.48,'Status : NO TRACKS','Color','r');

else

    text(0.70,0.48,'Status : TRACKING','Color','g');

end

%% ======================================================
% Footer
%======================================================

text(0.02,0.08,...
    datestr(now),...
    'Color',[0.8 0.8 0.8]);

text(0.55,0.08,...
    'SARRS Smart AI Radar Research Simulator',...
    'Color','y',...
    'FontWeight','bold');