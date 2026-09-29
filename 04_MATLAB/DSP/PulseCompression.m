function MatchedData = PulseCompression(InputData)
%=========================================================
% SARRS STUDIO
% Basic Matched Filter / Pulse Compression
%
% Input:
%   Echo structure containing:
%       Signal
%       SampleRate
%
% Output:
%   MatchedData.Output
%   MatchedData.Magnitude
%   MatchedData.RangeAxis
%=========================================================

%% Extract input signal

if isstruct(InputData)

    if isfield(InputData, 'Signal')
        Signal = InputData.Signal;

    elseif isfield(InputData, 'Input')
        Signal = InputData.Input;

    elseif isfield(InputData, 'Output')
        Signal = InputData.Output;

    else
        error('PulseCompression: No valid signal field found.');
    end

else
    Signal = InputData;
end

Signal = double(Signal);

if isempty(Signal)
    error('PulseCompression: Input signal is empty.');
end

%% Ensure range-by-pulse format

if isvector(Signal)
    Signal = Signal(:);
end

[NumSamples, NumPulses] = size(Signal);

%% Create simple rectangular matched-filter reference

ReferenceLength = min(100, NumSamples);

Reference = ones(ReferenceLength, 1);

%% Matched filtering

CompressedSignal = zeros(NumSamples, NumPulses);

for pulse = 1:NumPulses

    CurrentPulse = Signal(:, pulse);

    FilteredPulse = conv( ...
        CurrentPulse, ...
        conj(flipud(Reference)), ...
        'same');

    CompressedSignal(:, pulse) = FilteredPulse;

end

%% Magnitude

Magnitude = abs(CompressedSignal);

%% Range axis

if isstruct(InputData) && isfield(InputData, 'SampleRate')

    Fs = InputData.SampleRate;

else

    Fs = 100e6;

end

c = 3e8;

RangeAxis = ...
    (0:NumSamples-1)' * c / (2 * Fs);

%% Output

MatchedData.Input = Signal;

MatchedData.Output = CompressedSignal;

MatchedData.Magnitude = Magnitude;

MatchedData.RangeAxis = RangeAxis;

MatchedData.SampleRate = Fs;

MatchedData.NumSamples = NumSamples;

MatchedData.NumPulses = NumPulses;

MatchedData.FilterLength = ReferenceLength;

MatchedData.Description = ...
    "Basic Rectangular Matched Filter";

%% Preserve metadata

if isstruct(InputData)

    fieldsToCopy = { ...
        'PRF', ...
        'PRFList', ...
        'PulsePRF', ...
        'PulsePRI', ...
        'PulseTime', ...
        'PulseGroup', ...
        'RequiredMaximumVelocity'};

    for k = 1:length(fieldsToCopy)

        fieldName = fieldsToCopy{k};

        if isfield(InputData, fieldName)
            MatchedData.(fieldName) = InputData.(fieldName);
        end

    end

end

disp(' ');
disp('=========================================');
disp('Pulse Compression');
disp('=========================================');

fprintf('Input Size       : %d x %d\n', ...
    NumSamples, NumPulses);

fprintf('Filter Length    : %d samples\n', ...
    ReferenceLength);

fprintf('Output Size      : %d x %d\n', ...
    size(CompressedSignal,1), ...
    size(CompressedSignal,2));

end