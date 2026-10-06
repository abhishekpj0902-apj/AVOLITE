function CFARResult = CFARDetector(Matched)
%=========================================================
% SARRS STUDIO
% Basic 1-D Range CFAR Detector
%
% Input:
%   Matched.Output
%
% Supports:
%   1-D signal
%   Range-by-pulse matrix
%
% For a matrix, pulse magnitudes are averaged to form
% one range profile before CFAR processing.
%=========================================================

%% Validate input

if nargin < 1
    error('CFARDetector requires one input structure.');
end

if ~isstruct(Matched)
    error('Input must be a structure.');
end

if ~isfield(Matched, 'Output')
    error('Input structure must contain the field Output.');
end

%% Extract signal

Signal = abs(double(Matched.Output));

if isempty(Signal)
    error('CFARDetector: Input signal is empty.');
end

%% Convert range-by-pulse data into 1-D range profile

if isvector(Signal)

    signal = Signal(:);

else

    % Average across pulses
    signal = mean(Signal, 2);

end

signal = real(signal);

NumSamples = length(signal);

%% Find scalar peak safely

[p, idx] = max(signal);

fprintf('\n');
fprintf('========== CFAR DEBUG ==========\n');
fprintf('Peak Value  : %.6e\n', p);
fprintf('Peak Index  : %d\n', idx);

%% CFAR parameters

NumGuardCells = 60;
NumTrainingCells = 31;
ScaleFactor = 1.2;

threshold = zeros(NumSamples, 1);
detection = zeros(NumSamples, 1);

StartIndex = NumTrainingCells + NumGuardCells + 1;

EndIndex = NumSamples - NumTrainingCells - NumGuardCells;

%% Cell-averaging CFAR

for k = StartIndex:EndIndex

    LeadingCells = signal( ...
        k - NumGuardCells - NumTrainingCells : ...
        k - NumGuardCells - 1);

    TrailingCells = signal( ...
        k + NumGuardCells + 1 : ...
        k + NumGuardCells + NumTrainingCells);

    NoiseEstimate = mean([ ...
        LeadingCells;
        TrailingCells]);

    threshold(k) = ScaleFactor * NoiseEstimate;

    if signal(k) > threshold(k)
        detection(k) = signal(k);
    end

end

fprintf('\n========== CFAR THRESHOLD DEBUG ==========\n');
fprintf('Maximum Signal    : %.6e\n', max(signal));
fprintf('Maximum Threshold : %.6e\n', max(threshold));
fprintf('Maximum Detection : %.6e\n', max(detection));
fprintf('Samples Above Threshold : %d\n', ...
    nnz(signal > threshold));
%% Find detected peaks

if any(detection > 0)

    MinimumPeakHeight = 0.5 * max(detection);

    [Peaks, Locations] = findpeaks( ...
        detection, ...
        'MinPeakHeight', MinimumPeakHeight, ...
        'MinPeakDistance', 300);

else

    Peaks = [];
    Locations = [];

end

%% Range axis

if isfield(Matched, 'SampleRate')

    Fs = Matched.SampleRate;

else

    Fs = 100e6;

end

c = 3e8;

RangeAxis = ...
    (0:NumSamples-1)' * c / (2 * Fs);

%% Output structure

CFARResult.Input = Signal;

CFARResult.Signal = signal;

CFARResult.Threshold = threshold;

CFARResult.Detection = detection;

CFARResult.Peaks = Peaks;

CFARResult.Index = Locations;

CFARResult.NumberOfTargets = length(Locations);

CFARResult.TargetDetected = ~isempty(Locations);

CFARResult.RangeAxis = RangeAxis;

CFARResult.SampleRate = Fs;

CFARResult.Description = ...
    "Basic 1-D Range CFAR Detector";

%% Display result

fprintf('\n');
fprintf('========== CFAR RESULT ==========\n');
fprintf('Number of Detected Peaks : %d\n', ...
    CFARResult.NumberOfTargets);

for k = 1:CFARResult.NumberOfTargets

    RangeValue = RangeAxis(Locations(k));

    fprintf( ...
        'Detection %d : Range = %.3f km | Amplitude = %.6e\n', ...
        k, ...
        RangeValue / 1000, ...
        Peaks(k));

end

end