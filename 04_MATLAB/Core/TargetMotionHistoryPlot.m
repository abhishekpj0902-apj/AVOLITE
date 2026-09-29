function TargetMotionHistoryPlot(TargetHistory)
%=========================================================
% SARRS STUDIO
% TARGET MOTION HISTORY
%
% Displays:
%   1. Range vs Time
%   2. Eight range snapshots
%   3. 360-degree X/Y target motion if X/Y exists
%   4. Eight 360-degree spatial snapshots if X/Y exists
%=========================================================

%% --------------------------------------------------------
% Validate input
% ---------------------------------------------------------

if nargin < 1 || isempty(TargetHistory)

    warning('No target history supplied.');

    return;

end


%% --------------------------------------------------------
% Read Range / Time
% ---------------------------------------------------------

Time = TargetHistory.Time(:);

Range = TargetHistory.Range;

if isvector(Range)

    Range = Range(:);

end

NumberOfScans = size(Range,1);
NumberOfTargets = size(Range,2);


%% ========================================================
% 1. RANGE VS TIME
% =========================================================

figure( ...
    'Name','SARRS - Target Range History', ...
    'NumberTitle','off');

hold on;

for TargetIndex = 1:NumberOfTargets

    Valid = isfinite(Range(:,TargetIndex));

    if any(Valid)

        plot( ...
            Time(Valid), ...
            Range(Valid,TargetIndex)/1000, ...
            '-o', ...
            'LineWidth',1.5, ...
            'MarkerSize',4, ...
            'DisplayName', ...
            sprintf('Target %d',TargetIndex));

    end

end

grid on;

xlabel('Time (s)');
ylabel('Target Range (km)');

title( ...
    'SARRS Target Motion — Range vs Time');

legend('Location','best');

hold off;


%% ========================================================
% 2. EIGHT RANGE SNAPSHOTS
% =========================================================

SnapshotCount = min(8,NumberOfScans);

SnapshotScans = round( ...
    linspace(1,NumberOfScans,SnapshotCount));

SnapshotScans = unique(SnapshotScans);


figure( ...
    'Name','SARRS - Range Motion Snapshots', ...
    'NumberTitle','off');

Rows = ceil(sqrt(numel(SnapshotScans)));
Cols = ceil(numel(SnapshotScans)/Rows);

MaxRangeKm = max(Range(:),[],'omitnan')/1000;

if isempty(MaxRangeKm) || ...
        ~isfinite(MaxRangeKm) || ...
        MaxRangeKm <= 0

    MaxRangeKm = 1;

end


for PlotIndex = 1:numel(SnapshotScans)

    ScanIndex = SnapshotScans(PlotIndex);

    subplot(Rows,Cols,PlotIndex);

    hold on;

    plot( ...
        0,0, ...
        '^', ...
        'MarkerFaceColor','k', ...
        'MarkerSize',7);


    for TargetIndex = 1:NumberOfTargets

        if isfinite(Range(ScanIndex,TargetIndex))

            CurrentRangeKm = ...
                Range(ScanIndex,TargetIndex)/1000;

            plot( ...
                CurrentRangeKm, ...
                0, ...
                'o', ...
                'MarkerSize',7);

            line( ...
                [0 CurrentRangeKm], ...
                [0 0], ...
                'LineStyle','--');


            text( ...
                CurrentRangeKm, ...
                0, ...
                sprintf( ...
                '  T%d %.1f km', ...
                TargetIndex, ...
                CurrentRangeKm), ...
                'VerticalAlignment','bottom');

        end

    end


    xlim([0 MaxRangeKm*1.08]);
    ylim([-1 1]);

    yticks([]);

    grid on;

    xlabel('Range (km)');

    title( ...
        sprintf( ...
        'Scan %d | t = %.1f s', ...
        ScanIndex, ...
        Time(ScanIndex)));

    hold off;

end


sgtitle( ...
    'SARRS Target Motion — Range Snapshots');


%% ========================================================
% 3. CHECK X/Y POSITION HISTORY
% =========================================================

HasXY = false;

X = [];
Y = [];


%% --------------------------------------------------------
% Method A: TargetHistory.X / Y
% ---------------------------------------------------------

if isfield(TargetHistory,'X') && ...
        isfield(TargetHistory,'Y')

    X = TargetHistory.X;
    Y = TargetHistory.Y;

    HasXY = true;

end


%% --------------------------------------------------------
% Method B: Position
% ---------------------------------------------------------

if ~HasXY && ...
        isfield(TargetHistory,'Position')

    P = TargetHistory.Position;

    if ndims(P) >= 2

        % Try common formats

        if size(P,2) >= 2

            X = P(:,1);
            Y = P(:,2);

            HasXY = true;

        end

    end

end


%% ========================================================
% 4. 360-DEGREE GROUND TRUTH PPI
% =========================================================

if ~HasXY

    fprintf('\n');
    fprintf('SARRS TargetMotionHistoryPlot:\n');
    fprintf('X/Y position history is not available.\n');
    fprintf('360-degree ground-truth PPI cannot be created from\n');
    fprintf('TargetHistory alone.\n');
    fprintf('\n');

    return;

end


%% --------------------------------------------------------
% Force X/Y into scan × target format
% ---------------------------------------------------------

if isvector(X)

    X = X(:);

end

if isvector(Y)

    Y = Y(:);

end


%% --------------------------------------------------------
% Verify dimensions
% ---------------------------------------------------------

if size(X,1) ~= NumberOfScans || ...
        size(Y,1) ~= NumberOfScans

    warning( ...
        ['X/Y history dimensions do not match Range history. ' ...
         '360-degree PPI skipped.']);

    return;

end


NumberOfXYTargets = size(X,2);

