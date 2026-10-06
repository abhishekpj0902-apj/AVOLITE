function BScope(TrackData)

%=========================================================
% SARRS STUDIO
% B-Scope Display
%
% Range vs Azimuth
%=========================================================

figure(...
    'Name','B-Scope',...
    'NumberTitle','off',...
    'Color','w');

hold on
grid on

xlabel('Azimuth (deg)');
ylabel('Range (km)');
title('Radar B-Scope');

if isempty(TrackData)

    text(180,75,'NO TARGETS',...
        'HorizontalAlignment','center',...
        'FontSize',14,...
        'Color','r');

    xlim([0 360]);
    ylim([0 150]);

    return

end

N = length(TrackData);

Azimuth = zeros(N,1);
Range = zeros(N,1);

for k = 1:N

    Range(k) = TrackData(k).Range/1000;

    % Temporary simulated azimuth
    Azimuth(k) = (k-1)*360/N;

end

scatter(...
    Azimuth,...
    Range,...
    120,...
    'filled',...
    'b');

for k = 1:N

    text(...
        Azimuth(k)+3,...
        Range(k),...
        sprintf('T%d',k),...
        'FontSize',10,...
        'Color','k');

end

xlim([0 360]);
ylim([0 150]);

set(gca,'YDir','reverse');

hold off

end