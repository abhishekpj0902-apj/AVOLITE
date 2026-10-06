function ResultViewer(Environment,...
                      Mission,...
                      Radar,...
                      Target,...
                      Matched,...
                      CFAR,...
                      TrackData)

%=========================================================
% SARRS STUDIO
% Final Mission Result Viewer
%=========================================================

figure(...
    'Name','SARRS Mission Summary',...
    'NumberTitle','off',...
    'Color','w',...
    'Position',[150 80 900 700]);

%% Title

annotation('textbox',...
    [0.15 0.93 0.7 0.05],...
    'String','SARRS STUDIO - FINAL MISSION REPORT',...
    'HorizontalAlignment','center',...
    'FontSize',18,...
    'FontWeight','bold',...
    'EdgeColor','none');

%% =====================================================
% Mission
%=====================================================

subplot(3,2,1)

axis off

text(0,1,'MISSION','FontWeight','bold','FontSize',12)

text(0,0.85,['Mode : ',char(Mission.Mode)])

text(0,0.75,['Type : ',char(Mission.Type)])

text(0,0.65,['Priority : ',char(Mission.Priority)])

text(0,0.55,['Status : ',char(Mission.Status)])

text(0,0.45,...
    ['Duration : ',num2str(Mission.Duration),' sec']);

%% =====================================================
% Radar
%=====================================================

subplot(3,2,2)

axis off

text(0,1,'RADAR','FontWeight','bold','FontSize',12)

text(0,0.85,...
    ['Frequency : ',...
    num2str(Radar.Frequency/1e9),' GHz'])

text(0,0.75,...
    ['Power : ',num2str(Radar.Power),' W'])

text(0,0.65,...
    ['Gain : ',num2str(Radar.Gain),' dB'])

text(0,0.55,...
    ['Bandwidth : ',...
    num2str(Radar.Bandwidth/1e6),' MHz'])

text(0,0.45,...
    ['PRF : ',num2str(Radar.PRF)])

%% =====================================================
% Environment
%=====================================================

subplot(3,2,3)

axis off

text(0,1,'ENVIRONMENT','FontWeight','bold','FontSize',12)

text(0,0.85,...
    ['Temperature : ',...
    num2str(Environment.Temperature),' C'])

text(0,0.75,...
    ['Humidity : ',...
    num2str(Environment.Humidity),' %'])

text(0,0.65,...
    ['Wind : ',...
    num2str(Environment.Wind),' m/s'])

text(0,0.55,...
    ['Terrain : ',...
    char(Environment.Terrain)])

text(0,0.45,...
    ['Jamming : ',...
    char(Environment.Jamming)])

%% =====================================================
% Detection Summary
%=====================================================

subplot(3,2,4)

bar([ ...
    length(Target), ...
    Matched.NumberOfPeaks,...
    CFAR.NumberOfTargets,...
    length(TrackData)])

grid on

xticklabels({'Targets','Matched','CFAR','Tracks'})

ylabel('Count')

title('Detection Summary')

%% =====================================================
% Range Plot
%=====================================================

subplot(3,2,5)

if ~isempty(Matched.PeakRanges)

    stem(Matched.PeakRanges/1000,...
         Matched.Peaks,...
         'filled');

    xlabel('Range (km)')

    ylabel('Amplitude')

    title('Detected Targets')

    grid on

else

    text(0.2,0.5,'No Targets')

    axis off

end

%% =====================================================
% Status
%=====================================================

subplot(3,2,6)

axis off

text(0,1,'SIMULATION STATUS',...
    'FontWeight','bold',...
    'FontSize',12)

text(0,0.80,...
    ['Targets Created : ',...
    num2str(length(Target))])

text(0,0.70,...
    ['Matched Peaks : ',...
    num2str(Matched.NumberOfPeaks)])

text(0,0.60,...
    ['CFAR Targets : ',...
    num2str(CFAR.NumberOfTargets)])

text(0,0.50,...
    ['Tracks : ',...
    num2str(length(TrackData))])

if length(TrackData)>0

    text(0,0.30,...
        'MISSION SUCCESS',...
        'Color',[0 0.6 0],...
        'FontWeight','bold',...
        'FontSize',14);

else

    text(0,0.30,...
        'NO TARGETS TRACKED',...
        'Color','r',...
        'FontWeight','bold',...
        'FontSize',14);

end

sgtitle('SARRS Studio Final Mission Report')