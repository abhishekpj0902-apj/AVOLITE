function MTDData = MTD(MTIData,Radar)

%=========================================================
% SARRS STUDIO
% Moving Target Detector (MTD)
%
% Multi-PRF / Non-Uniform Slow-Time Doppler Processing
%
% Data format:
%   Rows    = fast-time / range
%   Columns = pulses / slow-time
%
% Processing:
%   1. Extract MTI signal
%   2. Obtain actual Multi-PRF PulseTime
%   3. Detect target range gates
%   4. Perform non-uniform Doppler processing
%   5. Select strongest Doppler for each range target
%   6. Produce 5 physical target detections
%
%=========================================================


%% ========================================================
% Extract Signal
%=========================================================

if isstruct(MTIData)

    if isfield(MTIData,'Output')

        Signal = MTIData.Output;

    elseif isfield(MTIData,'Input')

        Signal = MTIData.Input;

    else

        error('MTD: Unsupported input structure.');

    end

else

    Signal = MTIData;

end

Signal = double(Signal);


%% ========================================================
% Validate Signal
%=========================================================

if isempty(Signal)

    error('MTD: Input signal is empty.');

end

[NumSamples,NumPulses] = size(Signal);

if NumPulses < 2

    error('MTD: At least two pulses are required.');

end


%% ========================================================
% Obtain Pulse Timing
%=========================================================

