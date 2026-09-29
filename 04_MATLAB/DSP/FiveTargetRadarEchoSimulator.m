%% FiveTargetRadarEchoSimulator.m
% SARRS STUDIO
% Five-target radar echo simulation
%
% Processing:
%   1. Radar configuration
%   2. Five-target echo generation
%   3. Range FFT
%   4. Doppler FFT
%   5. Range-Doppler map
%   6. 2D CA-CFAR
%   7. Local peak detection
%   8. Physical coordinate conversion
%   9. Target validation
%
% Required file:
%   CA_CFAR_2D.m
%
% Keep CA_CFAR_2D.m in the same folder.

clc;
clear;
close all;

rng(10);

%% ============================================================
% 1. RADAR CONFIGURATION
% =============================================================

Radar = struct;

Radar.PRF        = 800;       % Pulse repetition frequency, Hz
Radar.SampleRate = 10e6;      % Fast-time sample rate, Hz
Radar.Wavelength = 0.03;      % Carrier wavelength, m
Radar.c          = 3e8;       % Speed of light, m/s

%% ============================================================
% 2. SIMULATION PARAMETERS
% =============================================================

NFastTime = 256;              % Fast-time samples per pulse
NPulses   = 128;              % Number of coherent pulses

NoiseSigma = 0.03;            % Complex noise level

%% ============================================================
% 3. FIVE TARGET DEFINITIONS
% =============================================================

TargetRanges_m = [75 150 225 300 375];

TargetVelocities_mps = [-5 -3 -1 2 4];

TargetAmplitudes = [1.00 0.95 0.90 0.85 0.80];

NumberOfTargets = numel(TargetRanges_m);

%% ============================================================
% 4. TIME AXES
% =============================================================

FastTime = ...
    (0:NFastTime-1) / Radar.SampleRate;

SlowTime = ...
    (0:NPulses-1) / Radar.PRF;

%% ============================================================
% 5. SIMPLIFIED RANGE MODEL
% ============================================================
%
% This is a simplified FMCW-like model.
% It is suitable for algorithm development and simulation.
%
% Maximum simulated range = 1.25 times the largest target range.

MaximumSimulationRange_m = ...
    1.25 * max(TargetRanges_m);

RangeBinScale_Hz_per_m = ...
    Radar.SampleRate / ...
    (2 * MaximumSimulationRange_m);

%% ============================================================
% 6. GENERATE COMPLEX RECEIVED DATA
% =============================================================

ReceivedData = ...
    NoiseSigma/sqrt(2) * ...
    (randn(NFastTime,NPulses) + ...
     1i*randn(NFastTime,NPulses));

for k = 1:NumberOfTargets

    TargetRange = TargetRanges_m(k);

    TargetVelocity = ...
        TargetVelocities_mps(k);

    TargetAmplitude = ...
        TargetAmplitudes(k);

    % Simplified range beat frequency
    RangeFrequency_Hz = ...
        TargetRange * RangeBinScale_Hz_per_m;

    % Doppler frequency
    DopplerFrequency_Hz = ...
        2 * TargetVelocity / Radar.Wavelength;

    % Range phase
    RangePhase = ...
        2*pi*RangeFrequency_Hz*FastTime(:);

    % Doppler phase
    DopplerPhase = ...
        2*pi*DopplerFrequency_Hz*SlowTime;

    % Separable target signal
    TargetSignal = ...
        TargetAmplitude * ...
        exp(1i*RangePhase) * ...
        exp(1i*DopplerPhase);

    ReceivedData = ...
        ReceivedData + TargetSignal;

end

%% ============================================================
% 7. APPLY WINDOWS
% =============================================================

RangeWindow = hann(NFastTime);

DopplerWindow = hann(NPulses).';

WindowedData = ...
    ReceivedData .* RangeWindow;

WindowedData = ...
    WindowedData .* DopplerWindow;

%% ============================================================
% 8. RANGE FFT
% =============================================================

RangeFFTFull = ...
    fft(WindowedData, NFastTime, 1);

% Keep positive range-frequency half
NRangeBins = floor(NFastTime/2);

RangeFFT = ...
    RangeFFTFull(1:NRangeBins,:);

%% ============================================================
% 9. DOPPLER FFT
% =============================================================

RangeDopplerComplex = ...
    fftshift( ...
    fft(RangeFFT, NPulses, 2), ...
    2);

%% ============================================================
% 10. POWER MAP
% =============================================================

RangeDopplerPower = ...
    abs(RangeDopplerComplex).^2;

MaximumPower = ...
    max(RangeDopplerPower(:));

RangeDopplerPowerNormalized = ...
    RangeDopplerPower / MaximumPower;

RangeDopplerPower_dB = ...
    10*log10(RangeDopplerPowerNormalized + eps);

