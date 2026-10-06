function TrajectoryPlot(Data)

%=========================================================
% SARRS STUDIO
% Target / Track Trajectory Visualization
%
% Supports:
%   1. Target structure from Target.m
%      -> Uses X/Y trajectory history
%
%   2. TrackTable from TrackManager
%      -> Uses Range and optional Azimuth
%
%=========================================================

%% ========================================================
% Figure
%========================================================

figure( ...
    'Name','SARRS Target / Track Trajectory', ...
    'NumberTitle','off', ...
    'Color','w');

hold on;
grid on;
axis equal;

xlabel('X Position (km)');
ylabel('Y Position (km)');
title('SARRS Target / Track Trajectory');

%% ========================================================
% Radar
%========================================================

plot( ...
    0, ...
    0, ...
    'kp', ...
    'MarkerSize',16, ...
    'MarkerFaceColor','g');

text( ...
    2, ...
    2, ...
    'RADAR', ...
    'FontWeight','bold', ...
    'Color','b');

%% ========================================================
% Empty Data
%========================================================

if isempty(Data)

    text( ...
        20, ...
        20, ...
        'NO TARGETS / TRACKS AVAILABLE', ...
        'Color','r', ...
        'FontSize',14);

    xlim([-160 160]);
    ylim([-160 160]);

    hold off;

    return;

end

%% ========================================================
% Determine Data Type
%========================================================

IsTargetData = ...
    isfield(Data,'X') && ...
    isfield(Data,'Y');

IsTrackData = ...
    isfield(Data,'Range');

%% ========================================================
% TRUE TARGET TRAJECTORY
%========================================================

if IsTargetData

    NTargets = length(Data);

    for k = 1:NTargets

        %% ------------------------------------------------
        % Position history
        % -------------------------------------------------

        X = double(Data(k).X) / 1000;
        Y = double(Data(k).Y) / 1000;

        %% ------------------------------------------------
        % Complete trajectory
        % -------------------------------------------------

        plot( ...
            X, ...
            Y, ...
            'b-', ...
            'LineWidth',1.5);

        %% ------------------------------------------------
        % Initial Position
        % -------------------------------------------------

        plot( ...
            X(1), ...
            Y(1), ...
            'ko', ...
            'MarkerSize',6);

        %% ------------------------------------------------
        % Current Position
        % -------------------------------------------------

        plot( ...
            X(end), ...
            Y(end), ...
            'ro', ...
            'MarkerFaceColor','r', ...
            'MarkerSize',8);

        %% ------------------------------------------------
        % Motion Direction
        % -------------------------------------------------

        if length(X) >= 2

            dx = X(end) - X(end-1);
            dy = Y(end) - Y(end-1);

            quiver( ...
                X(end), ...
                Y(end), ...
                dx*20, ...
                dy*20, ...
                0, ...
                'b', ...
                'LineWidth',1.5, ...
                'MaxHeadSize',2);

        end

        %% ------------------------------------------------
        % Target ID
        % -------------------------------------------------

        if isfield(Data(k),'ID')

            ID = Data(k).ID;

        else

            ID = k;

        end

        text( ...
            X(end)+2, ...
            Y(end)+2, ...
            sprintf('T%d',ID), ...
            'FontWeight','bold');

    end

%% ========================================================
% TRACK TABLE
%=========================================================

elseif IsTrackData

    NTracks = length(Data);

    % -----------------------------------------------------
    % Generate display angles only when angle is unavailable
    % ------------------------------------------------------

    DisplayAngles = ...
        linspace(0,360,NTracks+1);

    DisplayAngles(end) = [];

    for k = 1:NTracks

        %% ------------------------------------------------
        % Range
        % -------------------------------------------------

        R = double(Data(k).Range) / 1000;

        %% ------------------------------------------------
        % Use real azimuth if available
        % -------------------------------------------------

        if isfield(Data(k),'Azimuth')

            Azimuth = ...
                double(Data(k).Azimuth);

        elseif isfield(Data(k),'Angle')

            Azimuth = ...
                double(Data(k).Angle);

        else

            % No angle available in current track data.
            % Use display angle only.

            Azimuth = DisplayAngles(k);

        end

        %% ------------------------------------------------
        % Convert polar -> Cartesian
        % -------------------------------------------------

        X = R * cosd(Azimuth);

        Y = R * sind(Azimuth);

        %% ------------------------------------------------
        % Current Track Position
        % -------------------------------------------------

        plot( ...
            X, ...
            Y, ...
            'ro', ...
            'MarkerFaceColor','r', ...
            'MarkerSize',8);

        %% ------------------------------------------------
        % Track ID
        % -------------------------------------------------

        if isfield(Data(k),'TrackID')

            TrackID = Data(k).TrackID;

        else

            TrackID = k;

        end

        text( ...
            X+2, ...
            Y+2, ...
            sprintf('T%d',TrackID), ...
            'FontWeight','bold');

        %% ------------------------------------------------
        % Velocity Vector
        % -------------------------------------------------

        if isfield(Data(k),'FilteredVelocity')

            Velocity = ...
                double(Data(k).FilteredVelocity);

        elseif isfield(Data(k),'Velocity')

            Velocity = ...
                double(Data(k).Velocity);

        else

            Velocity = 0;

        end

        %% ------------------------------------------------
        % Display Motion Direction
        % -------------------------------------------------

        if Velocity ~= 0

            ArrowLength = 3;

            quiver( ...
                X, ...
                Y, ...
                -ArrowLength*cosd(Azimuth), ...
                -ArrowLength*sind(Azimuth), ...
                0, ...
                'b', ...
                'LineWidth',1.5, ...
                'MaxHeadSize',2);

        end

    end

    %% ----------------------------------------------------
    % Warning
    % -----------------------------------------------------

    if ~isfield(Data,'Azimuth') && ...
       ~isfield(Data,'Angle')

        text( ...
            -150, ...
            -145, ...
            'NOTE: TrackTable has no azimuth. Display angles are illustrative.', ...
            'Color','r', ...
            'FontWeight','bold');

    end

else

    error( ...
        ['TrajectoryPlot: Unsupported input. ', ...
         'Expected Target data or TrackTable.']);

end

%% ========================================================
% Radar Coverage
%=========================================================

theta = linspace(0,2*pi,360);

Rmax = 150;

plot( ...
    Rmax*cos(theta), ...
    Rmax*sin(theta), ...
    'k--', ...
    'LineWidth',1);

%% ========================================================
% Axis Limits
%=========================================================

xlim([-160 160]);

ylim([-160 160]);

%% ========================================================
% Legend
%=========================================================

legend( ...
    'Radar', ...
    'Trajectory / Track', ...
    'Initial Position', ...
    'Current Target / Track', ...
    'Motion', ...
    'Coverage', ...
    'Location','eastoutside');

hold off;

end