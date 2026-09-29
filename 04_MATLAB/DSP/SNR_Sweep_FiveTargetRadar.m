%% ============================================================
% SNR_Sweep_FiveTargetRadar.m
%
% SARRS STUDIO
% Five-target radar SNR-sweep Monte Carlo performance evaluation
%
% This script performs:
%   1. Five-target radar echo generation
%   2. Range FFT
%   3. Doppler FFT
%   4. 2D CA-CFAR detection
%   5. Local peak extraction
%   6. Target validation
%   7. SNR sweep Monte Carlo analysis
%   8. Detection probability calculation
%   9. False alarm calculation
%  10. Range RMSE calculation
%  11. Velocity RMSE calculation
%  12. MAT and CSV export
%
% No external CA_CFAR_2D.m file is required.
%
% MATLAB R2016b or newer is recommended because this script
% contains a local function at the bottom.
%% ============================================================

clc;
clear;
close all;

rng(1);

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - SNR SWEEP MONTE CARLO RADAR TEST\n');
fprintf('============================================================\n');

%% ============================================================
% 1. Radar configuration
%% ============================================================

Radar = struct;

Radar.PRF        = 800;       % Pulse repetition frequency, Hz
Radar.SampleRate = 10e6;      % Fast-time sampling rate, Hz
Radar.Wavelength = 0.03;      % Radar wavelength, m
Radar.c          = 3e8;       % Speed of light, m/s

%% ============================================================
% 2. Simulation parameters
%% ============================================================

NFastTime = 256;
NPulses   = 128;

% SNR sweep
SNRValues_dB = -10:2:20;

% Monte Carlo runs per SNR
NumberOfMonteCarloRuns = 100;

% Target-independent display parameters
TrainingCells   = 8;
GuardCells      = 2;
ThresholdFactor = 14;

% Local peak detection
UseLocalPeakExtraction = true;

% Validation tolerances
RangeTolerance_m    = 5;
VelocityTolerance_mps = 0.15;

%% ============================================================
% 3. Five target definitions
%% ============================================================

TargetRanges_m = [75 150 225 300 375];

TargetVelocities_mps = [-5 -3 -1 2 4];

TargetAmplitudes = [1.00 0.95 0.90 0.85 0.80];

NumberOfTargets = numel(TargetRanges_m);

%% ============================================================
% 4. Axes and range model
%% ============================================================

FastTime = (0:NFastTime-1) / Radar.SampleRate;

SlowTime = (0:NPulses-1) / Radar.PRF;

% Simplified FMCW-like range beat-frequency scale.
% This is a simulation parameter and not a complete hardware
% waveform model.
RangeBinScale_Hz_per_m = Radar.SampleRate / ...
    (2 * max(TargetRanges_m) * 1.25);

NRangeBins = floor(NFastTime/2);

RangeFrequencyAxis_Hz = ...
    (0:NRangeBins-1) * Radar.SampleRate / NFastTime;

RangeAxis_m = ...
    RangeFrequencyAxis_Hz / RangeBinScale_Hz_per_m;

DopplerAxis_Hz = ...
    (-NPulses/2:NPulses/2-1) * Radar.PRF / NPulses;

VelocityAxis_mps = ...
    DopplerAxis_Hz * Radar.Wavelength / 2;

%% ============================================================
% 5. Allocate Monte Carlo result arrays
%% ============================================================

NumberOfSNRPoints = numel(SNRValues_dB);

DetectionProbabilityPercent = zeros(1, NumberOfSNRPoints);

AverageDetectedTargets = zeros(1, NumberOfSNRPoints);

AverageTotalPeaks = zeros(1, NumberOfSNRPoints);

AverageFalseAlarms = zeros(1, NumberOfSNRPoints);

RangeRMSE_Sweep_m = zeros(1, NumberOfSNRPoints);

RangeMeanError_Sweep_m = zeros(1, NumberOfSNRPoints);

RangeMaximumError_Sweep_m = zeros(1, NumberOfSNRPoints);

VelocityRMSE_Sweep_mps = zeros(1, NumberOfSNRPoints);

VelocityMeanError_Sweep_mps = zeros(1, NumberOfSNRPoints);

VelocityMaximumError_Sweep_mps = zeros(1, NumberOfSNRPoints);

% Store all run-level results
DetectionProbabilityPerRun = zeros( ...
    NumberOfSNRPoints, NumberOfMonteCarloRuns);

