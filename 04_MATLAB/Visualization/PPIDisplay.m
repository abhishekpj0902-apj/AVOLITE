function PPIDisplay(TrackData, Radar)
%=========================================================
% SARRS STUDIO
% FINAL 360-DEGREE PPI DISPLAY
%
% Priority:
%   1. Use actual Azimuth/Angle if available in TrackData
%   2. Otherwise use X/Y position if available
%   3. Otherwise DO NOT invent an angle
%
% This version does NOT use:
%       Azimuth = (k-1)*360/N
%
% because that was only an artificial visualization.
%=========================================================

%% --------------------------------------------------------
% Validate Radar
% ---------------------------------------------------------

if nargin < 2 || isempty(Radar)

    warning('SARRS PPI: Radar data not supplied.');

    MaxRangeKm = 100;

else

    if isfield(Radar,'MaximumRange') && ...
            ~isempty(Radar.MaximumRange)

        MaxRangeKm = Radar.MaximumRange / 1000;

    else

        MaxRangeKm = 100;

    end

end

if MaxRangeKm <= 0 || ~isfinite(MaxRangeKm)

    MaxRangeKm = 100;

end


%% --------------------------------------------------------
% Create Figure
% ---------------------------------------------------------

figure( ...
    'Name','SARRS - 360 Degree PPI', ...
    'NumberTitle','off', ...
    'Color','k');

hold on;
axis equal;
grid on;

ax = gca;

set(ax, ...
    'Color','k', ...
    'XColor','w', ...
    'YColor','w', ...
    'GridColor',[0.2 0.6 0.2]);

title( ...
    'SARRS 360° PLAN POSITION INDICATOR', ...
    'Color','w', ...
    'FontSize',14, ...
    'FontWeight','bold');

xlabel('East / X (km)','Color','w');
ylabel('North / Y (km)','Color','w');


%% --------------------------------------------------------
% Range Rings
% ---------------------------------------------------------

theta = linspace(0,2*pi,720);

RingSpacing = 25;

for R = RingSpacing:RingSpacing:MaxRangeKm

    Xring = R*cos(theta);
    Yring = R*sin(theta);

    plot( ...
        Xring, ...
        Yring, ...
        'g:', ...
        'LineWidth',0.8);

end


%% --------------------------------------------------------
% 360 Degree Azimuth Lines
% ---------------------------------------------------------

for ang = 0:30:330

    Xline = ...
        [0 MaxRangeKm*cosd(ang)];

    Yline = ...
        [0 MaxRangeKm*sind(ang)];

    plot( ...
        Xline, ...
        Yline, ...
        'g:', ...
        'LineWidth',0.5);

end


%% --------------------------------------------------------
% Radar Location
% ---------------------------------------------------------

plot( ...
    0, ...
    0, ...
    '^', ...
    'MarkerFaceColor','w', ...
    'MarkerEdgeColor','w', ...
    'MarkerSize',9);

