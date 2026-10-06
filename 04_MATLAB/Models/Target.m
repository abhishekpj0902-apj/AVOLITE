function Target = Target()

%=========================================================
% SARRS STUDIO
% Multi Target Motion Model
%
% Features
% ------------------------------------------
% ✓ Multiple Targets
% ✓ Target Position History
% ✓ Range History
% ✓ Velocity
% ✓ Heading
% ✓ Altitude
% ✓ RCS
% ✓ Multi-Scan Support
% ✓ 2-D Target Motion Toward Radar
%=========================================================


%% ========================================================
% Simulation Parameters
%=========================================================

TargetCount = 5;

dt = 1;                 % Simulation time step [s]
T  = 60;                % Simulation duration [s]

Time = 0:dt:T;

N = length(Time);


%% ========================================================
% Target Initialization
%=========================================================

Target = struct([]);


% Initial target positions [km]
%
% T1 -> East
% T2 -> North-East
% T3 -> North-West
% T4 -> South-West
% T5 -> South-East

InitialX_km = [50, 15, -40, -40, 15];

InitialY_km = [0, 45, 30, -30, -45];


%% ========================================================
% Target Generation
%=========================================================

for i = 1:TargetCount

    %% ----------------------------------------------------
    % Basic Target Information
    % -----------------------------------------------------

    Target(i).ID = i;

    Target(i).Type = "Aircraft";


    %% ----------------------------------------------------
    % Initial Position
    % -----------------------------------------------------

    Target(i).InitialX = InitialX_km(i) * 1000;

    Target(i).InitialY = InitialY_km(i) * 1000;

    Target(i).InitialZ = 5000;


    %% ----------------------------------------------------
    % Velocity
    % -----------------------------------------------------

    switch i

        case 1
            Target(i).Velocity = 250;     % m/s

        case 2
            Target(i).Velocity = 180;     % m/s

        case 3
            Target(i).Velocity = 90;      % m/s

        case 4
            Target(i).Velocity = 60;      % m/s

        case 5
            Target(i).Velocity = 450;     % m/s

    end


    %% ----------------------------------------------------
    % Altitude
    % -----------------------------------------------------

    Target(i).Altitude = 5000;            % meters


    %% ----------------------------------------------------
    % Radar Cross Section
    % -----------------------------------------------------

    Target(i).RCS = 10;                   % m^2


    %% ----------------------------------------------------
    % Time Vector
    % -----------------------------------------------------

    Target(i).Time = Time;


    %% ====================================================
    % Position History
    % ====================================================

    Target(i).X = zeros(1,N);

    Target(i).Y = zeros(1,N);

    Target(i).Z = zeros(1,N);


    %% ====================================================
    % Range History
    % ====================================================

    Target(i).GroundRange = zeros(1,N);

    Target(i).Distance = zeros(1,N);


    %% ====================================================
    % Initial Position
    % ====================================================

    Target(i).X(1) = Target(i).InitialX;

    Target(i).Y(1) = Target(i).InitialY;

    Target(i).Z(1) = Target(i).InitialZ;


    %% ====================================================
    % Initial Range
    % ====================================================

    Target(i).GroundRange(1) = sqrt( ...
        Target(i).X(1)^2 + ...
        Target(i).Y(1)^2 );


    Target(i).Distance(1) = sqrt( ...
        Target(i).X(1)^2 + ...
        Target(i).Y(1)^2 + ...
        Target(i).Z(1)^2 );


    %% ====================================================
    % Motion Model
    % ====================================================

    % Direction from target toward radar
    dx = -Target(i).X(1);

    dy = -Target(i).Y(1);

    direction = sqrt(dx^2 + dy^2);

    ux = dx / direction;

    uy = dy / direction;


    %% ----------------------------------------------------
    % Heading Angle
    % -----------------------------------------------------

    Target(i).HeadingAngle = atan2d( ...
        uy, ux);


    Target(i).Heading = "Toward Radar";


    %% ====================================================
    % Target Movement
    % ====================================================

    for k = 2:N

        %% Move toward radar

        Target(i).X(k) = ...
            Target(i).X(k-1) + ...
            Target(i).Velocity * ux * dt;


        Target(i).Y(k) = ...
            Target(i).Y(k-1) + ...
            Target(i).Velocity * uy * dt;


        %% Constant altitude

        Target(i).Z(k) = ...
            Target(i).Z(k-1);


        %% Ground range

        Target(i).GroundRange(k) = sqrt( ...
            Target(i).X(k)^2 + ...
            Target(i).Y(k)^2 );


        %% Slant range

        Target(i).Distance(k) = sqrt( ...
            Target(i).X(k)^2 + ...
            Target(i).Y(k)^2 + ...
            Target(i).Z(k)^2 );

    end


    %% ====================================================
    % Current Position
    % ====================================================

    Target(i).CurrentX = Target(i).X(end);

    Target(i).CurrentY = Target(i).Y(end);

    Target(i).CurrentZ = Target(i).Z(end);

    Target(i).CurrentRange = ...
        Target(i).Distance(end);


    %% ====================================================
    % Initial Range
    % ====================================================

    Target(i).InitialRange = ...
        Target(i).Distance(1);


end


%% ========================================================
% Display Target Information
% =========================================================

disp(' ');
disp('=========================================');
disp('      SARRS STUDIO TARGET MODEL');
disp('=========================================');

for i = 1:TargetCount

    fprintf('\nTarget %d\n',i);

    fprintf('Initial X : %.2f km\n', ...
        Target(i).X(1)/1000);

    fprintf('Initial Y : %.2f km\n', ...
        Target(i).Y(1)/1000);

    fprintf('Velocity  : %.0f m/s\n', ...
        Target(i).Velocity);

    fprintf('Altitude  : %.0f m\n', ...
        Target(i).Altitude);

    fprintf('RCS       : %.1f m^2\n', ...
        Target(i).RCS);

    fprintf('Initial Range : %.2f km\n', ...
        Target(i).Distance(1)/1000);

    fprintf('Final Range   : %.2f km\n', ...
        Target(i).Distance(end)/1000);

end

disp(' ');
disp('Target trajectory generated.');
disp('Multi-scan position history available.');

end