DetectedTargetsPerRun = zeros( ...
    NumberOfSNRPoints, NumberOfMonteCarloRuns);

TotalPeaksPerRun = zeros( ...
    NumberOfSNRPoints, NumberOfMonteCarloRuns);

FalseAlarmsPerRun = zeros( ...
    NumberOfSNRPoints, NumberOfMonteCarloRuns);

RangeRMSEPerRun_m = nan( ...
    NumberOfSNRPoints, NumberOfMonteCarloRuns);

VelocityRMSEPerRun_mps = nan( ...
    NumberOfSNRPoints, NumberOfMonteCarloRuns);

%% ============================================================
% 6. Display configuration
%% ============================================================

fprintf('SNR range              : %d to %d dB\n', ...
    min(SNRValues_dB), max(SNRValues_dB));

fprintf('SNR step               : %d dB\n', ...
    SNRValues_dB(2) - SNRValues_dB(1));

fprintf('Monte Carlo runs/SNR   : %d\n', ...
    NumberOfMonteCarloRuns);

fprintf('Targets per run        : %d\n', ...
    NumberOfTargets);

fprintf('Fast-time samples      : %d\n', ...
    NFastTime);

fprintf('Number of pulses       : %d\n', ...
    NPulses);

fprintf('Training cells         : %d\n', ...
    TrainingCells);

fprintf('Guard cells            : %d\n', ...
    GuardCells);

fprintf('CFAR threshold factor  : %.2f\n', ...
    ThresholdFactor);

fprintf('============================================================\n\n');

%% ============================================================
% 7. Main SNR sweep
%% ============================================================

