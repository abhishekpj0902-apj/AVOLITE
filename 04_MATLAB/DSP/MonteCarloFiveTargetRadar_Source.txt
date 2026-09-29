%% ============================================
% MonteCarloFiveTargetRadar.m
%
% SARRS STUDIO
% Monte Carlo Performance Evaluation
%
% Required external function:
%   CA_CFAR_2D.m
%
% This script evaluates:
%   1. Detection probability
%   2. False alarm rate
%   3. Range RMSE
%   4. Velocity RMSE
%   5. Detection performance versus noise
% ============================================

clc;
close all;
clear;

rng('shuffle');

%% ============================================
% 1. RADAR CONFIGURATION
% ============================================

Radar.PRF = 800;
Radar.SampleRate = 10e6;
Radar.Wavelength = 0.03;
Radar.c = 3e8;

%% ============================================
% 2. SIMULATION PARAMETERS
% ============================================

NFastTime = 256;
NPulses = 128;

NumberOfMonteCarloRuns = 100;

NoiseSigma = 0.10;

TrainingCells = 8;
GuardCells = 2;
ThresholdFactor = 14;

RangeTolerance_m = 5;
VelocityTolerance_mps = 0.15;

%% ============================================
% 3. TARGET DEFINITIONS
% ============================================

TargetRanges_m = [75 150 225 300 375];

TargetVelocities_mps = [-5 -3 -1 2 4];

TargetAmplitudes = [1.00 0.95 0.90 0.85 0.80];

NumberOfTargets = numel(TargetRanges_m);

%% ============================================
% 4. AXES AND RANGE MODEL
% ============================================

FastTime = ...
    (0:NFastTime-1) / Radar.SampleRate;

SlowTime = ...
    (0:NPulses-1) / Radar.PRF;

RangeBinScale_Hz_per_m = ...
    Radar.SampleRate / ...
    (2 * max(TargetRanges_m) * 1.25);

NRangeBins = floor(NFastTime/2);

RangeFrequencyAxis_Hz = ...
    (0:NRangeBins-1) * ...
    Radar.SampleRate / NFastTime;

RangeAxis_m = ...
    RangeFrequencyAxis_Hz / RangeBinScale_Hz_per_m;

DopplerAxis_Hz = ...
    (-NPulses/2:NPulses/2-1) * ...
    Radar.PRF / NPulses;

VelocityAxis_mps = ...
    DopplerAxis_Hz * Radar.Wavelength / 2;

%% ============================================
% 5. CHECK CA-CFAR FUNCTION
% ============================================

if exist('CA_CFAR_2D','file') ~= 2

    error(['CA_CFAR_2D.m was not found. ', ...
           'Place it in the current MATLAB folder or path.']);

end

%% ============================================
% 6. PREALLOCATE PERFORMANCE ARRAYS
% ============================================

DetectionProbabilityPerRun = zeros(NumberOfMonteCarloRuns,1);

FalseAlarmsPerRun = zeros(NumberOfMonteCarloRuns,1);

DetectedTargetsPerRun = zeros(NumberOfMonteCarloRuns,1);

TotalPeaksPerRun = zeros(NumberOfMonteCarloRuns,1);

RangeRMSEPerRun_m = nan(NumberOfMonteCarloRuns,1);

VelocityRMSEPerRun_mps = nan(NumberOfMonteCarloRuns,1);

RangeMeanErrorPerRun_m = nan(NumberOfMonteCarloRuns,1);

VelocityMeanErrorPerRun_mps = nan(NumberOfMonteCarloRuns,1);

MaximumRangeErrorPerRun_m = nan(NumberOfMonteCarloRuns,1);

MaximumVelocityErrorPerRun_mps = nan(NumberOfMonteCarloRuns,1);

%% ============================================
% 7. MONTE CARLO LOOP
% ============================================

fprintf('\n============================================\n');
fprintf('MONTE CARLO RADAR PERFORMANCE TEST\n');
fprintf('============================================\n');

fprintf('Monte Carlo runs : %d\n', NumberOfMonteCarloRuns);
fprintf('Noise sigma      : %.3f\n', NoiseSigma);
fprintf('Training cells   : %d\n', TrainingCells);
fprintf('Guard cells      : %d\n', GuardCells);
fprintf('CFAR threshold   : %.2f\n', ThresholdFactor);
fprintf('============================================\n');