%% ============================================================
% 11. PHYSICAL AXES
% =============================================================

% Range-frequency axis
RangeFrequencyAxis_Hz = ...
    (0:NRangeBins-1) * ...
    Radar.SampleRate / NFastTime;

% Simplified physical range axis
RangeAxis_m = ...
    RangeFrequencyAxis_Hz / ...
    RangeBinScale_Hz_per_m;

% Doppler-frequency axis
DopplerAxis_Hz = ...
    (-NPulses/2:NPulses/2-1) * ...
    Radar.PRF / NPulses;

% Velocity axis
VelocityAxis_mps = ...
    DopplerAxis_Hz * ...
    Radar.Wavelength / 2;

%% ============================================================
% 12. DISPLAY RANGE-DOPPLER MAP
% =============================================================

figure;

imagesc( ...
    VelocityAxis_mps, ...
    RangeAxis_m, ...
    RangeDopplerPower_dB);

axis xy;
colorbar;
caxis([-60 0]);

xlabel('Radial velocity (m/s)');
ylabel('Range (m)');
title('Simulated Five-Target Range-Doppler Map');

hold on;

plot( ...
    TargetVelocities_mps, ...
    TargetRanges_m, ...
    'rx', ...
    'MarkerSize', 12, ...
    'LineWidth', 2);

legend('Known targets');

hold off;

%% ============================================================
% 13. CA-CFAR CONFIGURATION
% =============================================================

TrainingCells = 8;
GuardCells = 2;
ThresholdFactor = 14;

%% ============================================================
% 14. CHECK CA-CFAR FUNCTION
% =============================================================

if exist('CA_CFAR_2D','file') ~= 2

    error([ ...
        'CA_CFAR_2D.m was not found. ', ...
        'Place CA_CFAR_2D.m in the current folder or MATLAB path.' ...
        ]);

end

%% ============================================================
% 15. RUN 2D CA-CFAR
% =============================================================

DetectionMap = ...
    CA_CFAR_2D( ...
    RangeDopplerPower, ...
    TrainingCells, ...
    GuardCells, ...
    ThresholdFactor);

%% ============================================================
% 16. LOCAL PEAK DETECTION
% =============================================================

DetectionMapPeak = ...
    false(size(DetectionMap));

[NumberOfRows, NumberOfColumns] = ...
    size(DetectionMap);

for r = 2:NumberOfRows-1

    for d = 2:NumberOfColumns-1

        if DetectionMap(r,d)

            LocalWindow = ...
                RangeDopplerPower( ...
                r-1:r+1, ...
                d-1:d+1);

            CenterPower = ...
                RangeDopplerPower(r,d);

            if CenterPower == max(LocalWindow(:))

                DetectionMapPeak(r,d) = true;

            end

        end

    end

end

%% ============================================================
% 17. EXTRACT DETECTION BINS
% =============================================================

[PeakRangeBins, PeakDopplerBins] = ...
    find(DetectionMapPeak);

%% ============================================================
% 18. CONVERT DETECTIONS TO PHYSICAL VALUES
% =============================================================

DetectedRanges_m = ...
    RangeAxis_m(PeakRangeBins);

DetectedDopplers_Hz = ...
    DopplerAxis_Hz(PeakDopplerBins);

DetectedVelocities_mps = ...
    DetectedDopplers_Hz * ...
    Radar.Wavelength / 2;

DetectedPowers = ...
    RangeDopplerPower(DetectionMapPeak);

%% ============================================================
% 19. CREATE DETECTION TABLE
% =============================================================

DetectionPhysicalTable = ...
    table( ...
    PeakRangeBins(:), ...
    PeakDopplerBins(:), ...
    DetectedRanges_m(:), ...
    DetectedDopplers_Hz(:), ...
    DetectedVelocities_mps(:), ...
    DetectedPowers(:), ...
    'VariableNames', ...
    { ...
    'RangeBin', ...
    'DopplerBin', ...
    'Range_m', ...
    'Doppler_Hz', ...
    'Velocity_mps', ...
    'Power' ...
    });

%% ============================================================
% 20. DISPLAY RESULT
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('FIVE-TARGET RADAR ECHO SIMULATION RESULT\n');
fprintf('============================================\n');

fprintf('Fast-time samples : %d\n', NFastTime);
fprintf('Number of pulses  : %d\n', NPulses);
fprintf('PRF               : %.2f Hz\n', Radar.PRF);
fprintf('Sample rate       : %.2f MHz\n', ...
    Radar.SampleRate/1e6);

fprintf('Wavelength        : %.4f m\n', ...
    Radar.Wavelength);

fprintf('Training cells    : %d\n', ...
    TrainingCells);

fprintf('Guard cells       : %d\n', ...
    GuardCells);

