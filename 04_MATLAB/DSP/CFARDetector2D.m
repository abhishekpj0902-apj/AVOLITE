function CFARResult = CFARDetector2D(RDData, RangeAxis, DopplerAxis, PRF)
% CFARDetector2D
%
% 2-D Cell-Averaging CFAR detector for Range-Doppler data.
%
% Inputs:
%   RDData      : Range-Doppler magnitude or complex matrix
%   RangeAxis   : Range axis in metres
%   DopplerAxis : Doppler axis in Hz
%   PRF         : Pulse repetition frequency in Hz
%
% Outputs:
%   CFARResult.DetectionMap
%   CFARResult.ThresholdMap
%   CFARResult.ScaledThresholdMap
%   CFARResult.Range
%   CFARResult.Doppler
%   CFARResult.Velocity
%   CFARResult.Amplitude
%   CFARResult.RangeIndex
%   CFARResult.DopplerIndex
%   CFARResult.RangeAxis
%   CFARResult.DopplerAxis
%   CFARResult.NumberOfDetections

    fprintf('\n==============================================\n');
    fprintf('2-D CFAR DETECTOR\n');
    fprintf('==============================================\n');

    %% ---------------------------------------------------------
    % Input validation
    % ----------------------------------------------------------

    if nargin < 4
        error('Usage: CFARDetector2D(RDData, RangeAxis, DopplerAxis, PRF)');
    end

    if ~isnumeric(RDData) || isempty(RDData)
        error('RDData must be a non-empty numeric matrix.');
    end

    if ~isnumeric(RangeAxis) || isempty(RangeAxis)
        error('RangeAxis must be a non-empty numeric vector.');
    end

    if ~isnumeric(DopplerAxis) || isempty(DopplerAxis)
        error('DopplerAxis must be a non-empty numeric vector.');
    end

    if ~isscalar(PRF) || PRF <= 0
        error('PRF must be a positive scalar.');
    end

    RangeAxis = RangeAxis(:);
    DopplerAxis = DopplerAxis(:).';

    if size(RDData, 1) ~= length(RangeAxis)
        error('RDData rows must match RangeAxis length.');
    end

    if size(RDData, 2) ~= length(DopplerAxis)
        error('RDData columns must match DopplerAxis length.');
    end

    %% ---------------------------------------------------------
    % CFAR configuration
    % ----------------------------------------------------------

    MinRange = 40e3;
    MaxRange = 55e3;

    Pfa = 1e-3;

    TrainingRange = 12;
    TrainingDoppler = 8;

    GuardRange = 4;
    GuardDoppler = 2;

    MaxDetections = 20;

    RangeSeparation = 20;
    DopplerSeparation = 8;

    % Practical debugging scale for the current simulation.
    % Later, after noise calibration, change to 1.0.
    ThresholdScale = 0.10;

    % Minimum normalized power gate
    MinimumNormalizedPower = 0.05;

    %% ---------------------------------------------------------
    % Range gating
    % ----------------------------------------------------------

    RangeMask = ...
        RangeAxis >= MinRange & RangeAxis <= MaxRange;

    if ~any(RangeMask)
        error('No range samples exist inside the selected range gate.');
    end

    RangeData = RDData(RangeMask, :);
    GatedRangeAxis = RangeAxis(RangeMask);

    [NumRange, NumDoppler] = size(RangeData);

    fprintf('Range gate        : %.2f to %.2f km\n', ...
        MinRange/1000, MaxRange/1000);

    fprintf('Processed ranges  : %d\n', NumRange);
    fprintf('Processed Doppler : %d\n', NumDoppler);

    %% ---------------------------------------------------------
    % Power map
    % ----------------------------------------------------------

    PowerMap = abs(RangeData).^2;

    MaximumPower = max(PowerMap(:));

    if MaximumPower <= 0 || ~isfinite(MaximumPower)
        error('Input RDData contains zero or invalid power.');
    end

    PowerMap = PowerMap ./ MaximumPower;

    %% ---------------------------------------------------------
    % CFAR training window
    % ----------------------------------------------------------

    WindowRange = ...
        2*(TrainingRange + GuardRange) + 1;

    WindowDoppler = ...
        2*(TrainingDoppler + GuardDoppler) + 1;

    Window = ones(WindowRange, WindowDoppler);

    CenterRange = TrainingRange + GuardRange + 1;
    CenterDoppler = TrainingDoppler + GuardDoppler + 1;

    Window( ...
        CenterRange-GuardRange : CenterRange+GuardRange, ...
        CenterDoppler-GuardDoppler : CenterDoppler+GuardDoppler) = 0;

    NumberTrainingCells = sum(Window(:));

    %% ---------------------------------------------------------
    % Local noise estimate
    % ----------------------------------------------------------

    NoisePower = ...
        conv2(PowerMap, Window, 'same') ./ NumberTrainingCells;

    %% ---------------------------------------------------------
    % CA-CFAR threshold
    % ----------------------------------------------------------

    Alpha = NumberTrainingCells * ...
        (Pfa^(-1/NumberTrainingCells) - 1);

    ThresholdMap = Alpha .* NoisePower;

    ScaledThresholdMap = ThresholdScale .* ThresholdMap;

    %% ---------------------------------------------------------
    % Initial detection
    % ----------------------------------------------------------

    DetectionMap = ...
        PowerMap > ScaledThresholdMap;

    DetectionMap = ...
        DetectionMap & ...
        PowerMap >= MinimumNormalizedPower;

    %% ---------------------------------------------------------
    % Remove boundary cells
    % ----------------------------------------------------------

    BoundaryRange = TrainingRange + GuardRange;
    BoundaryDoppler = TrainingDoppler + GuardDoppler;

    DetectionMap(1:BoundaryRange, :) = false;

    DetectionMap(end-BoundaryRange+1:end, :) = false;

    DetectionMap(:, 1:BoundaryDoppler) = false;

    DetectionMap(:, end-BoundaryDoppler+1:end) = false;

    %% ---------------------------------------------------------
    % Extract candidate detections
    % ----------------------------------------------------------

    [CandidateRangeIndex, CandidateDopplerIndex] = ...
        find(DetectionMap);

    SelectedRangeIndex = [];
    SelectedDopplerIndex = [];
    SelectedAmplitude = [];

    if ~isempty(CandidateRangeIndex)

        CandidateLinearIndex = sub2ind( ...
            size(RangeData), ...
            CandidateRangeIndex, ...
            CandidateDopplerIndex);

        CandidateAmplitude = ...
            abs(RangeData(CandidateLinearIndex));

        % Strongest candidates first
        [CandidateAmplitude, SortIndex] = ...
            sort(CandidateAmplitude, 'descend');

        CandidateRangeIndex = ...
            CandidateRangeIndex(SortIndex);

        CandidateDopplerIndex = ...
            CandidateDopplerIndex(SortIndex);

        NumberOfCandidates = ...
            min(100, length(CandidateAmplitude));

        CandidateAmplitude = ...
            CandidateAmplitude(1:NumberOfCandidates);

        CandidateRangeIndex = ...
            CandidateRangeIndex(1:NumberOfCandidates);

        CandidateDopplerIndex = ...
            CandidateDopplerIndex(1:NumberOfCandidates);

        %% Non-maximum suppression

        for n = 1:length(CandidateAmplitude)

            if length(SelectedAmplitude) >= MaxDetections
                break;
            end

            CurrentRangeIndex = CandidateRangeIndex(n);
            CurrentDopplerIndex = CandidateDopplerIndex(n);

            IsSeparated = true;

            for k = 1:length(SelectedAmplitude)

                RangeDistance = abs( ...
                    CurrentRangeIndex - SelectedRangeIndex(k));

                DopplerDistance = abs( ...
                    CurrentDopplerIndex - SelectedDopplerIndex(k));

                if RangeDistance < RangeSeparation && ...
                   DopplerDistance < DopplerSeparation

                    IsSeparated = false;
                    break;
                end
            end

            if IsSeparated

                SelectedRangeIndex(end+1,1) = ...
                    CurrentRangeIndex;

                SelectedDopplerIndex(end+1,1) = ...
                    CurrentDopplerIndex;

                SelectedAmplitude(end+1,1) = ...
                    CandidateAmplitude(n);
            end
        end
    end

    %% ---------------------------------------------------------
    % Convert to physical values
    % ----------------------------------------------------------

    if isempty(SelectedRangeIndex)

        DetectedRange = [];
        DetectedDoppler = [];
        DetectedVelocity = [];

    else

        DetectedRange = ...
            GatedRangeAxis(SelectedRangeIndex);

        DetectedDoppler = ...
            DopplerAxis(SelectedDopplerIndex);

        SpeedOfLight = 3e8;
        RadarFrequency = 10e9;

        Wavelength = SpeedOfLight / RadarFrequency;

        DetectedVelocity = ...
            DetectedDoppler * Wavelength / 2;
    end

    %% ---------------------------------------------------------
    % Store output
    % ----------------------------------------------------------

    CFARResult = struct();

    CFARResult.DetectionMap = DetectionMap;
    CFARResult.ThresholdMap = ThresholdMap;
    CFARResult.ScaledThresholdMap = ScaledThresholdMap;

    CFARResult.Range = DetectedRange(:);
    CFARResult.Doppler = DetectedDoppler(:);
    CFARResult.Velocity = DetectedVelocity(:);
    CFARResult.Amplitude = SelectedAmplitude(:);

    CFARResult.RangeIndex = SelectedRangeIndex(:);
    CFARResult.DopplerIndex = SelectedDopplerIndex(:);

    CFARResult.RangeAxis = GatedRangeAxis;
    CFARResult.DopplerAxis = DopplerAxis;

    CFARResult.NumberOfDetections = ...
        length(SelectedAmplitude);

    CFARResult.PRF = PRF;
    CFARResult.Pfa = Pfa;
    CFARResult.ThresholdScale = ThresholdScale;

    CFARResult.TrainingRange = TrainingRange;
    CFARResult.TrainingDoppler = TrainingDoppler;

    CFARResult.GuardRange = GuardRange;
    CFARResult.GuardDoppler = GuardDoppler;

    %% ---------------------------------------------------------
    % Display results
    % ----------------------------------------------------------

    fprintf('\nDetected targets : %d\n', ...
        CFARResult.NumberOfDetections);

    fprintf('Threshold scale  : %.3f\n', ThresholdScale);
    fprintf('Pfa               : %.2e\n', Pfa);

    if CFARResult.NumberOfDetections > 0

        DetectionTable = table( ...
            CFARResult.Range/1000, ...
            CFARResult.Doppler, ...
            CFARResult.Velocity, ...
            CFARResult.Amplitude, ...
            'VariableNames', { ...
            'Range_km', ...
            'Doppler_Hz', ...
            'Velocity_mps', ...
            'Amplitude'});

        disp(DetectionTable);

    else

        fprintf('No targets detected.\n');

    end

    fprintf('==============================================\n');

end