for RunIndex = 1:NumberOfMonteCarloRuns

    %% ----------------------------------------
    % 7.1 Generate complex noise
    % -----------------------------------------

    ReceivedData = ...
        NoiseSigma/sqrt(2) * ...
        (randn(NFastTime,NPulses) + ...
         1i*randn(NFastTime,NPulses));

    %% ----------------------------------------
    % 7.2 Inject five targets
    % -----------------------------------------

    for k = 1:NumberOfTargets

        TargetRange = TargetRanges_m(k);

        TargetVelocity = TargetVelocities_mps(k);

        TargetAmplitude = TargetAmplitudes(k);

        % Simplified FMCW-like range beat frequency
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

    %% ----------------------------------------
    % 7.3 Windowing
    % -----------------------------------------

    % Hann window without requiring hann()
    RangeWindow = ...
        0.5 - 0.5*cos( ...
        2*pi*(0:NFastTime-1)'/(NFastTime-1));

    DopplerWindow = ...
        0.5 - 0.5*cos( ...
        2*pi*(0:NPulses-1)/(NPulses-1));

    WindowedData = ...
        ReceivedData .* RangeWindow;

    WindowedData = ...
        WindowedData .* DopplerWindow;

    %% ----------------------------------------
    % 7.4 Range FFT
    % -----------------------------------------

    RangeFFT = ...
        fft(WindowedData, NFastTime, 1);

    RangeFFT = ...
        RangeFFT(1:NRangeBins,:);

    %% ----------------------------------------
    % 7.5 Doppler FFT
    % -----------------------------------------

    RangeDopplerComplex = ...
        fftshift( ...
        fft(RangeFFT, NPulses, 2), ...
        2);

    %% ----------------------------------------
    % 7.6 Power map
    % -----------------------------------------

    RangeDopplerPower = ...
        abs(RangeDopplerComplex).^2;

    %% ----------------------------------------
    % 7.7 CA-CFAR
    % -----------------------------------------

    DetectionMap = CA_CFAR_2D( ...
        RangeDopplerPower, ...
        TrainingCells, ...
        GuardCells, ...
        ThresholdFactor);

    %% ----------------------------------------
    % 7.8 Local peak extraction
    % -----------------------------------------

    DetectionMapPeak = ...
        false(size(DetectionMap));

    for r = 2:size(DetectionMap,1)-1

        for d = 2:size(DetectionMap,2)-1

            if DetectionMap(r,d)

                LocalWindow = ...
                    RangeDopplerPower( ...
                    r-1:r+1, d-1:d+1);

                CenterPower = ...
                    RangeDopplerPower(r,d);

                if CenterPower == max(LocalWindow(:))

                    DetectionMapPeak(r,d) = true;

                end

            end

        end

    end

    %% ----------------------------------------
    % 7.9 Extract detections
    % -----------------------------------------

    [PeakRangeBins, PeakDopplerBins] = ...
        find(DetectionMapPeak);

    DetectedRanges_m = ...
        RangeAxis_m(PeakRangeBins);

    DetectedDopplers_Hz = ...
        DopplerAxis_Hz(PeakDopplerBins);

    DetectedVelocities_mps = ...
        DetectedDopplers_Hz * Radar.Wavelength / 2;

    NumberOfDetectedPeaks = ...
        numel(PeakRangeBins);

    %% ----------------------------------------
    % 7.10 Match detected targets
    % -----------------------------------------

    TargetsDetected = ...
        false(NumberOfTargets,1);

    MatchedRangeErrors_m = ...
        nan(NumberOfTargets,1);

    MatchedVelocityErrors_mps = ...
        nan(NumberOfTargets,1);

    for k = 1:NumberOfTargets

        if isempty(DetectedRanges_m)

            continue;

        end

        RangeError = ...
            abs(DetectedRanges_m - TargetRanges_m(k));

        VelocityError = ...
            abs(DetectedVelocities_mps - ...
                TargetVelocities_mps(k));

        Match = ...
            RangeError <= RangeTolerance_m & ...
            VelocityError <= VelocityTolerance_mps;

        if any(Match)

            TargetsDetected(k) = true;

            CandidateIndices = find(Match);

            CandidateDistance = ...
                RangeError(CandidateIndices) + ...
                VelocityError(CandidateIndices);

            [~, BestIndex] = ...
                min(CandidateDistance);

            BestDetectionIndex = ...
                CandidateIndices(BestIndex);

            MatchedRangeErrors_m(k) = ...
                DetectedRanges_m(BestDetectionIndex) - ...
                TargetRanges_m(k);

            MatchedVelocityErrors_mps(k) = ...
                DetectedVelocities_mps(BestDetectionIndex) - ...
                TargetVelocities_mps(k);

        end

    end

    %% ----------------------------------------
    % 7.11 Calculate run statistics
    % -----------------------------------------

    NumberOfDetectedTargets = ...
        sum(TargetsDetected);

    NumberOfFalseAlarms = ...
        NumberOfDetectedPeaks - ...
        NumberOfDetectedTargets;

    if NumberOfFalseAlarms < 0

        NumberOfFalseAlarms = 0;

    end

    DetectionProbabilityPerRun(RunIndex) = ...
        NumberOfDetectedTargets / NumberOfTargets;

    FalseAlarmsPerRun(RunIndex) = ...
        NumberOfFalseAlarms;

    DetectedTargetsPerRun(RunIndex) = ...
        NumberOfDetectedTargets;

    TotalPeaksPerRun(RunIndex) = ...
        NumberOfDetectedPeaks;

    ValidRangeErrors = ...
        MatchedRangeErrors_m(~isnan(MatchedRangeErrors_m));

    ValidVelocityErrors = ...
        MatchedVelocityErrors_mps( ...
        ~isnan(MatchedVelocityErrors_mps));

    if ~isempty(ValidRangeErrors)

        RangeRMSEPerRun_m(RunIndex) = ...
            sqrt(mean(ValidRangeErrors.^2));

        RangeMeanErrorPerRun_m(RunIndex) = ...
            mean(ValidRangeErrors);

        MaximumRangeErrorPerRun_m(RunIndex) = ...
            max(abs(ValidRangeErrors));

    end

    if ~isempty(ValidVelocityErrors)

        VelocityRMSEPerRun_mps(RunIndex) = ...
            sqrt(mean(ValidVelocityErrors.^2));

        VelocityMeanErrorPerRun_mps(RunIndex) = ...
            mean(ValidVelocityErrors);

        MaximumVelocityErrorPerRun_mps(RunIndex) = ...
            max(abs(ValidVelocityErrors));

    end

    %% ----------------------------------------
    % 7.12 Progress display
    % -----------------------------------------

    if mod(RunIndex,10) == 0 || ...
            RunIndex == 1 || ...
            RunIndex == NumberOfMonteCarloRuns

        fprintf( ...
            'Run %3d/%3d | Detection = %6.2f %% | Peaks = %d\n', ...
            RunIndex, ...
            NumberOfMonteCarloRuns, ...
            100*DetectionProbabilityPerRun(RunIndex), ...
            NumberOfDetectedPeaks);

    end

end

%% ============================================
% 8. FINAL PERFORMANCE STATISTICS
% ============================================

OverallDetectionProbability = ...
    mean(DetectionProbabilityPerRun);

AverageFalseAlarms = ...
    mean(FalseAlarmsPerRun);

AverageDetectedTargets = ...
    mean(DetectedTargetsPerRun);

AverageTotalPeaks = ...
    mean(TotalPeaksPerRun);

%% ============================================
% 8. FINAL PERFORMANCE STATISTICS
% ============================================

% Valid range RMSE values
ValidRangeRMSE = ...
    RangeRMSEPerRun_m(~isnan(RangeRMSEPerRun_m));

% Valid velocity RMSE values
ValidVelocityRMSE = ...
    VelocityRMSEPerRun_mps(~isnan(VelocityRMSEPerRun_mps));

% Valid range mean errors
ValidRangeMeanErrors = ...
    RangeMeanErrorPerRun_m(~isnan(RangeMeanErrorPerRun_m));

% Valid velocity mean errors
ValidVelocityMeanErrors = ...
    VelocityMeanErrorPerRun_mps( ...
    ~isnan(VelocityMeanErrorPerRun_mps));

% Valid maximum range errors
ValidMaximumRangeErrors = ...
    MaximumRangeErrorPerRun_m(~isnan(MaximumRangeErrorPerRun_m));

% Valid maximum velocity errors
ValidMaximumVelocityErrors = ...
    MaximumVelocityErrorPerRun_mps( ...
    ~isnan(MaximumVelocityErrorPerRun_mps));


%% Overall detection statistics

OverallDetectionProbability = ...
    mean(DetectionProbabilityPerRun);

AverageFalseAlarms = ...
    mean(FalseAlarmsPerRun);

AverageDetectedTargets = ...
    mean(DetectedTargetsPerRun);

AverageTotalPeaks = ...
    mean(TotalPeaksPerRun);


%% Overall range statistics

if isempty(ValidRangeRMSE)

    OverallRangeRMSE_m = NaN;

else

    OverallRangeRMSE_m = ...
        sqrt(mean(ValidRangeRMSE.^2));

end


if isempty(ValidRangeMeanErrors)

    OverallRangeMeanError_m = NaN;

else

    OverallRangeMeanError_m = ...
        mean(ValidRangeMeanErrors);

end


if isempty(ValidMaximumRangeErrors)

    OverallMaximumRangeError_m = NaN;

else

    OverallMaximumRangeError_m = ...
        max(ValidMaximumRangeErrors);

end


%% Overall velocity statistics

if isempty(ValidVelocityRMSE)

    OverallVelocityRMSE_mps = NaN;

else

    OverallVelocityRMSE_mps = ...
        sqrt(mean(ValidVelocityRMSE.^2));

end


if isempty(ValidVelocityMeanErrors)

    OverallVelocityMeanError_mps = NaN;

else

    OverallVelocityMeanError_mps = ...
        mean(ValidVelocityMeanErrors);

end


if isempty(ValidMaximumVelocityErrors)

    OverallMaximumVelocityError_mps = NaN;

else

    OverallMaximumVelocityError_mps = ...
        max(ValidMaximumVelocityErrors);

end
%% ============================================
% 9. PERFORMANCE SUMMARY
% ============================================

fprintf('\n============================================\n');
fprintf('MONTE CARLO PERFORMANCE SUMMARY\n');
fprintf('============================================\n');

fprintf('Monte Carlo runs       : %d\n', ...
    NumberOfMonteCarloRuns);

fprintf('Injected targets       : %d per run\n', ...
    NumberOfTargets);

fprintf('Average detected       : %.3f targets/run\n', ...
    AverageDetectedTargets);

fprintf('Average total peaks    : %.3f peaks/run\n', ...
    AverageTotalPeaks);

fprintf('Detection probability  : %.2f %%\n', ...
    100*OverallDetectionProbability);

fprintf('Average false alarms   : %.3f/run\n', ...
    AverageFalseAlarms);

fprintf('Range RMSE             : %.4f m\n', ...
    OverallRangeRMSE_m);

fprintf('Range mean error       : %.4f m\n', ...
    OverallRangeMeanError_m);

fprintf('Maximum range error    : %.4f m\n', ...
    OverallMaximumRangeError_m);

fprintf('Velocity RMSE          : %.4f m/s\n', ...
    OverallVelocityRMSE_mps);

fprintf('Velocity mean error    : %.4f m/s\n', ...
    OverallVelocityMeanError_mps);

fprintf('Maximum velocity error : %.4f m/s\n', ...
    OverallMaximumVelocityError_mps);

fprintf('============================================\n');

if OverallDetectionProbability >= 0.95 && ...
        AverageFalseAlarms <= 0.5

    fprintf('MONTE CARLO RADAR TEST: PASS\n');

else

    fprintf('MONTE CARLO RADAR TEST: REVIEW REQUIRED\n');

end

fprintf('============================================\n');

%% ============================================
% 10. CREATE PERFORMANCE TABLE
% ============================================

MonteCarloPerformanceTable = table( ...
    (1:NumberOfMonteCarloRuns)', ...
    DetectionProbabilityPerRun, ...
    DetectedTargetsPerRun, ...
    TotalPeaksPerRun, ...
    FalseAlarmsPerRun, ...
    RangeRMSEPerRun_m, ...
    RangeMeanErrorPerRun_m, ...
    MaximumRangeErrorPerRun_m, ...
    VelocityRMSEPerRun_mps, ...
    VelocityMeanErrorPerRun_mps, ...
    MaximumVelocityErrorPerRun_mps, ...
    'VariableNames', ...
    {'Run', ...
     'DetectionProbability', ...
     'DetectedTargets', ...
     'TotalPeaks', ...
     'FalseAlarms', ...
     'RangeRMSE_m', ...
     'RangeMeanError_m', ...
     'MaximumRangeError_m', ...
     'VelocityRMSE_mps', ...
     'VelocityMeanError_mps', ...
     'MaximumVelocityError_mps'});

%% ============================================
% 11. PLOT DETECTION PROBABILITY
% ============================================

figure;

plot( ...
    1:NumberOfMonteCarloRuns, ...
    100*DetectionProbabilityPerRun, ...
    'b-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

grid on;

xlabel('Monte Carlo run');

ylabel('Detection probability (%)');

title('Monte Carlo Detection Probability');

ylim([0 105]);

%% ============================================
% 12. PLOT FALSE ALARMS
% ============================================

figure;

plot( ...
    1:NumberOfMonteCarloRuns, ...
    FalseAlarmsPerRun, ...
    'r-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

grid on;

xlabel('Monte Carlo run');

ylabel('False alarms');

title('Monte Carlo False Alarms');

%% ============================================
% 13. PLOT RANGE RMSE
% ============================================

figure;

plot( ...
    1:NumberOfMonteCarloRuns, ...
    RangeRMSEPerRun_m, ...
    'k-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

grid on;

xlabel('Monte Carlo run');

ylabel('Range RMSE (m)');

title('Monte Carlo Range RMSE');

%% ============================================
% 14. PLOT VELOCITY RMSE
% ============================================

figure;

plot( ...
    1:NumberOfMonteCarloRuns, ...
    VelocityRMSEPerRun_mps, ...
    'm-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

grid on;

xlabel('Monte Carlo run');

ylabel('Velocity RMSE (m/s)');

title('Monte Carlo Velocity RMSE');

%% ============================================
% 15. SAVE MONTE CARLO RESULTS
% ============================================

ResultsFolder = 'SARRS_Results';

if ~exist(ResultsFolder,'dir')

    mkdir(ResultsFolder);

end

Timestamp = datestr(now,'yyyymmdd_HHMMSS');

MonteCarloMATFileName = fullfile( ...
    ResultsFolder, ...
    ['MonteCarlo_FiveTarget_' Timestamp '.mat']);

save( ...
    MonteCarloMATFileName, ...
    'Radar', ...
    'NFastTime', ...
    'NPulses', ...
    'NumberOfMonteCarloRuns', ...
    'NoiseSigma', ...
    'TrainingCells', ...
    'GuardCells', ...
    'ThresholdFactor', ...
    'TargetRanges_m', ...
    'TargetVelocities_mps', ...
    'TargetAmplitudes', ...
    'DetectionProbabilityPerRun', ...
    'FalseAlarmsPerRun', ...
    'DetectedTargetsPerRun', ...
    'TotalPeaksPerRun', ...
    'RangeRMSEPerRun_m', ...
    'RangeMeanErrorPerRun_m', ...
    'MaximumRangeErrorPerRun_m', ...
    'VelocityRMSEPerRun_mps', ...
    'VelocityMeanErrorPerRun_mps', ...
    'MaximumVelocityErrorPerRun_mps', ...
    'OverallDetectionProbability', ...
    'AverageFalseAlarms', ...
    'AverageDetectedTargets', ...
    'AverageTotalPeaks', ...
    'OverallRangeRMSE_m', ...
    'OverallRangeMeanError_m', ...
    'OverallMaximumRangeError_m', ...
    'OverallVelocityRMSE_mps', ...
    'OverallVelocityMeanError_mps', ...
    'OverallMaximumVelocityError_mps', ...
    'MonteCarloPerformanceTable');

%% ============================================
% 16. SAVE CSV REPORT
% ============================================

MonteCarloCSVFileName = fullfile( ...
    ResultsFolder, ...
    ['MonteCarlo_PerformanceTable_' Timestamp '.csv']);

writetable( ...
    MonteCarloPerformanceTable, ...
    MonteCarloCSVFileName);

%% ============================================
% 17. EXPORT TO MATLAB WORKSPACE
% ============================================

assignin('base', ...
    'MonteCarloPerformanceTable', ...
    MonteCarloPerformanceTable);

assignin('base', ...
    'OverallDetectionProbability', ...
    OverallDetectionProbability);

assignin('base', ...
    'AverageFalseAlarms', ...
    AverageFalseAlarms);

assignin('base', ...
    'OverallRangeRMSE_m', ...
    OverallRangeRMSE_m);

assignin('base', ...
    'OverallVelocityRMSE_mps', ...
    OverallVelocityRMSE_mps);

fprintf('\n============================================\n');
fprintf('MONTE CARLO RESULTS SAVED\n');
fprintf('============================================\n');

fprintf('MAT file:\n%s\n', ...
    MonteCarloMATFileName);

fprintf('\nCSV file:\n%s\n', ...
    MonteCarloCSVFileName);

fprintf('============================================\n');