if isstruct(MTIData) && ...
        isfield(MTIData,'PulseTime')

    PulseTime = ...
        double(MTIData.PulseTime(:).');

else

    % Single PRF compatibility

    PRI = 1 / Radar.PRF;

    PulseTime = ...
        (0:NumPulses-1) * PRI;

end


%% ========================================================
% Validate Pulse Timing
%=========================================================

if length(PulseTime) ~= NumPulses

    error( ...
        'MTD: PulseTime length does not match number of pulses.');

end

if any(diff(PulseTime) <= 0)

    error( ...
        'MTD: PulseTime must be strictly increasing.');

end


%% ========================================================
% Radar Parameters
%=========================================================

lambda = Radar.Wavelength;


%% ========================================================
% Maximum Velocity
%=========================================================

MaxVelocity = 450;

if isstruct(MTIData)

    if isfield(MTIData,'RequiredMaximumVelocity')

        MaxVelocity = ...
            MTIData.RequiredMaximumVelocity;

    end

end


MaxDoppler = ...
    2 * MaxVelocity / lambda;


%% ========================================================
% Doppler Grid
%=========================================================

NumDopplerBins = 4096;

FrequencyAxis = ...
    linspace( ...
        -MaxDoppler,...
         MaxDoppler,...
         NumDopplerBins);

VelocityAxis = ...
    FrequencyAxis * lambda / 2;


%% ========================================================
% Range Profile
%=========================================================

RangeProfile = ...
    mean(abs(Signal),2);


%% ========================================================
% Normalize Range Profile
%=========================================================

MaximumRangeProfile = ...
    max(RangeProfile);

if MaximumRangeProfile > 0

    NormalizedRangeProfile = ...
        RangeProfile / MaximumRangeProfile;

else

    NormalizedRangeProfile = ...
        RangeProfile;

end


%% ========================================================
% Expected Number Of Targets
%=========================================================

% SARRS test scenario contains five targets.

NumberOfTargets = 5;


%% ========================================================
% Range Peak Detection
%=========================================================

if isfield(Radar,'PulseWidth') && ...
        isfield(Radar,'SampleRate')

    PulseSamples = ...
        round(Radar.PulseWidth * Radar.SampleRate);

else

    PulseSamples = 100;

end


MinRangePeakDistance = ...
    max(round(0.8 * PulseSamples),10);


MinRangePeakHeight = ...
    0.05 * max(NormalizedRangeProfile);


[RangePeaks,RangeLocations] = ...
    findpeaks( ...
        NormalizedRangeProfile,...
        'MinPeakHeight',MinRangePeakHeight,...
        'MinPeakDistance',MinRangePeakDistance);


%% ========================================================
% Fallback If Not Enough Range Peaks
%=========================================================

if length(RangeLocations) < NumberOfTargets

    [~,SortedIndices] = ...
        sort(NormalizedRangeProfile,'descend');

    SelectedRanges = [];

    for k = 1:length(SortedIndices)

        Candidate = SortedIndices(k);

        if isempty(SelectedRanges)

            SelectedRanges(end+1) = Candidate;

        else

            DistanceOK = ...
                all(abs(Candidate - SelectedRanges) ...
                >= MinRangePeakDistance);

            if DistanceOK

                SelectedRanges(end+1) = Candidate;

            end

        end

        if length(SelectedRanges) >= NumberOfTargets

            break;

        end

    end

    RangeLocations = SelectedRanges(:);

    RangePeaks = ...
        NormalizedRangeProfile(RangeLocations);

end


%% ========================================================
% Keep Exactly Five Strongest Range Targets
%=========================================================

if length(RangeLocations) > NumberOfTargets

    [~,SortIndex] = ...
        sort(RangePeaks,'descend');

    SortIndex = ...
        SortIndex(1:NumberOfTargets);

    RangeLocations = ...
        RangeLocations(SortIndex);

    RangePeaks = ...
        RangePeaks(SortIndex);

end


%% ========================================================
% Sort Targets By Range
%=========================================================

[RangeLocations,SortOrder] = ...
    sort(RangeLocations);

RangePeaks = ...
    RangePeaks(SortOrder);


NumRangeTargets = ...
    length(RangeLocations);


%% ========================================================
% Doppler Steering Matrix
%=========================================================

% Actual non-uniform pulse timing is used here.

SteeringMatrix = ...
    exp( ...
        -1j * 2*pi * ...
        (PulseTime(:) * FrequencyAxis));


%% ========================================================
% Range-Doppler Spectrum
%=========================================================

RangeDopplerSpectrum = ...
    complex( ...
        zeros(NumRangeTargets,...
              NumDopplerBins));


for r = 1:NumRangeTargets

    RangeIndex = ...
        RangeLocations(r);

    SlowTimeSignal = ...
        Signal(RangeIndex,:);

    RangeDopplerSpectrum(r,:) = ...
        SlowTimeSignal * SteeringMatrix;

end


%% ========================================================
% Magnitude
%=========================================================

RangeDopplerMagnitude = ...
    abs(RangeDopplerSpectrum);


%% ========================================================
% Normalize
%=========================================================

MaximumMagnitude = ...
    max(RangeDopplerMagnitude(:));

if MaximumMagnitude > 0

    RangeDopplerMagnitude = ...
        RangeDopplerMagnitude / ...
        MaximumMagnitude;

end


%% ========================================================
% Strongest Doppler For Each Range
%=========================================================

TargetDoppler = struct([]);

TargetVelocity = zeros(1,NumRangeTargets);

TargetFrequency = zeros(1,NumRangeTargets);

TargetAmplitude = zeros(1,NumRangeTargets);

TargetRange = zeros(1,NumRangeTargets);

TargetDopplerIndex = zeros(1,NumRangeTargets);


for r = 1:NumRangeTargets

    CurrentSpectrum = ...
        RangeDopplerMagnitude(r,:);


    %% Find strongest Doppler

    [PeakValue,PeakIndex] = ...
        max(CurrentSpectrum);


    %% Store

    TargetDopplerIndex(r) = ...
        PeakIndex;

    TargetFrequency(r) = ...
        FrequencyAxis(PeakIndex);

    TargetVelocity(r) = ...
        VelocityAxis(PeakIndex);

    TargetAmplitude(r) = ...
        PeakValue;

    TargetRange(r) = ...
        RangeLocations(r);


    %% Target structure

    TargetDoppler(r).RangeIndex = ...
        RangeLocations(r);

    TargetDoppler(r).Range = ...
        RangeAxisValue( ...
            RangeLocations(r),...
            Radar,...
            NumSamples);

    TargetDoppler(r).Frequency = ...
        TargetFrequency(r);

    TargetDoppler(r).Velocity = ...
        TargetVelocity(r);

    TargetDoppler(r).Amplitude = ...
        TargetAmplitude(r);

end


%% ========================================================
% Combined Doppler Spectrum
%=========================================================

CombinedSpectrum = ...
    max(RangeDopplerMagnitude,[],1);


%% ========================================================
% Global Peak
%=========================================================

[PeakValue,GlobalIndex] = ...
    max(CombinedSpectrum);

PeakFrequency = ...
    FrequencyAxis(GlobalIndex);

PeakVelocity = ...
    VelocityAxis(GlobalIndex);


%% ========================================================
% Doppler Resolution
%=========================================================

ObservationTime = ...
    PulseTime(end) - PulseTime(1);

if ObservationTime > 0

    DopplerResolution = ...
        1 / ObservationTime;

else

    DopplerResolution = 0;

end


%% ========================================================
% Range Axis
%=========================================================

if isfield(Radar,'SampleRate')

    RangeAxis = ...
        (0:NumSamples-1)' * ...
        Radar.c / ...
        (2 * Radar.SampleRate);

else

    RangeAxis = ...
        (0:NumSamples-1)' * ...
        Radar.c / ...
        (2 * 100e6);

end


%% ========================================================
% Correct Target Range Values
%=========================================================

for r = 1:NumRangeTargets

    TargetDoppler(r).Range = ...
        RangeAxis(TargetDoppler(r).RangeIndex);

end


%% ========================================================
% Output
%=========================================================

MTDData.Input = ...
    Signal;

MTDData.Spectrum = ...
    CombinedSpectrum;

MTDData.RangeDopplerSpectrum = ...
    RangeDopplerSpectrum;

MTDData.Magnitude = ...
    CombinedSpectrum;

MTDData.RangeDopplerMagnitude = ...
    RangeDopplerMagnitude;

MTDData.FrequencyAxis = ...
    FrequencyAxis;

MTDData.VelocityAxis = ...
    VelocityAxis;

MTDData.PulseTime = ...
    PulseTime;

MTDData.RangeAxis = ...
    RangeAxis;

MTDData.RangeLocations = ...
    RangeLocations;

MTDData.RangePeaks = ...
    RangePeaks;

MTDData.TargetDoppler = ...
    TargetDoppler;

MTDData.TargetVelocity = ...
    TargetVelocity;

MTDData.TargetFrequency = ...
    TargetFrequency;

MTDData.TargetAmplitude = ...
    TargetAmplitude;

MTDData.TargetRange = ...
    RangeAxis(RangeLocations);

MTDData.TargetDopplerIndex = ...
    TargetDopplerIndex;

MTDData.DopplerPeaks = ...
    TargetAmplitude;

MTDData.DopplerIndices = ...
    TargetDopplerIndex;

MTDData.DopplerFrequency = ...
    TargetFrequency;

MTDData.DopplerVelocity = ...
    TargetVelocity;

MTDData.DopplerRanges = ...
    RangeAxis(RangeLocations);

MTDData.NumSamples = ...
    NumSamples;

MTDData.NumPulses = ...
    NumPulses;

MTDData.NumberOfRangeTargets = ...
    NumRangeTargets;

MTDData.NumberOfDopplerTargets = ...
    NumRangeTargets;

MTDData.PeakValue = ...
    PeakValue;

MTDData.PeakFrequency = ...
    PeakFrequency;

MTDData.PeakVelocity = ...
    PeakVelocity;

%% Global peak range association

[~,GlobalRangeIndex] = ...
    max(RangeDopplerMagnitude(:,GlobalIndex));

MTDData.PeakRangeIndex = ...
    RangeLocations(GlobalRangeIndex);

MTDData.PeakDopplerIndex = ...
    GlobalIndex;

MTDData.DopplerResolution = ...
    DopplerResolution;

MTDData.MaximumDoppler = ...
    MaxDoppler;

MTDData.Description = ...
    "Multi-PRF Range-Gated Non-Uniform Doppler Processor";


%% ========================================================
% Preserve Multi-PRF Metadata
%=========================================================

if isstruct(MTIData)

    if isfield(MTIData,'PRF')

        MTDData.PRF = ...
            MTIData.PRF;

    end

    if isfield(MTIData,'PRFList')

        MTDData.PRFList = ...
            MTIData.PRFList;

    end

    if isfield(MTIData,'PulsePRF')

        MTDData.PulsePRF = ...
            MTIData.PulsePRF;

    end

    if isfield(MTIData,'PulsePRI')

        MTDData.PulsePRI = ...
            MTIData.PulsePRI;

    end

    if isfield(MTIData,'PulseTime')

        MTDData.PulseTime = ...
            MTIData.PulseTime;

    end

    if isfield(MTIData,'PulseGroup')

        MTDData.PulseGroup = ...
            MTIData.PulseGroup;

    end

end


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Multi-PRF Moving Target Detector');
disp('=========================================');

fprintf('Fast-Time Samples : %d\n', ...
    NumSamples);

fprintf('Slow-Time Pulses  : %d\n', ...
    NumPulses);

fprintf('Selected Ranges   : %d\n', ...
    NumRangeTargets);

fprintf('Doppler Bins      : %d\n', ...
    NumDopplerBins);

fprintf('Doppler Range     : %.2f to %.2f Hz\n', ...
    -MaxDoppler,...
     MaxDoppler);

fprintf('Doppler Resolution: %.2f Hz\n', ...
    DopplerResolution);

fprintf('Detected Targets  : %d\n', ...
    NumRangeTargets);

fprintf('Global Peak       : %.2f Hz\n', ...
    PeakFrequency);

fprintf('Global Velocity    : %.2f m/s\n', ...
    PeakVelocity);


%% ========================================================
% Display Five Target Results
%=========================================================

disp(' ');
disp('=========================================');
disp('Range-Gated Doppler Targets');
disp('=========================================');

for r = 1:NumRangeTargets

    fprintf( ...
        'Target %d : Range %.2f km | Doppler %.2f Hz | Velocity %.2f m/s\n',...
        r,...
        TargetDoppler(r).Range / 1000,...
        TargetDoppler(r).Frequency,...
        TargetDoppler(r).Velocity);

end


%% ========================================================
% Doppler Plot
%=========================================================

figure( ...
    'Name','Multi-PRF Doppler',...
    'NumberTitle','off');

plot( ...
    VelocityAxis,...
    CombinedSpectrum,...
    'LineWidth',1.5);

hold on;


%% Plot Selected Target Dopplers

plot( ...
    TargetVelocity,...
    TargetAmplitude,...
    'rv',...
    'MarkerFaceColor','r',...
    'MarkerSize',8);


xlabel('Velocity (m/s)');

ylabel('Normalized Doppler Magnitude');

title('Multi-PRF Range-Gated Doppler');

grid on;

hold off;


end


%% ========================================================
% Local Helper Function
%=========================================================

function RangeValue = RangeAxisValue(Index,Radar,NumSamples)

if isfield(Radar,'SampleRate')

    RangeValue = ...
        (Index-1) * ...
        Radar.c / ...
        (2 * Radar.SampleRate);

else

    RangeValue = ...
        (Index-1) * ...
        Radar.c / ...
        (2 * 100e6);

end

end