fprintf('CFAR threshold    : %.2f\n', ...
    ThresholdFactor);

fprintf('Detected peaks    : %d\n', ...
    numel(PeakRangeBins));

fprintf('============================================\n');

disp(DetectionPhysicalTable);

%% ============================================================
% 21. PLOT CFAR DETECTIONS
% =============================================================

figure;

imagesc( ...
    VelocityAxis_mps, ...
    RangeAxis_m, ...
    DetectionMapPeak);

axis xy;
colorbar;

xlabel('Radial velocity (m/s)');
ylabel('Range (m)');
title('CA-CFAR Detection of Simulated Targets');

hold on;

plot( ...
    TargetVelocities_mps, ...
    TargetRanges_m, ...
    'rx', ...
    'MarkerSize', 14, ...
    'LineWidth', 3);

plot( ...
    DetectedVelocities_mps, ...
    DetectedRanges_m, ...
    'wo', ...
    'MarkerSize', 8, ...
    'LineWidth', 1.5);

legend( ...
    'Known targets', ...
    'Detected peaks');

hold off;

%% ============================================================
% 22. TARGET VALIDATION
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('TARGET DETECTION VALIDATION\n');
fprintf('============================================\n');

DetectionToleranceRange_m = 5;
DetectionToleranceVelocity_mps = 0.20;

TargetDetectedFlags = ...
    false(NumberOfTargets,1);

for k = 1:NumberOfTargets

    RangeError = ...
        abs(DetectedRanges_m - TargetRanges_m(k));

    VelocityError = ...
        abs(DetectedVelocities_mps - ...
            TargetVelocities_mps(k));

    MatchingDetection = ...
        (RangeError <= DetectionToleranceRange_m) & ...
        (VelocityError <= DetectionToleranceVelocity_mps);

    TargetDetectedFlags(k) = ...
        any(MatchingDetection);

    fprintf( ...
        'Target %d: Range = %.2f m, ', ...
        k, TargetRanges_m(k));

    fprintf( ...
        'Velocity = %.2f m/s, Detected = %d\n', ...
        TargetVelocities_mps(k), ...
        TargetDetectedFlags(k));

end

NumberOfTargetsDetected = ...
    sum(TargetDetectedFlags);

NumberOfFalseAlarms = ...
    numel(PeakRangeBins) - NumberOfTargetsDetected;

fprintf('--------------------------------------------\n');
fprintf('Targets injected : %d\n', NumberOfTargets);
fprintf('Targets detected : %d\n', NumberOfTargetsDetected);
fprintf('False alarms     : %d\n', NumberOfFalseAlarms);
fprintf('Total peaks      : %d\n', numel(PeakRangeBins));
fprintf('============================================\n');

if NumberOfTargetsDetected == NumberOfTargets

    fprintf('CFAR TARGET DETECTION: PASS\n');

else

    fprintf('CFAR TARGET DETECTION: CHECK REQUIRED\n');

end

%% ============================================================
% 23. EXPORT VARIABLES TO MATLAB WORKSPACE
% =============================================================

assignin('base','Radar',Radar);

assignin('base','ReceivedData',ReceivedData);
assignin('base','WindowedData',WindowedData);

assignin('base','RangeFFT',RangeFFT);
assignin('base','RangeDopplerComplex',RangeDopplerComplex);

assignin('base','RangeDopplerPower',RangeDopplerPower);
assignin('base','RangeDopplerPowerNormalized', ...
    RangeDopplerPowerNormalized);

assignin('base','RangeDopplerPower_dB', ...
    RangeDopplerPower_dB);

assignin('base','RangeAxis_m',RangeAxis_m);
assignin('base','DopplerAxis_Hz',DopplerAxis_Hz);
assignin('base','VelocityAxis_mps',VelocityAxis_mps);

assignin('base','DetectionMap',DetectionMap);
assignin('base','DetectionMapPeak',DetectionMapPeak);

assignin('base','PeakRangeBins',PeakRangeBins);
assignin('base','PeakDopplerBins',PeakDopplerBins);

assignin('base','DetectedRanges_m',DetectedRanges_m);
assignin('base','DetectedDopplers_Hz',DetectedDopplers_Hz);
assignin('base','DetectedVelocities_mps', ...
    DetectedVelocities_mps);

assignin('base','DetectedPowers',DetectedPowers);
assignin('base','DetectionPhysicalTable', ...
    DetectionPhysicalTable);

assignin('base','TargetRanges_m',TargetRanges_m);
assignin('base','TargetVelocities_mps', ...
    TargetVelocities_mps);

assignin('base','TargetAmplitudes',TargetAmplitudes);

fprintf('\n');
fprintf('Simulation variables exported to MATLAB workspace.\n');