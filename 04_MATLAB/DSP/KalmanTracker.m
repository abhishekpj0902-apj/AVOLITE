function Tracks = KalmanTracker(TrackInput)

%=========================================================
% SARRS STUDIO
% Range-Velocity Kalman Tracker
%
% State:
%       x = [Range
%            Velocity]
%
% Model:
%
%       x(k+1) = F*x(k) + w
%
%       F = [1  dt
%            0   1]
%
% Measurement:
%
%       z = [Range
%            Velocity]
%
% Features:
%   ✓ Range prediction
%   ✓ Velocity prediction
%   ✓ Measurement update
%   ✓ Variable time step
%   ✓ Track covariance
%   ✓ Kalman gain
%=========================================================


%% ========================================================
% Validate Input
%========================================================

if nargin < 1 || isempty(TrackInput)

    Tracks = struct([]);

    disp(' ');
    disp('=========================================');
    disp('Kalman Tracker');
    disp('=========================================');
    disp('No tracks available.');

    return

end


Tracks = TrackInput;


%% ========================================================
% Kalman Parameters
%=========================================================

% Process noise

Q = [ ...
    25      0;
     0     10];


% Measurement noise

R = [ ...
    100      0;
      0     25];


% Default time step

DefaultDt = 0.001;


%% ========================================================
% Process Each Track
%=========================================================

for k = 1:length(TrackInput)

    %% ====================================================
    % Measurement
    %=====================================================

    RangeMeasurement = ...
        double(TrackInput(k).Range);


    if isfield(TrackInput(k),'Velocity')

        VelocityMeasurement = ...
            double(TrackInput(k).Velocity);

    else

        VelocityMeasurement = 0;

    end


    z = [ ...
        RangeMeasurement;
        VelocityMeasurement];


    %% ====================================================
    % Time Step
    %=====================================================

    if isfield(TrackInput(k),'DeltaTime')

        dt = ...
            double(TrackInput(k).DeltaTime);

    else

        dt = DefaultDt;

    end


    if dt <= 0

        dt = DefaultDt;

    end


    %% ====================================================
    % State Transition Matrix
    %=====================================================

    F = [ ...
        1   dt;
        0    1];


    %% ====================================================
    % Measurement Matrix
    %=====================================================

    H = eye(2);


    %% ====================================================
    % Previous State
    %=====================================================

    if isfield(TrackInput(k),'StateEstimate')

        xPrevious = ...
            double(TrackInput(k).StateEstimate(:));

        if length(xPrevious) ~= 2

            xPrevious = ...
                z;

        end

    else

        xPrevious = ...
            z;

    end


    %% ====================================================
    % Previous Covariance
    %=====================================================

    if isfield(TrackInput(k),'StateCovariance')

        PPrevious = ...
            double(TrackInput(k).StateCovariance);

        if ~isequal(size(PPrevious),[2 2])

            PPrevious = ...
                eye(2);

        end

    else

        PPrevious = ...
            eye(2);

    end


    %% ====================================================
    % Prediction
    %=====================================================

    xPredicted = ...
        F * xPrevious;


    PPredicted = ...
        F * PPrevious * F' + Q;


    %% ====================================================
    % Innovation
    %=====================================================

    Innovation = ...
        z - H*xPredicted;


    InnovationCovariance = ...
        H*PPredicted*H' + R;


    %% ====================================================
    % Kalman Gain
    %=====================================================

    K = ...
        PPredicted * H' / ...
        InnovationCovariance;


    %% ====================================================
    % Measurement Update
    %=====================================================

    xUpdated = ...
        xPredicted + K*Innovation;


    PUpdated = ...
        (eye(2)-K*H) * PPredicted;


    %% ====================================================
    % Store State
    %=====================================================

    Tracks(k).StateEstimate = ...
        xUpdated;


    Tracks(k).StateCovariance = ...
        PUpdated;


    Tracks(k).PredictedRange = ...
        xPredicted(1);


    Tracks(k).PredictedVelocity = ...
        xPredicted(2);


    Tracks(k).FilteredRange = ...
        xUpdated(1);


    Tracks(k).FilteredVelocity = ...
        xUpdated(2);


    Tracks(k).InnovationRange = ...
        Innovation(1);


    Tracks(k).InnovationVelocity = ...
        Innovation(2);


    Tracks(k).KalmanGain = ...
        K;


    Tracks(k).Covariance = ...
        PUpdated;


    %% ====================================================
    % Compatibility Fields
    %=====================================================

    Tracks(k).MeasuredPosition = ...
        RangeMeasurement;


    Tracks(k).PredictedPosition = ...
        xPredicted(1);


    Tracks(k).FilteredPosition = ...
        xUpdated(1);


end


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Range-Velocity Kalman Tracker');
disp('=========================================');

fprintf('Tracks Processed : %d\n', ...
    length(Tracks));


%% ========================================================
% Track Summary
%=========================================================

for k = 1:length(Tracks)

    fprintf( ...
        'Track %d | Range %.2f m | Velocity %.2f m/s | Predicted Range %.2f m\n',...
        Tracks(k).TrackID,...
        Tracks(k).FilteredRange,...
        Tracks(k).FilteredVelocity,...
        Tracks(k).PredictedRange);

end

end