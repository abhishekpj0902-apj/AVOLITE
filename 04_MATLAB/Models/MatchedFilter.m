function MatchedData = MatchedFilter(ReceiverData,WaveformData,Radar)

%=========================================================
% SARRS STUDIO
% Digital Matched Filter
%
% Supports:
%   ✓ Multi-pulse processing
%   ✓ Pulse compression
%   ✓ Range estimation
%   ✓ Multiple target detection
%   ✓ Peak detection
%
% Data format:
%   Rows    = fast-time / range
%   Columns = pulses / slow-time
%=========================================================


%% ========================================================
% Inputs
%=========================================================

Rx = double(ReceiverData.OutputSignal);

Tx = double(WaveformData.Signal(:));

Fs = WaveformData.SampleRate;


%% ========================================================
% Validate Input
%=========================================================

if isempty(Rx)

    error('MatchedFilter: Receiver output is empty.');

end

if isempty(Tx)

    error('MatchedFilter: Waveform contains no pulse.');

end


%% ========================================================
% Determine Data Dimensions
%=========================================================

[NumSamples,NumPulses] = size(Rx);


%% ========================================================
% Extract Actual Transmitted Pulse
%=========================================================

PulseLength = nnz(Tx);

if PulseLength == 0

    error('MatchedFilter: Waveform contains no pulse.');

end

Pulse = Tx(1:PulseLength);


%% ========================================================
% Matched Filter Reference
%=========================================================

Reference = conj(flipud(Pulse));


%% ========================================================
% Matched Filter Output
%=========================================================

ComplexOutput = ...
    complex(zeros(NumSamples,NumPulses));

for p = 1:NumPulses

    CurrentPulse = Rx(:,p);

    FilteredPulse = ...
        conv(CurrentPulse,Reference,'same');

    ComplexOutput(:,p) = ...
        FilteredPulse;

end


%% ========================================================
% Magnitude Output
%=========================================================

Output = abs(ComplexOutput);


%% ========================================================
% Normalize
%=========================================================

%% ========================================================
% Normalize
%=========================================================

MaximumValue = ...
    max(abs(ComplexOutput(:)));

if MaximumValue > 0

    ComplexOutput = ...
        ComplexOutput ./ MaximumValue;

end

Output = abs(ComplexOutput);


%% ========================================================
% Range Axis
%=========================================================

RangeAxis = ...
    (0:NumSamples-1)' * Radar.c /(2*Fs);


%% ========================================================
% Peak Detection
%=========================================================

% Use non-coherent pulse integration for detection.
IntegratedOutput = mean(Output,2);


%% ========================================================
% Peak Parameters
%=========================================================

MinPeakHeight = ...
    max(IntegratedOutput) * 0.08;

MinPeakDistance = ...
    round(0.8 * PulseLength);


%% ========================================================
% Find Peaks
%=========================================================

[Peaks,Locs] = findpeaks( ...
    IntegratedOutput,...
    'MinPeakHeight',MinPeakHeight,...
    'MinPeakDistance',MinPeakDistance);


%% ========================================================
% Peak Ranges
%=========================================================

PeakRanges = RangeAxis(Locs);


%% ========================================================
% Store Results
%=========================================================

MatchedData.Reference = Reference;

MatchedData.ComplexOutput = ...
    ComplexOutput;

MatchedData.Output = ...
    ComplexOutput;

MatchedData.Magnitude = ...
    Output;

MatchedData.IntegratedOutput = ...
    IntegratedOutput;

MatchedData.RangeAxis = RangeAxis;

MatchedData.Peaks = Peaks;

MatchedData.PeakIndices = Locs;

MatchedData.PeakRanges = PeakRanges;

MatchedData.NumberOfPeaks = ...
    length(Peaks);

MatchedData.NumPulses = NumPulses;

MatchedData.SampleRate = Fs;

MatchedData.PulseLength = PulseLength;


%% ========================================================
% Largest Peak
%=========================================================

if isempty(Peaks)

    MatchedData.Peak = 0;

    MatchedData.PeakIndex = 0;

    MatchedData.PeakRange = 0;

else

    [MatchedData.Peak,idx] = max(Peaks);

    MatchedData.PeakIndex = Locs(idx);

    MatchedData.PeakRange = PeakRanges(idx);

end


%% ========================================================
% Description
%=========================================================

MatchedData.Description = ...
    "Multi-Pulse Digital Matched Filter";


%% ========================================================
% Display
%=========================================================

disp(' ')
disp('=========================================')
disp('Multi-Pulse Matched Filter')
disp('=========================================')

fprintf('Samples         : %d\n',NumSamples);

fprintf('Pulses          : %d\n',NumPulses);

fprintf('Pulse Length    : %d samples\n',PulseLength);

fprintf('Output Size     : %d x %d\n', ...
    size(Output,1),size(Output,2));
fprintf('Complex Output  : %d x %d\n', ...
size(ComplexOutput,1), ...
size(ComplexOutput,2));

fprintf('Detected Peaks  : %d\n', ...
    MatchedData.NumberOfPeaks);


if MatchedData.NumberOfPeaks > 0

    disp(' ')
    disp('Peak Ranges (m)')

    disp(round(MatchedData.PeakRanges(:)));

end


%% ========================================================
% Plot Integrated Range Profile
%=========================================================

figure( ...
    'Name','Matched Filter',...
    'NumberTitle','off');

plot( ...
    RangeAxis/1000,...
    IntegratedOutput,...
    'LineWidth',1.5);

hold on;


if ~isempty(Locs)

    plot( ...
        PeakRanges/1000,...
        Peaks,...
        'rv',...
        'MarkerFaceColor','r',...
        'MarkerSize',8);

end


xlabel('Range (km)');

ylabel('Normalized Amplitude');

title('Multi-Pulse Matched Filter Output');

grid on;

hold off;

%% ========================================================
% Preserve Multi-PRF Metadata
%=========================================================

if isstruct(ReceiverData)

    if isfield(ReceiverData,'PRF')

        MatchedData.PRF = ...
            ReceiverData.PRF;

    end

    if isfield(ReceiverData,'PRFList')

        MatchedData.PRFList = ...
            ReceiverData.PRFList;

    end

    if isfield(ReceiverData,'PulsePRF')

        MatchedData.PulsePRF = ...
            ReceiverData.PulsePRF;

    end

    if isfield(ReceiverData,'PulsePRI')

        MatchedData.PulsePRI = ...
            ReceiverData.PulsePRI;

    end

    if isfield(ReceiverData,'PulseTime')

        MatchedData.PulseTime = ...
            ReceiverData.PulseTime;

    end

    if isfield(ReceiverData,'PulseGroup')

        MatchedData.PulseGroup = ...
            ReceiverData.PulseGroup;

    end

    if isfield(ReceiverData,'PRI')

        MatchedData.PRI = ...
            ReceiverData.PRI;

    end

end
end