text( ...
    0, ...
    2, ...
    'RADAR', ...
    'Color','w', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');


%% --------------------------------------------------------
% Check Target Data
% ---------------------------------------------------------

if nargin < 1 || isempty(TrackData)

    text( ...
        0, ...
        -5, ...
        'NO TARGET TRACKS', ...
        'Color','r', ...
        'HorizontalAlignment','center', ...
        'FontSize',14, ...
        'FontWeight','bold');

    xlim([-MaxRangeKm MaxRangeKm]);
    ylim([-MaxRangeKm MaxRangeKm]);

    hold off;
    return;

end


%% --------------------------------------------------------
% Number of Tracks
% ---------------------------------------------------------

N = numel(TrackData);

fprintf('\n');
fprintf('====================================================\n');
fprintf('          SARRS 360 DEGREE PPI\n');
fprintf('====================================================\n');


%% --------------------------------------------------------
% Plot Tracks
% ---------------------------------------------------------

TargetsPlotted = 0;

for k = 1:N

    %% ----------------------------------------------------
    % Range
    % -----------------------------------------------------

    Range_m = [];

    if isfield(TrackData(k),'Range')

        Range_m = TrackData(k).Range;

    elseif isfield(TrackData(k),'Range_m')

        Range_m = TrackData(k).Range_m;

    end


    if isempty(Range_m) || ~isfinite(Range_m)

        continue;

    end


    RangeKm = Range_m / 1000;


    %% ----------------------------------------------------
    % Try to find REAL AZIMUTH
    % -----------------------------------------------------

    AzimuthDeg = [];


    % ---- Option 1: Azimuth ------------------------------

    if isfield(TrackData(k),'Azimuth') && ...
            ~isempty(TrackData(k).Azimuth)

        AzimuthDeg = TrackData(k).Azimuth;

    elseif isfield(TrackData(k),'AzimuthDeg') && ...
            ~isempty(TrackData(k).AzimuthDeg)

        AzimuthDeg = TrackData(k).AzimuthDeg;

    elseif isfield(TrackData(k),'Angle') && ...
            ~isempty(TrackData(k).Angle)

        AzimuthDeg = TrackData(k).Angle;

    elseif isfield(TrackData(k),'AngleDeg') && ...
            ~isempty(TrackData(k).AngleDeg)

        AzimuthDeg = TrackData(k).AngleDeg;

    elseif isfield(TrackData(k),'Bearing') && ...
            ~isempty(TrackData(k).Bearing)

        AzimuthDeg = TrackData(k).Bearing;

    end


    %% ----------------------------------------------------
    % Option 2: Calculate azimuth from X/Y
    % -----------------------------------------------------

    if isempty(AzimuthDeg)

        X_m = [];
        Y_m = [];

        if isfield(TrackData(k),'X')
            X_m = TrackData(k).X;
        elseif isfield(TrackData(k),'Position')
            P = TrackData(k).Position;

            if numel(P) >= 2

                X_m = P(1);
                Y_m = P(2);

            end
        end

        if isfield(TrackData(k),'Y')

            Y_m = TrackData(k).Y;

        end


        if ~isempty(X_m) && ...
                ~isempty(Y_m) && ...
                isfinite(X_m) && ...
                isfinite(Y_m)

            AzimuthDeg = atan2d(Y_m,X_m);

            % Convert -180...180 into 0...360
            if AzimuthDeg < 0
                AzimuthDeg = AzimuthDeg + 360;
            end

        end

    end


    %% ----------------------------------------------------
    % If NO angle is available
    % -----------------------------------------------------

    if isempty(AzimuthDeg)

        fprintf( ...
            'Track %d: range available, azimuth unavailable.\n', ...
            k);

        continue;

    end


    %% ----------------------------------------------------
    % Normalize Angle
    % -----------------------------------------------------

    AzimuthDeg = mod(AzimuthDeg,360);


    %% ----------------------------------------------------
    % Convert Polar -> Cartesian
    % -----------------------------------------------------

    Xkm = RangeKm*cosd(AzimuthDeg);
    Ykm = RangeKm*sind(AzimuthDeg);


    %% ----------------------------------------------------
    % Plot Target
    % -----------------------------------------------------

    plot( ...
        Xkm, ...
        Ykm, ...
        'ro', ...
        'MarkerFaceColor','r', ...
        'MarkerEdgeColor','w', ...
        'MarkerSize',9);


    %% ----------------------------------------------------
    % Target Label
    % -----------------------------------------------------

    text( ...
        Xkm + 1, ...
        Ykm, ...
        sprintf('T%d',k), ...
        'Color','y', ...
        'FontWeight','bold');


    %% ----------------------------------------------------
    % Target-to-Radar Line
    % -----------------------------------------------------

    plot( ...
        [0 Xkm], ...
        [0 Ykm], ...
        'r-', ...
        'LineWidth',0.5);


    %% ----------------------------------------------------
    % Print Data
    % -----------------------------------------------------

    fprintf( ...
        'Track %d: Range = %.3f km | Azimuth = %.2f deg\n', ...
        k, ...
        RangeKm, ...
        AzimuthDeg);


    TargetsPlotted = TargetsPlotted + 1;

end


%% --------------------------------------------------------
% No Valid Targets
% ---------------------------------------------------------

if TargetsPlotted == 0

    text( ...
        0, ...
        -5, ...
        'AZIMUTH DATA NOT AVAILABLE', ...
        'Color','y', ...
        'HorizontalAlignment','center', ...
        'FontSize',13, ...
        'FontWeight','bold');

    text( ...
        0, ...
        -10, ...
        'PPI requires Range + Azimuth', ...
        'Color','w', ...
        'HorizontalAlignment','center', ...
        'FontSize',10);

end


%% --------------------------------------------------------
% Axis
% ---------------------------------------------------------

xlim([-MaxRangeKm MaxRangeKm]);
ylim([-MaxRangeKm MaxRangeKm]);


%% --------------------------------------------------------
% Direction Labels
% ---------------------------------------------------------

text( ...
    0, ...
    MaxRangeKm*1.02, ...
    'N', ...
    'Color','w', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');

text( ...
    MaxRangeKm*1.02, ...
    0, ...
    'E', ...
    'Color','w', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');

text( ...
    0, ...
    -MaxRangeKm*1.02, ...
    'S', ...
    'Color','w', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');

text( ...
    -MaxRangeKm*1.02, ...
    0, ...
    'W', ...
    'Color','w', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');


%% --------------------------------------------------------
% Finish
% ---------------------------------------------------------

hold off;

fprintf('====================================================\n');
fprintf('PPI targets plotted: %d\n',TargetsPlotted);
fprintf('====================================================\n\n');

end