for snrIndex = 1:NumberOfSNRPoints

    CurrentSNR_dB = SNRValues_dB(snrIndex);

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('SNR = %d dB\n', CurrentSNR_dB);
    fprintf('------------------------------------------------------------\n');

    % Run-level arrays for this SNR
    LocalDetectionProbability = zeros(1, NumberOfMonteCarloRuns);

    LocalDetectedTargets = zeros(1, NumberOfMonteCarloRuns);

    LocalTotalPeaks = zeros(1, NumberOfMonteCarloRuns);

    LocalFalseAlarms = zeros(1, NumberOfMonteCarloRuns);

    LocalRangeRMSE_m = nan(1, NumberOfMonteCarloRuns);

    LocalVelocityRMSE_mps = nan(1, NumberOfMonteCarloRuns);

    LocalRangeMeanError_m = nan(1, NumberOfMonteCarloRuns);

    LocalVelocityMeanError_mps = nan(1, NumberOfMonteCarloRuns);

    LocalRangeMaximumError_m = nan(1, NumberOfMonteCarloRuns);

    LocalVelocityMaximumError_mps = nan(1, NumberOfMonteCarloRuns);

    for runIndex = 1:NumberOfMonteCarloRuns

        %% ----------------------------------------------------
        % 7.1 Generate clean received data
        %% -----------------------------------------------------

        CleanReceivedData = zeros(NFastTime, NPulses);

        for targetIndex = 1:NumberOfTargets

            TargetRange = TargetRanges_m(targetIndex);

            TargetVelocity = ...
                TargetVelocities_mps(targetIndex);

            TargetAmplitude = ...
                TargetAmplitudes(targetIndex);

            % Simplified range beat frequency
            RangeFrequency_Hz = ...
                TargetRange * RangeBinScale_Hz_per_m;

            % Doppler frequency
            DopplerFrequency_Hz = ...
                2 * TargetVelocity / Radar.Wavelength;

            % Fast-time phase
            RangePhase = ...
                2*pi*RangeFrequency_Hz*FastTime(:);

            % Slow-time phase
            DopplerPhase = ...
                2*pi*DopplerFrequency_Hz*SlowTime;

            % Separable target response
            TargetSignal = TargetAmplitude * ...
                exp(1i*RangePhase) * ...
                exp(1i*DopplerPhase);

            CleanReceivedData = ...
                CleanReceivedData + TargetSignal;

        end

        %% ----------------------------------------------------
        % 7.2 Add noise according to the required SNR
        %% -----------------------------------------------------

        SignalPower = mean(abs(CleanReceivedData(:)).^2);

        DesiredSNR_Linear = 10^(CurrentSNR_dB/10);

        NoisePower = SignalPower / DesiredSNR_Linear;

        NoiseSigma = sqrt(NoisePower);

        ComplexNoise = NoiseSigma/sqrt(2) * ...
            (randn(NFastTime,NPulses) + ...
             1i*randn(NFastTime,NPulses));

        ReceivedData = CleanReceivedData + ComplexNoise;

        %% ----------------------------------------------------
        % 7.3 Apply range and Doppler windows
        %% -----------------------------------------------------

        RangeWindow = hann(NFastTime);

        DopplerWindow = hann(NPulses).';

        WindowedData = ReceivedData .* RangeWindow;

        WindowedData = WindowedData .* DopplerWindow;

        %% ----------------------------------------------------
        % 7.4 Range FFT
        %% -----------------------------------------------------

        RangeFFTFull = fft( ...
            WindowedData, ...
            NFastTime, ...
            1);

        RangeFFT = ...
            RangeFFTFull(1:NRangeBins, :);

        %% ----------------------------------------------------
        % 7.5 Doppler FFT
        %% -----------------------------------------------------

        RangeDopplerComplex = fftshift( ...
            fft(RangeFFT, NPulses, 2), ...
            2);

        %% ----------------------------------------------------
        % 7.6 Power map
        %% -----------------------------------------------------

        RangeDopplerPower = ...
            abs(RangeDopplerComplex).^2;

        %% ----------------------------------------------------
        % 7.7 CA-CFAR detection
        %% -----------------------------------------------------

        DetectionMap = CA_CFAR_2D_Local( ...
            RangeDopplerPower, ...
            TrainingCells, ...
            GuardCells, ...
            ThresholdFactor);

        %% ----------------------------------------------------
        % 7.8 Local peak extraction
        %% -----------------------------------------------------

        if UseLocalPeakExtraction

            DetectionMapPeak = ...
                false(size(DetectionMap));

            for r = 2:size(DetectionMap,1)-1

                for d = 2:size(DetectionMap,2)-1

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

        else

            DetectionMapPeak = DetectionMap;

        end

        %% ----------------------------------------------------
        % 7.9 Extract detected peaks
        %% -----------------------------------------------------

        [PeakRangeBins, PeakDopplerBins] = ...
            find(DetectionMapPeak);

        DetectedRanges_m = ...
            RangeAxis_m(PeakRangeBins);

        DetectedDopplers_Hz = ...
            DopplerAxis_Hz(PeakDopplerBins);

        DetectedVelocities_mps = ...
            DetectedDopplers_Hz * Radar.Wavelength / 2;

        NumberOfPeaks = numel(PeakRangeBins);

        %% ----------------------------------------------------
        % 7.10 Match detections to known targets
        %% -----------------------------------------------------

        TargetsDetected = ...
            false(1, NumberOfTargets);

        MatchedRangeErrors_m = nan(1, NumberOfTargets);

        MatchedVelocityErrors_mps = ...
            nan(1, NumberOfTargets);

        % Prevent one detection from being assigned to
        % multiple targets.
        DetectionAlreadyUsed = ...
            false(1, NumberOfPeaks);

        for targetIndex = 1:NumberOfTargets

            if NumberOfPeaks == 0
                continue;
            end

            RangeError = abs( ...
                DetectedRanges_m - ...
                TargetRanges_m(targetIndex));

            VelocityError = abs( ...
                DetectedVelocities_mps - ...
                TargetVelocities_mps(targetIndex));

            ValidMatches = ...
                RangeError <= RangeTolerance_m & ...
                VelocityError <= VelocityTolerance_mps & ...
                ~DetectionAlreadyUsed;

            CandidateIndices = find(ValidMatches);

            if ~isempty(CandidateIndices)

                % Select the closest combined range/velocity match
                MatchScore = ...
                    RangeError(CandidateIndices) / RangeTolerance_m + ...
                    VelocityError(CandidateIndices) / ...
                    VelocityTolerance_mps;

                [~, BestLocalIndex] = min(MatchScore);

                BestDetectionIndex = ...
                    CandidateIndices(BestLocalIndex);

                TargetsDetected(targetIndex) = true;

                DetectionAlreadyUsed(BestDetectionIndex) = true;

                MatchedRangeErrors_m(targetIndex) = ...
                    DetectedRanges_m(BestDetectionIndex) - ...
                    TargetRanges_m(targetIndex);

                MatchedVelocityErrors_mps(targetIndex) = ...
                    DetectedVelocities_mps(BestDetectionIndex) - ...
                    TargetVelocities_mps(targetIndex);

            end

        end

        %% ----------------------------------------------------
        % 7.11 Calculate run-level performance
        %% -----------------------------------------------------

        NumberOfDetectedTargets = ...
            sum(TargetsDetected);

        NumberOfFalseAlarms = ...
            NumberOfPeaks - NumberOfDetectedTargets;

        DetectionProbability = ...
            NumberOfDetectedTargets / NumberOfTargets;

        LocalDetectionProbability(runIndex) = ...
            DetectionProbability * 100;

        LocalDetectedTargets(runIndex) = ...
            NumberOfDetectedTargets;

        LocalTotalPeaks(runIndex) = ...
            NumberOfPeaks;

        LocalFalseAlarms(runIndex) = ...
            NumberOfFalseAlarms;

        if NumberOfDetectedTargets > 0

            ValidRangeErrors = ...
                MatchedRangeErrors_m(~isnan(MatchedRangeErrors_m));

            ValidVelocityErrors = ...
                MatchedVelocityErrors_mps( ...
                ~isnan(MatchedVelocityErrors_mps));

            if ~isempty(ValidRangeErrors)

                LocalRangeRMSE_m(runIndex) = ...
                    sqrt(mean(ValidRangeErrors.^2));

                LocalRangeMeanError_m(runIndex) = ...
                    mean(ValidRangeErrors);

                LocalRangeMaximumError_m(runIndex) = ...
                    max(abs(ValidRangeErrors));

            end

            if ~isempty(ValidVelocityErrors)

                LocalVelocityRMSE_mps(runIndex) = ...
                    sqrt(mean(ValidVelocityErrors.^2));

                LocalVelocityMeanError_mps(runIndex) = ...
                    mean(ValidVelocityErrors);

                LocalVelocityMaximumError_mps(runIndex) = ...
                    max(abs(ValidVelocityErrors));

            end

        end

    end

    %% ========================================================
    % 7.12 Store results for this SNR
    %% ========================================================

    DetectionProbabilityPerRun(snrIndex,:) = ...
        LocalDetectionProbability;

    DetectedTargetsPerRun(snrIndex,:) = ...
        LocalDetectedTargets;

    TotalPeaksPerRun(snrIndex,:) = ...
        LocalTotalPeaks;

    FalseAlarmsPerRun(snrIndex,:) = ...
        LocalFalseAlarms;

    RangeRMSEPerRun_m(snrIndex,:) = ...
        LocalRangeRMSE_m;

    VelocityRMSEPerRun_mps(snrIndex,:) = ...
        LocalVelocityRMSE_mps;

    DetectionProbabilityPercent(snrIndex) = ...
        mean(LocalDetectionProbability);

    AverageDetectedTargets(snrIndex) = ...
        mean(LocalDetectedTargets);

    AverageTotalPeaks(snrIndex) = ...
        mean(LocalTotalPeaks);

    AverageFalseAlarms(snrIndex) = ...
        mean(LocalFalseAlarms);

    %% --------------------------------------------------------
    % Use only valid RMSE values.
    % This avoids nanmean compatibility errors.
    %% --------------------------------------------------------

    ValidRangeRMSE = ...
        LocalRangeRMSE_m(~isnan(LocalRangeRMSE_m));

    ValidVelocityRMSE = ...
        LocalVelocityRMSE_mps(~isnan(LocalVelocityRMSE_mps));

    ValidRangeMeanErrors = ...
        LocalRangeMeanError_m(~isnan(LocalRangeMeanError_m));

    ValidVelocityMeanErrors = ...
        LocalVelocityMeanError_mps( ...
        ~isnan(LocalVelocityMeanError_mps));

    ValidRangeMaximumErrors = ...
        LocalRangeMaximumError_m( ...
        ~isnan(LocalRangeMaximumError_m));

    ValidVelocityMaximumErrors = ...
        LocalVelocityMaximumError_mps( ...
        ~isnan(LocalVelocityMaximumError_mps));

    if isempty(ValidRangeRMSE)

        RangeRMSE_Sweep_m(snrIndex) = NaN;

    else

        RangeRMSE_Sweep_m(snrIndex) = ...
            sqrt(mean(ValidRangeRMSE.^2));

    end

    if isempty(ValidVelocityRMSE)

        VelocityRMSE_Sweep_mps(snrIndex) = NaN;

    else

        VelocityRMSE_Sweep_mps(snrIndex) = ...
            sqrt(mean(ValidVelocityRMSE.^2));

    end

    if isempty(ValidRangeMeanErrors)

        RangeMeanError_Sweep_m(snrIndex) = NaN;

    else

        RangeMeanError_Sweep_m(snrIndex) = ...
            mean(ValidRangeMeanErrors);

    end

    if isempty(ValidVelocityMeanErrors)

        VelocityMeanError_Sweep_mps(snrIndex) = NaN;

    else

        VelocityMeanError_Sweep_mps(snrIndex) = ...
            mean(ValidVelocityMeanErrors);

    end

    if isempty(ValidRangeMaximumErrors)

        RangeMaximumError_Sweep_m(snrIndex) = NaN;

    else

        RangeMaximumError_Sweep_m(snrIndex) = ...
            max(ValidRangeMaximumErrors);

    end

    if isempty(ValidVelocityMaximumErrors)

        VelocityMaximumError_Sweep_mps(snrIndex) = NaN;

    else

        VelocityMaximumError_Sweep_mps(snrIndex) = ...
            max(ValidVelocityMaximumErrors);

    end

    %% --------------------------------------------------------
    % 7.13 Display progress
    %% --------------------------------------------------------

    fprintf( ...
        'SNR = %4d dB | Detection = %6.2f %% | ', ...
        CurrentSNR_dB, ...
        DetectionProbabilityPercent(snrIndex));

    fprintf( ...
        'Avg peaks = %.2f | False alarms = %.2f\n', ...
        AverageTotalPeaks(snrIndex), ...
        AverageFalseAlarms(snrIndex));

