function AScope(Matched)

%=========================================================
% SARRS STUDIO
% A-Scope Display
%
% Displays:
%   Range vs Echo Amplitude
%=========================================================

figure(...
    'Name','A-Scope',...
    'NumberTitle','off',...
    'Color','w');

plot(...
    Matched.RangeAxis/1000,...
    abs(Matched.Output),...
    'b',...
    'LineWidth',1.5);

hold on

if Matched.NumberOfPeaks > 0

    plot(...
        Matched.PeakRanges/1000,...
        Matched.Peaks,...
        'rv',...
        'MarkerFaceColor','r',...
        'MarkerSize',8);

end

xlabel('Range (km)');
ylabel('Amplitude');

title('Radar A-Scope');

grid on;

xlim([0 max(Matched.RangeAxis)/1000]);

hold off

end