NumberOfTargets = ...
    min(NumberOfTargets,NumberOfXYTargets);


%% ========================================================
% 5. FULL 360-DEGREE TARGET TRAJECTORY
% =========================================================

figure( ...
    'Name','SARRS - 360 Degree Target Motion', ...
    'NumberTitle','off', ...
    'Color','w');

hold on;

axis equal;

grid on;

title( ...
    'SARRS 360° Target Motion — Ground Truth');

xlabel('East / X (km)');
ylabel('North / Y (km)');


%% Radar

plot( ...
    0, ...
    0, ...
    '^', ...
    'MarkerFaceColor','k', ...
    'MarkerSize',9);


%% Range rings

MaxXYRange = ...
    max(sqrt(X(:).^2 + Y(:).^2),[],'omitnan')/1000;

if isempty(MaxXYRange) || ...
        ~isfinite(MaxXYRange) || ...
        MaxXYRange <= 0

    MaxXYRange = MaxRangeKm;

end


theta = linspace(0,2*pi,720);

for R = 25:25:MaxXYRange

    plot( ...
        R*cos(theta), ...
        R*sin(theta), ...
        'k:', ...
        'LineWidth',0.5);

end


%% Target trajectories

for TargetIndex = 1:NumberOfTargets

    Valid = ...
        isfinite(X(:,TargetIndex)) & ...
        isfinite(Y(:,TargetIndex));

    if any(Valid)

        plot( ...
            X(Valid,TargetIndex)/1000, ...
            Y(Valid,TargetIndex)/1000, ...
            '-o', ...
            'LineWidth',1.5, ...
            'MarkerSize',3, ...
            'DisplayName', ...
            sprintf('Target %d',TargetIndex));


        %% Initial position

        First = find(Valid,1,'first');

        plot( ...
            X(First,TargetIndex)/1000, ...
            Y(First,TargetIndex)/1000, ...
            's', ...
            'MarkerSize',8, ...
            'LineWidth',1.5);


        %% Final position

        Last = find(Valid,1,'last');

        plot( ...
            X(Last,TargetIndex)/1000, ...
            Y(Last,TargetIndex)/1000, ...
            'o', ...
            'MarkerSize',9, ...
            'LineWidth',1.5);


        text( ...
            X(Last,TargetIndex)/1000, ...
            Y(Last,TargetIndex)/1000, ...
            sprintf('  T%d',TargetIndex), ...
            'FontWeight','bold');

    end

end


xlim([-MaxXYRange MaxXYRange]);
ylim([-MaxXYRange MaxXYRange]);

legend('Location','best');

hold off;


%% ========================================================
% 6. EIGHT 360-DEGREE SPATIAL SNAPSHOTS
% =========================================================

SnapshotCount = min(8,NumberOfScans);

SnapshotScans = round( ...
    linspace(1,NumberOfScans,SnapshotCount));

SnapshotScans = unique(SnapshotScans);


figure( ...
    'Name','SARRS - 360 Degree Target Snapshots', ...
    'NumberTitle','off');


Rows = ceil(sqrt(numel(SnapshotScans)));
Cols = ceil(numel(SnapshotScans)/Rows);


for PlotIndex = 1:numel(SnapshotScans)

    ScanIndex = SnapshotScans(PlotIndex);

    subplot(Rows,Cols,PlotIndex);

    hold on;

    %% Radar

    plot( ...
        0, ...
        0, ...
        '^', ...
        'MarkerFaceColor','k', ...
        'MarkerSize',7);


    %% Range circle

    plot( ...
        MaxXYRange*cos(theta), ...
        MaxXYRange*sin(theta), ...
        'k:');


    %% Targets

    for TargetIndex = 1:NumberOfTargets

        if isfinite(X(ScanIndex,TargetIndex)) && ...
                isfinite(Y(ScanIndex,TargetIndex))

            Xkm = X(ScanIndex,TargetIndex)/1000;
            Ykm = Y(ScanIndex,TargetIndex)/1000;

            plot( ...
                Xkm, ...
                Ykm, ...
                'ro', ...
                'MarkerFaceColor','r', ...
                'MarkerSize',6);


            text( ...
                Xkm, ...
                Ykm, ...
                sprintf(' T%d',TargetIndex), ...
                'FontSize',8);

        end

    end


    axis equal;

    xlim([-MaxXYRange MaxXYRange]);
    ylim([-MaxXYRange MaxXYRange]);

    grid on;

    xlabel('X (km)');
    ylabel('Y (km)');

    title( ...
        sprintf( ...
        'Scan %d | t = %.1f s', ...
        ScanIndex, ...
        Time(ScanIndex)));

    hold off;

end


sgtitle( ...
    'SARRS 360° Target Motion — Eight Snapshots');


%% ========================================================
% 7. CONSOLE TABLE
% =========================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('       SARRS TARGET MOTION HISTORY\n');
fprintf('====================================================\n');

fprintf( ...
    '%8s %12s', ...
    'Scan', ...
    'Time(s)');


for TargetIndex = 1:NumberOfTargets

    fprintf( ...
        '%16s', ...
        sprintf('Target %d(km)',TargetIndex));

end

fprintf('\n');

fprintf( ...
    '----------------------------------------------------\n');


for ScanIndex = 1:NumberOfScans

    fprintf( ...
        '%8d %12.2f', ...
        ScanIndex, ...
        Time(ScanIndex));


    for TargetIndex = 1:NumberOfTargets

        if ~isfinite(Range(ScanIndex,TargetIndex))

            fprintf('%16s','N/A');

        else

            fprintf( ...
                '%16.3f', ...
                Range(ScanIndex,TargetIndex)/1000);

        end

    end

    fprintf('\n');

end


fprintf( ...
    '====================================================\n');

end