end

%% ============================================================
% 8. Display final SNR sweep summary
%% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SNR SWEEP MONTE CARLO PERFORMANCE SUMMARY\n');
fprintf('============================================================\n');

fprintf( ...
    '%10s %18s %18s %18s %18s\n', ...
    'SNR(dB)', ...
    'Detection(%)', ...
    'Avg Peaks', ...
    'False Alarms', ...
    'Range RMSE(m)');

fprintf('------------------------------------------------------------\n');

for snrIndex = 1:NumberOfSNRPoints

    fprintf( ...
        '%10.0f %18.2f %18.3f %18.3f %18.4f\n', ...
        SNRValues_dB(snrIndex), ...
        DetectionProbabilityPercent(snrIndex), ...
        AverageTotalPeaks(snrIndex), ...
        AverageFalseAlarms(snrIndex), ...
        RangeRMSE_Sweep_m(snrIndex));

end

fprintf('============================================================\n');

%% ============================================================
% 9. Final performance values
%% ============================================================

[~, BestDetectionIndex] = ...
    max(DetectionProbabilityPercent);

BestDetectionSNR_dB = ...
    SNRValues_dB(BestDetectionIndex);

DetectionAt0dB = NaN;

ZeroSNRIndex = find(SNRValues_dB == 0, 1);

