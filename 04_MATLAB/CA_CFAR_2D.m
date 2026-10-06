function DetectionMap = CA_CFAR_2D( ...
    PowerMap, ...
    TrainingCells, ...
    GuardCells, ...
    ThresholdFactor)

% CA_CFAR_2D
%
% Two-dimensional Cell Averaging Constant False Alarm Rate detector.
%
% Syntax:
%
% DetectionMap = CA_CFAR_2D( ...
%     PowerMap, ...
%     TrainingCells, ...
%     GuardCells, ...
%     ThresholdFactor);
%
% Inputs:
%   PowerMap        : 2D radar power map
%   TrainingCells   : Number of training cells on each side
%   GuardCells      : Number of guard cells on each side
%   ThresholdFactor : Detection threshold multiplier
%
% Output:
%   DetectionMap    : Logical 2D detection map
%
% Example:
%
% DetectionMap = CA_CFAR_2D( ...
%     RangeDopplerPower, 8, 2, 14);

%% ============================================================
% 1. INPUT VALIDATION
% =============================================================

if nargin ~= 4

    error([ ...
        'Usage: DetectionMap = CA_CFAR_2D(', ...
        'PowerMap, TrainingCells, GuardCells, ', ...
        'ThresholdFactor)' ...
        ]);

end

if isempty(PowerMap)

    error('PowerMap cannot be empty.');

end

if ndims(PowerMap) ~= 2

    error('PowerMap must be a 2D matrix.');

end

if ~isnumeric(PowerMap)

    error('PowerMap must be numeric.');

end

if ~isscalar(TrainingCells) || ...
        TrainingCells < 1 || ...
        TrainingCells ~= floor(TrainingCells)

    error('TrainingCells must be a positive integer.');

end

if ~isscalar(GuardCells) || ...
        GuardCells < 0 || ...
        GuardCells ~= floor(GuardCells)

    error('GuardCells must be a non-negative integer.');

end

if ~isscalar(ThresholdFactor) || ...
        ThresholdFactor <= 0

    error('ThresholdFactor must be greater than zero.');

end

%% ============================================================
% 2. INITIALIZATION
% =============================================================

[NumberOfRows, NumberOfColumns] = ...
    size(PowerMap);

DetectionMap = ...
    false(NumberOfRows, NumberOfColumns);

%% ============================================================
% 3. CFAR WINDOW SIZE
% =============================================================

WindowRadius = ...
    TrainingCells + GuardCells;

WindowSize = ...
    2*WindowRadius + 1;

%% ============================================================
% 4. CA-CFAR PROCESSING
% =============================================================

for r = WindowRadius+1 : ...
        NumberOfRows-WindowRadius

    for d = WindowRadius+1 : ...
            NumberOfColumns-WindowRadius

        %% ----------------------------------------------------
        % Extract complete local CFAR window
        %% ----------------------------------------------------

        LocalWindow = ...
            PowerMap( ...
            r-WindowRadius:r+WindowRadius, ...
            d-WindowRadius:d+WindowRadius);

        %% ----------------------------------------------------
        % Create training-cell mask
        %% ----------------------------------------------------

        TrainingMask = ...
            true(WindowSize, WindowSize);

        %% ----------------------------------------------------
        % Remove guard cells and cell under test
        %% ----------------------------------------------------

        CenterIndex = ...
            WindowRadius + 1;

        GuardStart = ...
            CenterIndex - GuardCells;

        GuardEnd = ...
            CenterIndex + GuardCells;

        TrainingMask( ...
            GuardStart:GuardEnd, ...
            GuardStart:GuardEnd) = false;

        %% ----------------------------------------------------
        % Estimate noise power
        %% ----------------------------------------------------

        TrainingCellValues = ...
            LocalWindow(TrainingMask);

        NoiseEstimate = ...
            mean(TrainingCellValues(:));

        %% ----------------------------------------------------
        % Calculate threshold
        %% ----------------------------------------------------

        Threshold = ...
            ThresholdFactor * NoiseEstimate;

        %% ----------------------------------------------------
        % Cell under test
        %% ----------------------------------------------------

        CellUnderTest = ...
            PowerMap(r,d);

        %% ----------------------------------------------------
        % Detection decision
        %% ----------------------------------------------------

        if CellUnderTest > Threshold

            DetectionMap(r,d) = true;

        end

    end

end

end