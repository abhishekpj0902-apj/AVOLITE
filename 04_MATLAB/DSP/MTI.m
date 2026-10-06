function MTIData = MTI(InputData)
% MTI - Two-pulse canceller for stationary clutter suppression
%
% Accepts:
%   1. Numeric pulse-compressed matrix
%   2. Pulse-compressed structure containing .Output
%
% Input matrix:
%   Rows    = fast-time/range samples
%   Columns = slow-time pulses
%
% Output:
%   MTIData.Output
%   MTIData.Magnitude
%   MTIData.RangeAxis
%   MTIData.PRF
%   MTIData.SampleRate
%   MTIData.NumRangeSamples
%   MTIData.NumPulses

    % -------------------------------------------------------------
    % Extract input signal and metadata
    % -------------------------------------------------------------

    if isstruct(InputData)

        if isfield(InputData, 'Output')
            Signal = InputData.Output;

        elseif isfield(InputData, 'Signal')
            Signal = InputData.Signal;

        elseif isfield(InputData, 'Input')
            Signal = InputData.Input;

        else
            error('Input structure must contain Output, Signal, or Input.');
        end

        % Copy metadata if available
        if isfield(InputData, 'RangeAxis')
            MTIData.RangeAxis = InputData.RangeAxis;
        else
            MTIData.RangeAxis = [];
        end

        if isfield(InputData, 'SampleRate')
            MTIData.SampleRate = InputData.SampleRate;
        else
            MTIData.SampleRate = [];
        end

        if isfield(InputData, 'PRF')
            MTIData.PRF = InputData.PRF;
        else
            MTIData.PRF = [];
        end

        if isfield(InputData, 'FilterLength')
            MTIData.FilterLength = InputData.FilterLength;
        end

    elseif isnumeric(InputData)

        Signal = InputData;

        MTIData.RangeAxis = [];
        MTIData.SampleRate = [];
        MTIData.PRF = [];

    else
        error('InputData must be numeric or a structure.');
    end

    % -------------------------------------------------------------
    % Validate and convert input
    % -------------------------------------------------------------

    if isempty(Signal)
        error('Input signal cannot be empty.');
    end

    Signal = double(Signal);

    if isvector(Signal)
        Signal = Signal(:);
    end

    [NumRangeSamples, NumInputPulses] = size(Signal);

    if NumInputPulses < 2
        error('MTI requires at least two pulses.');
    end

    % -------------------------------------------------------------
    % Two-pulse canceller
    %
    % y(k) = x(k+1) - x(k)
    % -------------------------------------------------------------

    MTIData.Output = diff(Signal, 1, 2);

    % Magnitude for plotting and detection
    MTIData.Magnitude = abs(MTIData.Output);

    % -------------------------------------------------------------
    % Store dimensions
    % -------------------------------------------------------------

    [MTIData.NumRangeSamples, MTIData.NumPulses] = ...
        size(MTIData.Output);

    MTIData.InputNumPulses = NumInputPulses;

    % -------------------------------------------------------------
    % Preserve useful metadata
    % -------------------------------------------------------------

    MTIData.Method = "Two-pulse canceller";

    MTIData.Description = ...
        "MTI two-pulse canceller for stationary clutter suppression";

    % The range axis remains unchanged because MTI operates across
    % pulses, not across fast-time/range samples.
    if ~isempty(MTIData.RangeAxis)
        MTIData.RangeAxis = MTIData.RangeAxis(:);
    end

    % -------------------------------------------------------------
    % Display information
    % -------------------------------------------------------------

    fprintf('\n==============================================\n');
    fprintf('MTI Clutter Cancellation Complete\n');
    fprintf('==============================================\n');

    fprintf('Input Range Samples  : %d\n', NumRangeSamples);
    fprintf('Input Pulses         : %d\n', NumInputPulses);
    fprintf('Output Range Samples : %d\n', MTIData.NumRangeSamples);
    fprintf('Output Pulses        : %d\n', MTIData.NumPulses);

    if ~isempty(MTIData.PRF)
        fprintf('PRF                  : %.2f Hz\n', MTIData.PRF);
    end

    fprintf('Method               : %s\n', MTIData.Method);
end