if ~isempty(ZeroSNRIndex)

    DetectionAt0dB = ...
        DetectionProbabilityPercent(ZeroSNRIndex);

end

fprintf('\n');
fprintf('============================================================\n');
fprintf('KEY PERFORMANCE RESULTS\n');
fprintf('============================================================\n');

fprintf( ...
    'Best detection probability : %.2f %% at %d dB\n', ...
    DetectionProbabilityPercent(BestDetectionIndex), ...
    BestDetectionSNR_dB);

if ~isnan(DetectionAt0dB)

    fprintf( ...
        'Detection probability at 0 dB : %.2f %%\n', ...
        DetectionAt0dB);

end

fprintf( ...
    'Minimum average false alarms : %.3f/run\n', ...
    min(AverageFalseAlarms));

fprintf( ...
    'Maximum average false alarms : %.3f/run\n', ...
    max(AverageFalseAlarms));

fprintf( ...
    'Lowest range RMSE : %.4f m\n', ...
    min(RangeRMSE_Sweep_m, [], 'omitnan'));

fprintf( ...
    'Lowest velocity RMSE : %.4f m/s\n', ...
    min(VelocityRMSE_Sweep_mps, [], 'omitnan'));

fprintf('============================================================\n');

%% ============================================================
% 10. Plot detection probability versus SNR
%% ============================================================

figure('Name', 'Detection Probability versus SNR');

plot( ...
    SNRValues_dB, ...
    DetectionProbabilityPercent, ...
    'bo-', ...
    'LineWidth', 2, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Detection Probability (%)');

title('CA-CFAR Detection Probability versus SNR');

ylim([0 105]);

xlim([min(SNRValues_dB)-1, max(SNRValues_dB)+1]);

%% ============================================================
% 11. Plot false alarms versus SNR
%% ============================================================

figure('Name', 'False Alarms versus SNR');

plot( ...
    SNRValues_dB, ...
    AverageFalseAlarms, ...
    'ro-', ...
    'LineWidth', 2, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Average False Alarms per Run');

title('CA-CFAR False Alarms versus SNR');

xlim([min(SNRValues_dB)-1, max(SNRValues_dB)+1]);

%% ============================================================
% 12. Plot range RMSE versus SNR
%% ============================================================

figure('Name', 'Range RMSE versus SNR');

plot( ...
    SNRValues_dB, ...
    RangeRMSE_Sweep_m, ...
    'ko-', ...
    'LineWidth', 2, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Range RMSE (m)');

title('Range RMSE versus SNR');

xlim([min(SNRValues_dB)-1, max(SNRValues_dB)+1]);

%% ============================================================
% 13. Plot velocity RMSE versus SNR
%% ============================================================

figure('Name', 'Velocity RMSE versus SNR');

plot( ...
    SNRValues_dB, ...
    VelocityRMSE_Sweep_mps, ...
    'mo-', ...
    'LineWidth', 2, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Velocity RMSE (m/s)');

title('Velocity RMSE versus SNR');

xlim([min(SNRValues_dB)-1, max(SNRValues_dB)+1]);

%% ============================================================
% 14. Combined performance table
%% ============================================================

SNRPerformanceTable = table( ...
    SNRValues_dB(:), ...
    DetectionProbabilityPercent(:), ...
    AverageDetectedTargets(:), ...
    AverageTotalPeaks(:), ...
    AverageFalseAlarms(:), ...
    RangeRMSE_Sweep_m(:), ...
    RangeMeanError_Sweep_m(:), ...
    RangeMaximumError_Sweep_m(:), ...
    VelocityRMSE_Sweep_mps(:), ...
    VelocityMeanError_Sweep_mps(:), ...
    VelocityMaximumError_Sweep_mps(:), ...
    'VariableNames', ...
    { ...
    'SNR_dB', ...
    'DetectionProbability_percent', ...
    'AverageDetectedTargets', ...
    'AverageTotalPeaks', ...
    'AverageFalseAlarms', ...
    'RangeRMSE_m', ...
    'RangeMeanError_m', ...
    'RangeMaximumError_m', ...
    'VelocityRMSE_mps', ...
    'VelocityMeanError_mps', ...
    'VelocityMaximumError_mps' ...
    });

fprintf('\n');
fprintf('SNR performance table:\n');
disp(SNRPerformanceTable);

%% ============================================================
% 15. Save results
%% ============================================================

ResultsFolder = 'SARRS_Results';

if ~exist(ResultsFolder, 'dir')

    mkdir(ResultsFolder);

end

Timestamp = datestr(now, 'yyyymmdd_HHMMSS');

SNRMATFileName = fullfile( ...
    ResultsFolder, ...
    ['SNR_Sweep_MonteCarlo_' Timestamp '.mat']);

save( ...
    SNRMATFileName, ...
    'Radar', ...
    'NFastTime', ...
    'NPulses', ...
    'SNRValues_dB', ...
    'NumberOfMonteCarloRuns', ...
    'TrainingCells', ...
    'GuardCells', ...
    'ThresholdFactor', ...
    'RangeTolerance_m', ...
    'VelocityTolerance_mps', ...
    'TargetRanges_m', ...
    'TargetVelocities_mps', ...
    'TargetAmplitudes', ...
    'RangeAxis_m', ...
    'DopplerAxis_Hz', ...
    'VelocityAxis_mps', ...
    'DetectionProbabilityPercent', ...
    'AverageDetectedTargets', ...
    'AverageTotalPeaks', ...
    'AverageFalseAlarms', ...
    'RangeRMSE_Sweep_m', ...
    'RangeMeanError_Sweep_m', ...
    'RangeMaximumError_Sweep_m', ...
    'VelocityRMSE_Sweep_mps', ...
    'VelocityMeanError_Sweep_mps', ...
    'VelocityMaximumError_Sweep_mps', ...
    'DetectionProbabilityPerRun', ...
    'DetectedTargetsPerRun', ...
    'TotalPeaksPerRun', ...
    'FalseAlarmsPerRun', ...
    'RangeRMSEPerRun_m', ...
    'VelocityRMSEPerRun_mps', ...
    'SNRPerformanceTable');

SNRCsvFileName = fullfile( ...
    ResultsFolder, ...
    ['SNR_Sweep_PerformanceTable_' Timestamp '.csv']);

writetable( ...
    SNRPerformanceTable, ...
    SNRCsvFileName);

fprintf('\n');
fprintf('============================================================\n');
fprintf('SNR SWEEP RESULTS SAVED SUCCESSFULLY\n');
fprintf('============================================================\n');

fprintf('\nMAT file:\n');
fprintf('%s\n', SNRMATFileName);

fprintf('\nCSV file:\n');
fprintf('%s\n', SNRCsvFileName);

fprintf('\n============================================================\n');

%% ============================================================
% 16. Export important variables to MATLAB workspace
%% ============================================================

assignin('base', 'SNRValues_dB', SNRValues_dB);

assignin('base', ...
    'DetectionProbabilityPercent', ...
    DetectionProbabilityPercent);

assignin('base', ...
    'AverageDetectedTargets', ...
    AverageDetectedTargets);

assignin('base', ...
    'AverageTotalPeaks', ...
    AverageTotalPeaks);

assignin('base', ...
    'AverageFalseAlarms', ...
    AverageFalseAlarms);

assignin('base', ...
    'RangeRMSE_Sweep_m', ...
    RangeRMSE_Sweep_m);

assignin('base', ...
    'VelocityRMSE_Sweep_mps', ...
    VelocityRMSE_Sweep_mps);

assignin('base', ...
    'SNRPerformanceTable', ...
    SNRPerformanceTable);

fprintf('\nSNR sweep variables exported to MATLAB workspace.\n');

%% ============================================================
% 17. Local CA-CFAR function
%% ============================================================

function DetectionMap = CA_CFAR_2D_Local( ...
    PowerMap, ...
    TrainingCells, ...
    GuardCells, ...
    ThresholdFactor)

% ============================================================
% Two-dimensional Cell-Averaging CFAR detector
%
% PowerMap:
%     Input range-Doppler power matrix
%
% TrainingCells:
%     Number of training cells on each side
%
% GuardCells:
%     Number of guard cells on each side
%
% ThresholdFactor:
%     Multiplication factor applied to estimated noise power
%
% Output:
%     Logical detection map
% ============================================================

    [NumberOfRows, NumberOfColumns] = size(PowerMap);

    DetectionMap = false( ...
        NumberOfRows, ...
        NumberOfColumns);

    WindowRadius = ...
        TrainingCells + GuardCells;

    RowStart = WindowRadius + 1;

    RowEnd = NumberOfRows - WindowRadius;

    ColumnStart = WindowRadius + 1;

    ColumnEnd = NumberOfColumns - WindowRadius;

    for rowIndex = RowStart:RowEnd

        for columnIndex = ColumnStart:ColumnEnd

            RowIndices = ...
                (rowIndex-WindowRadius): ...
                (rowIndex+WindowRadius);

            ColumnIndices = ...
                (columnIndex-WindowRadius): ...
                (columnIndex+WindowRadius);

            LocalWindow = ...
                PowerMap(RowIndices, ColumnIndices);

            % Remove the guard region and CUT
            GuardRadius = GuardCells;

            CenterIndex = WindowRadius + 1;

            GuardRowStart = ...
                CenterIndex - GuardRadius;

            GuardRowEnd = ...
                CenterIndex + GuardRadius;

            GuardColumnStart = ...
                CenterIndex - GuardRadius;

            GuardColumnEnd = ...
                CenterIndex + GuardRadius;

            TrainingWindow = LocalWindow;

            TrainingWindow( ...
                GuardRowStart:GuardRowEnd, ...
                GuardColumnStart:GuardColumnEnd) = NaN;

            TrainingPowerValues = ...
                TrainingWindow(~isnan(TrainingWindow));

            if isempty(TrainingPowerValues)

                continue;

            end

            NoiseEstimate = ...
                mean(TrainingPowerValues);

            Threshold = ...
                ThresholdFactor * NoiseEstimate;

            CellUnderTest = ...
                PowerMap(rowIndex, columnIndex);

            if CellUnderTest > Threshold

                DetectionMap(rowIndex, columnIndex) = true;

            end

        end

    end

end