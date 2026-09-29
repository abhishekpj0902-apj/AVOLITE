%% ============================================================
% SARRS STUDIO
% SNR SWEEP MONTE CARLO RADAR PERFORMANCE TEST
%
% Complete standalone simulation:
%   1. Five-target radar echo generation
%   2. SNR-dependent complex AWGN
%   3. Range FFT
%   4. Doppler FFT
%   5. 2-D CA-CFAR
%   6. Peak extraction
%   7. Target matching
%   8. Detection probability
%   9. False alarm calculation
%  10. Range and velocity RMSE
%  11. Result plots
%  12. MAT and CSV export
%
% Compatible with MATLAB versions that support local functions.
% Does not require nanmean, nanstd, or Statistics Toolbox.
%% ============================================================

clear;
clc;
close all;

rng(20260914, 'twister');

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - SNR SWEEP MONTE CARLO RADAR TEST\n');
fprintf('============================================================\n');

%% ============================================================
% 1. RADAR PARAMETERS
%% ============================================================

Radar = struct();

Radar.c = 299792458;              % Speed of light, m/s
Radar.fc = 10e9;                  % Carrier frequency, Hz
Radar.lambda = Radar.c / Radar.fc;

Radar.Fs = 10e6;                 % Fast-time sample rate, Hz
Radar.PRF = 800;                 % Pulse repetition frequency, Hz

Radar.NFastTime = 256;            % Fast-time samples
Radar.NPulses = 128;              % Number of pulses

Radar.BW = 40.96e6;               % Chirp bandwidth, Hz
Radar.Tchirp = Radar.NFastTime / Radar.Fs;
Radar.Slope = Radar.BW / Radar.Tchirp;

Radar.NRangeFFT = Radar.NFastTime;
Radar.NDopplerFFT = Radar.NPulses;

Radar.TrainingCells = 8;
Radar.GuardCells = 2;
Radar.ThresholdFactor = 14;

Radar.RangeBinSpacing_m = ...
    Radar.c / (2 * Radar.BW);

Radar.RangeResolution_m = ...
    Radar.c / (2 * Radar.BW);

Radar.VelocityResolution_mps = ...
    Radar.lambda * Radar.PRF / ...
    (2 * Radar.NDopplerFFT);

Radar.MaxUnambiguousVelocity_mps = ...
    Radar.lambda * Radar.PRF / 4;

%% ============================================================
% 2. MONTE CARLO AND SNR SETTINGS
%% ============================================================

SNRValues_dB = -10:2:20;

NumberOfMonteCarloRuns = 100;

NoiseSigmaDisplay = NaN;

TargetRanges_m = [75 150 225 300 375];

TargetVelocities_mps = [-5 -3 -1 2 4];

TargetAmplitudes = [1.0 1.0 0.9 0.95 0.85];

NumberOfTargets = numel(TargetRanges_m);

RangeTolerance_m = 5;

VelocityTolerance_mps = 0.15;

%% ============================================================
% 3. AXES
%% ============================================================

RangeAxis_m = ...
    (0:(Radar.NRangeFFT/2 - 1)) * ...
    Radar.c * Radar.Fs / ...
    (2 * Radar.Slope * Radar.NRangeFFT);

DopplerAxis_Hz = ...
    (-Radar.NDopplerFFT/2 : Radar.NDopplerFFT/2 - 1) * ...
    Radar.PRF / Radar.NDopplerFFT;

VelocityAxis_mps = ...
    DopplerAxis_Hz * Radar.lambda / 2;

NumberOfRangeBins = numel(RangeAxis_m);
NumberOfDopplerBins = numel(DopplerAxis_Hz);

%% ============================================================
% 4. PRINT CONFIGURATION
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
    Radar.NFastTime);

fprintf('Number of pulses       : %d\n', ...
    Radar.NPulses);

fprintf('Sample rate            : %.2f MHz\n', ...
    Radar.Fs / 1e6);

fprintf('PRF                    : %.2f Hz\n', ...
    Radar.PRF);

fprintf('Carrier frequency      : %.2f GHz\n', ...
    Radar.fc / 1e9);

fprintf('Wavelength             : %.4f m\n', ...
    Radar.lambda);

fprintf('Bandwidth              : %.2f MHz\n', ...
    Radar.BW / 1e6);

fprintf('Range bin spacing      : %.4f m\n', ...
    Radar.RangeBinSpacing_m);

fprintf('Velocity resolution    : %.4f m/s\n', ...
    Radar.VelocityResolution_mps);

fprintf('Training cells         : %d\n', ...
    Radar.TrainingCells);

fprintf('Guard cells            : %d\n', ...
    Radar.GuardCells);

fprintf('CFAR threshold factor  : %.2f\n', ...
    Radar.ThresholdFactor);

fprintf('============================================================\n');

%% ============================================================
% 5. PREALLOCATE PERFORMANCE ARRAYS
%% ============================================================

NumberOfSNRPoints = numel(SNRValues_dB);

DetectionProbability = zeros(1, NumberOfSNRPoints);

AverageDetectedTargets = zeros(1, NumberOfSNRPoints);

AverageTotalPeaks = zeros(1, NumberOfSNRPoints);

AverageFalseAlarms = zeros(1, NumberOfSNRPoints);

RangeRMSE_m = NaN(1, NumberOfSNRPoints);

RangeMeanError_m = NaN(1, NumberOfSNRPoints);

RangeMaximumError_m = NaN(1, NumberOfSNRPoints);

VelocityRMSE_mps = NaN(1, NumberOfSNRPoints);

VelocityMeanError_mps = NaN(1, NumberOfSNRPoints);

VelocityMaximumError_mps = NaN(1, NumberOfSNRPoints);

MeasuredSNRMean_dB = NaN(1, NumberOfSNRPoints);

MeasuredSNRStd_dB = NaN(1, NumberOfSNRPoints);

%% ============================================================
% 6. GENERATE CLEAN RADAR ECHO
%
% The clean signal is generated only once.
% Noise is added independently for every SNR and Monte Carlo run.
%% ============================================================

fprintf('\nGenerating clean five-target radar echo...\n');

ReceivedDataClean = localGenerateCleanRadarEcho( ...
    Radar, ...
    TargetRanges_m, ...
    TargetVelocities_mps, ...
    TargetAmplitudes);

CleanSignalPower = mean(abs(ReceivedDataClean(:)).^2);

fprintf('Clean signal power     : %.6e\n', ...
    CleanSignalPower);

%% ============================================================
% 7. SNR SWEEP
%% ============================================================

for snrIndex = 1:NumberOfSNRPoints

    SNR_dB = SNRValues_dB(snrIndex);

    fprintf('\n------------------------------------------------------------\n');
    fprintf('SNR = %d dB\n', SNR_dB);
    fprintf('------------------------------------------------------------\n');

    DetectedTargetsPerRun = zeros(NumberOfMonteCarloRuns, 1);

    TotalPeaksPerRun = zeros(NumberOfMonteCarloRuns, 1);

    FalseAlarmsPerRun = zeros(NumberOfMonteCarloRuns, 1);

    RangeRMSEPerRun_m = NaN(NumberOfMonteCarloRuns, 1);

    RangeMeanErrorPerRun_m = NaN(NumberOfMonteCarloRuns, 1);

    RangeMaximumErrorPerRun_m = NaN(NumberOfMonteCarloRuns, 1);

    VelocityRMSEPerRun_mps = NaN(NumberOfMonteCarloRuns, 1);

    VelocityMeanErrorPerRun_mps = NaN(NumberOfMonteCarloRuns, 1);

    VelocityMaximumErrorPerRun_mps = NaN(NumberOfMonteCarloRuns, 1);

    MeasuredSNRPerRun_dB = NaN(NumberOfMonteCarloRuns, 1);

    for runIndex = 1:NumberOfMonteCarloRuns

        %% ----------------------------------------------------
        % 7.1 Generate SNR-dependent complex Gaussian noise
        %% ----------------------------------------------------

        SNRLinear = 10^(SNR_dB / 10);

        NoisePower = CleanSignalPower / SNRLinear;

        NoiseSigma = sqrt(NoisePower / 2);

        Noise = NoiseSigma * ...
            (randn(size(ReceivedDataClean)) + ...
             1i * randn(size(ReceivedDataClean)));

        ReceivedDataNoisy = ReceivedDataClean + Noise;

        %% ----------------------------------------------------
        % 7.2 Verify measured SNR
        %% ----------------------------------------------------

        ActualNoise = ReceivedDataNoisy - ReceivedDataClean;

        MeasuredSNR_dB = 10 * log10( ...
            mean(abs(ReceivedDataClean(:)).^2) / ...
            (mean(abs(ActualNoise(:)).^2) + eps));

        MeasuredSNRPerRun_dB(runIndex) = MeasuredSNR_dB;

        %% ----------------------------------------------------
        % 7.3 Range FFT
        %% ----------------------------------------------------

        FastTimeWindow = localHannWindow(Radar.NFastTime);

        RangeFFT = fft( ...
            ReceivedDataNoisy .* FastTimeWindow, ...
            Radar.NRangeFFT, ...
            1);

        RangeFFT = RangeFFT(1:NumberOfRangeBins, :);

        %% ----------------------------------------------------
        % 7.4 Doppler FFT
        %% ----------------------------------------------------

        SlowTimeWindow = localHannWindow(Radar.NPulses).';

        RangeDopplerComplex = fftshift( ...
            fft( ...
                RangeFFT .* SlowTimeWindow, ...
                Radar.NDopplerFFT, ...
                2), ...
            2);

        %% ----------------------------------------------------
        % 7.5 Range-Doppler power
        %% ----------------------------------------------------

        RangeDopplerPower = abs(RangeDopplerComplex).^2;

        RangeDopplerPower = ...
            RangeDopplerPower / ...
            max(RangeDopplerPower(:) + eps);

        %% ----------------------------------------------------
        % 7.6 2-D CA-CFAR
        %% ----------------------------------------------------

        DetectionMap = CA_CFAR_2D( ...
            RangeDopplerPower, ...
            Radar.TrainingCells, ...
            Radar.GuardCells, ...
            Radar.ThresholdFactor);

        %% ----------------------------------------------------
        % 7.7 Extract local maximum peaks
        %% ----------------------------------------------------

        [PeakRangeBins, PeakDopplerBins, PeakPowers] = ...
            localExtractPeaks( ...
                RangeDopplerPower, ...
                DetectionMap);

        DetectedRanges_m = ...
            RangeAxis_m(PeakRangeBins);

        DetectedDopplers_Hz = ...
            DopplerAxis_Hz(PeakDopplerBins);

        DetectedVelocities_mps = ...
            DetectedDopplers_Hz * Radar.lambda / 2;

        %% ----------------------------------------------------
        % 7.8 Match detections to known targets
        %% ----------------------------------------------------

        MatchResult = localMatchTargets( ...
            TargetRanges_m, ...
            TargetVelocities_mps, ...
            DetectedRanges_m, ...
            DetectedVelocities_mps, ...
            RangeTolerance_m, ...
            VelocityTolerance_mps);

        %% ----------------------------------------------------
        % 7.9 Store run results
        %% ----------------------------------------------------

        DetectedTargetsPerRun(runIndex) = ...
            MatchResult.NumberOfDetectedTargets;

        TotalPeaksPerRun(runIndex) = ...
            numel(DetectedRanges_m);

        FalseAlarmsPerRun(runIndex) = ...
            MatchResult.NumberOfFalseAlarms;

        if ~isempty(MatchResult.RangeErrors_m)

            RangeErrors = MatchResult.RangeErrors_m;

            VelocityErrors = MatchResult.VelocityErrors_mps;

            RangeRMSEPerRun_m(runIndex) = ...
                sqrt(mean(RangeErrors.^2));

            RangeMeanErrorPerRun_m(runIndex) = ...
                mean(RangeErrors);

            RangeMaximumErrorPerRun_m(runIndex) = ...
                max(abs(RangeErrors));

            VelocityRMSEPerRun_mps(runIndex) = ...
                sqrt(mean(VelocityErrors.^2));

            VelocityMeanErrorPerRun_mps(runIndex) = ...
                mean(VelocityErrors);

            VelocityMaximumErrorPerRun_mps(runIndex) = ...
                max(abs(VelocityErrors));

        end

        %% ----------------------------------------------------
        % 7.10 Progress display
        %% ----------------------------------------------------

        if runIndex == 1 || ...
                mod(runIndex, 10) == 0 || ...
                runIndex == NumberOfMonteCarloRuns

            CurrentDetectionProbability = ...
                100 * mean( ...
                DetectedTargetsPerRun(1:runIndex) / ...
                NumberOfTargets);

            CurrentAveragePeaks = ...
                mean(TotalPeaksPerRun(1:runIndex));

            fprintf( ...
                'Run %3d/%d | Detection = %6.2f %% | Peaks = %.2f\n', ...
                runIndex, ...
                NumberOfMonteCarloRuns, ...
                CurrentDetectionProbability, ...
                CurrentAveragePeaks);

        end

    end

    %% ========================================================
    % 7.11 Calculate SNR-point statistics
    %% ========================================================

    DetectionProbability(snrIndex) = ...
        100 * mean( ...
        DetectedTargetsPerRun / NumberOfTargets);

    AverageDetectedTargets(snrIndex) = ...
        mean(DetectedTargetsPerRun);

    AverageTotalPeaks(snrIndex) = ...
        mean(TotalPeaksPerRun);

    AverageFalseAlarms(snrIndex) = ...
        mean(FalseAlarmsPerRun);

    RangeRMSE_m(snrIndex) = ...
        localRMSE(RangeRMSEPerRun_m);

    RangeMeanError_m(snrIndex) = ...
        localMean(RangeMeanErrorPerRun_m);

    RangeMaximumError_m(snrIndex) = ...
        localMaximumAbsolute(RangeMaximumErrorPerRun_m);

    VelocityRMSE_mps(snrIndex) = ...
        localRMSE(VelocityRMSEPerRun_mps);

    VelocityMeanError_mps(snrIndex) = ...
        localMean(VelocityMeanErrorPerRun_mps);

    VelocityMaximumError_mps(snrIndex) = ...
        localMaximumAbsolute(VelocityMaximumErrorPerRun_mps);

    MeasuredSNRMean_dB(snrIndex) = ...
        localMean(MeasuredSNRPerRun_dB);

    MeasuredSNRStd_dB(snrIndex) = ...
        localStd(MeasuredSNRPerRun_dB);

    %% ========================================================
    % 7.12 Display SNR-point summary
    %% ========================================================

    fprintf('\nSNR point summary:\n');

    fprintf('Requested SNR          : %.2f dB\n', SNR_dB);

    fprintf('Measured SNR           : %.2f +/- %.2f dB\n', ...
        MeasuredSNRMean_dB(snrIndex), ...
        MeasuredSNRStd_dB(snrIndex));

    fprintf('Detection probability  : %.2f %%\n', ...
        DetectionProbability(snrIndex));

    fprintf('Average detected       : %.3f targets/run\n', ...
        AverageDetectedTargets(snrIndex));

    fprintf('Average total peaks    : %.3f peaks/run\n', ...
        AverageTotalPeaks(snrIndex));

    fprintf('Average false alarms   : %.5f/run\n', ...
        AverageFalseAlarms(snrIndex));

    fprintf('Range RMSE             : %.6f m\n', ...
        RangeRMSE_m(snrIndex));

    fprintf('Velocity RMSE          : %.6f m/s\n', ...
        VelocityRMSE_mps(snrIndex));

end

%% ============================================================
% 8. FINAL PERFORMANCE SUMMARY
%% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SNR SWEEP MONTE CARLO PERFORMANCE SUMMARY\n');
fprintf('============================================================\n');

fprintf('Monte Carlo runs/SNR   : %d\n', ...
    NumberOfMonteCarloRuns);

fprintf('SNR points             : %d\n', ...
    NumberOfSNRPoints);

fprintf('SNR range              : %d to %d dB\n', ...
    min(SNRValues_dB), max(SNRValues_dB));

fprintf('------------------------------------------------------------\n');

for snrIndex = 1:NumberOfSNRPoints

    fprintf( ...
        'SNR = %6.1f dB | Pd = %6.2f %% | False alarms = %.5f | Range RMSE = %.4f m | Velocity RMSE = %.4f m/s\n', ...
        SNRValues_dB(snrIndex), ...
        DetectionProbability(snrIndex), ...
        AverageFalseAlarms(snrIndex), ...
        RangeRMSE_m(snrIndex), ...
        VelocityRMSE_mps(snrIndex));

end

fprintf('============================================================\n');

%% ============================================================
% 9. PERFORMANCE TABLE
%% ============================================================

PerformanceTable = table( ...
    SNRValues_dB(:), ...
    MeasuredSNRMean_dB(:), ...
    MeasuredSNRStd_dB(:), ...
    DetectionProbability(:), ...
    AverageDetectedTargets(:), ...
    AverageTotalPeaks(:), ...
    AverageFalseAlarms(:), ...
    RangeRMSE_m(:), ...
    RangeMeanError_m(:), ...
    RangeMaximumError_m(:), ...
    VelocityRMSE_mps(:), ...
    VelocityMeanError_mps(:), ...
    VelocityMaximumError_mps(:), ...
    'VariableNames', { ...
    'RequestedSNR_dB', ...
    'MeasuredSNRMean_dB', ...
    'MeasuredSNRStd_dB', ...
    'DetectionProbability_percent', ...
    'AverageDetectedTargets', ...
    'AverageTotalPeaks', ...
    'AverageFalseAlarms', ...
    'RangeRMSE_m', ...
    'RangeMeanError_m', ...
    'RangeMaximumError_m', ...
    'VelocityRMSE_mps', ...
    'VelocityMeanError_mps', ...
    'VelocityMaximumError_mps'});

disp(PerformanceTable);

%% ============================================================
% 10. PLOT 1 - MEASURED SNR
%% ============================================================

figure('Name', 'Measured SNR Verification');

plot( ...
    SNRValues_dB, ...
    MeasuredSNRMean_dB, ...
    'bo-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

hold on;

plot( ...
    SNRValues_dB, ...
    SNRValues_dB, ...
    'k--', ...
    'LineWidth', 1.2);

grid on;

xlabel('Requested SNR (dB)');
ylabel('Measured SNR (dB)');

title('SNR Sweep - Requested versus Measured SNR');

legend( ...
    'Measured SNR', ...
    'Ideal SNR', ...
    'Location', ...
    'best');

hold off;

%% ============================================================
% 11. PLOT 2 - DETECTION PROBABILITY
%% ============================================================

figure('Name', 'SNR Sweep Detection Probability');

plot( ...
    SNRValues_dB, ...
    DetectionProbability, ...
    'bo-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Detection probability (%)');

title('SNR Sweep - Detection Probability');

ylim([0 105]);

%% ============================================================
% 12. PLOT 3 - FALSE ALARMS
%% ============================================================

figure('Name', 'SNR Sweep False Alarms');

plot( ...
    SNRValues_dB, ...
    AverageFalseAlarms, ...
    'ro-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Average false alarms/run');

title('SNR Sweep - Average False Alarms');

%% ============================================================
% 13. PLOT 4 - RANGE RMSE
%% ============================================================

figure('Name', 'SNR Sweep Range RMSE');

plot( ...
    SNRValues_dB, ...
    RangeRMSE_m, ...
    'ko-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Range RMSE (m)');

title('SNR Sweep - Range RMSE');

%% ============================================================
% 14. PLOT 5 - VELOCITY RMSE
%% ============================================================

figure('Name', 'SNR Sweep Velocity RMSE');

plot( ...
    SNRValues_dB, ...
    VelocityRMSE_mps, ...
    'mo-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Velocity RMSE (m/s)');

title('SNR Sweep - Velocity RMSE');

%% ============================================================
% 15. PLOT 6 - DETECTED TARGETS AND TOTAL PEAKS
%% ============================================================

figure('Name', 'SNR Sweep Detected Targets and Peaks');

plot( ...
    SNRValues_dB, ...
    AverageDetectedTargets, ...
    'bs-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

hold on;

plot( ...
    SNRValues_dB, ...
    AverageTotalPeaks, ...
    'rd-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

grid on;

xlabel('SNR (dB)');
ylabel('Average count per run');

title('SNR Sweep - Detected Targets and Total Peaks');

legend( ...
    'Average detected targets', ...
    'Average total peaks', ...
    'Location', ...
    'best');

hold off;

%% ============================================================
% 16. SAVE RESULTS
%% ============================================================

ResultsFolder = 'SARRS_Results';

if ~exist(ResultsFolder, 'dir')

    mkdir(ResultsFolder);

end

Timestamp = datestr(now, 'yyyymmdd_HHMMSS');

MATFileName = fullfile( ...
    ResultsFolder, ...
    ['SNR_Sweep_MonteCarlo_' Timestamp '.mat']);

CSVFileName = fullfile( ...
    ResultsFolder, ...
    ['SNR_Sweep_PerformanceTable_' Timestamp '.csv']);

save( ...
    MATFileName, ...
    'Radar', ...
    'SNRValues_dB', ...
    'NumberOfMonteCarloRuns', ...
    'TargetRanges_m', ...
    'TargetVelocities_mps', ...
    'TargetAmplitudes', ...
    'RangeTolerance_m', ...
    'VelocityTolerance_mps', ...
    'ReceivedDataClean', ...
    'CleanSignalPower', ...
    'RangeAxis_m', ...
    'DopplerAxis_Hz', ...
    'VelocityAxis_mps', ...
    'DetectionProbability', ...
    'AverageDetectedTargets', ...
    'AverageTotalPeaks', ...
    'AverageFalseAlarms', ...
    'RangeRMSE_m', ...
    'RangeMeanError_m', ...
    'RangeMaximumError_m', ...
    'VelocityRMSE_mps', ...
    'VelocityMeanError_mps', ...
    'VelocityMaximumError_mps', ...
    'MeasuredSNRMean_dB', ...
    'MeasuredSNRStd_dB', ...
    'PerformanceTable');

writetable(PerformanceTable, CSVFileName);

fprintf('\n');
fprintf('============================================================\n');
fprintf('SNR SWEEP RESULTS SAVED SUCCESSFULLY\n');
fprintf('============================================================\n');

fprintf('MAT file:\n');
fprintf('%s\n', MATFileName);

fprintf('\nCSV file:\n');
fprintf('%s\n', CSVFileName);

fprintf('============================================================\n');

%% ============================================================
% 17. LOCAL FUNCTION: CLEAN RADAR ECHO GENERATION
%% ============================================================

function ReceivedDataClean = localGenerateCleanRadarEcho( ...
    Radar, ...
    TargetRanges_m, ...
    TargetVelocities_mps, ...
    TargetAmplitudes)

    NFastTime = Radar.NFastTime;
    NPulses = Radar.NPulses;

    Fs = Radar.Fs;
    PRF = Radar.PRF;
    c = Radar.c;
    lambda = Radar.lambda;
    Slope = Radar.Slope;

    tFast = (0:NFastTime-1).' / Fs;

    PulseIndex = 0:NPulses-1;

    ReceivedDataClean = ...
        complex(zeros(NFastTime, NPulses));

    NumberOfTargets = numel(TargetRanges_m);

    for targetIndex = 1:NumberOfTargets

        TargetRange = TargetRanges_m(targetIndex);

        TargetVelocity = TargetVelocities_mps(targetIndex);

        TargetAmplitude = TargetAmplitudes(targetIndex);

        %% Range beat frequency

        BeatFrequency_Hz = ...
            2 * Slope * TargetRange / c;

        %% Doppler frequency

        DopplerFrequency_Hz = ...
            2 * TargetVelocity / lambda;

        %% Fast-time range phase

        FastTimeSignal = ...
            exp(1i * 2 * pi * BeatFrequency_Hz * tFast);

        %% Slow-time Doppler phase

        SlowTimeSignal = ...
            exp(1i * 2 * pi * DopplerFrequency_Hz * ...
            PulseIndex / PRF);

        %% Target echo

        TargetEcho = TargetAmplitude * ...
            FastTimeSignal * SlowTimeSignal;

        ReceivedDataClean = ...
            ReceivedDataClean + TargetEcho;

    end

    %% Normalize clean signal

    MaximumAmplitude = ...
        max(abs(ReceivedDataClean(:)));

    if MaximumAmplitude > 0

        ReceivedDataClean = ...
            ReceivedDataClean / MaximumAmplitude;

    end

end

%% ============================================================
% 18. LOCAL FUNCTION: HANN WINDOW
%% ============================================================

function Window = localHannWindow(NumberOfSamples)

    if NumberOfSamples == 1

        Window = 1;

    else

        n = (0:NumberOfSamples-1).';

        Window = ...
            0.5 - ...
            0.5 * cos(2*pi*n/(NumberOfSamples-1));

    end

end

%% ============================================================
% 19. LOCAL FUNCTION: 2-D CA-CFAR
%% ============================================================

function DetectionMap = CA_CFAR_2D( ...
    PowerMap, ...
    TrainingCells, ...
    GuardCells, ...
    ThresholdFactor)

    [NumberOfRows, NumberOfColumns] = size(PowerMap);

    DetectionMap = false(NumberOfRows, NumberOfColumns);

    TotalHalfWindow = TrainingCells + GuardCells;

    RowStart = TotalHalfWindow + 1;

    RowEnd = NumberOfRows - TotalHalfWindow;

    ColumnStart = TotalHalfWindow + 1;

    ColumnEnd = NumberOfColumns - TotalHalfWindow;

    if RowStart > RowEnd || ColumnStart > ColumnEnd

        warning('CA-CFAR window is larger than the input map.');

        return;

    end

    for rowIndex = RowStart:RowEnd

        for columnIndex = ColumnStart:ColumnEnd

            RowOuterStart = ...
                rowIndex - TotalHalfWindow;

            RowOuterEnd = ...
                rowIndex + TotalHalfWindow;

            ColumnOuterStart = ...
                columnIndex - TotalHalfWindow;

            ColumnOuterEnd = ...
                columnIndex + TotalHalfWindow;

            RowGuardStart = ...
                rowIndex - GuardCells;

            RowGuardEnd = ...
                rowIndex + GuardCells;

            ColumnGuardStart = ...
                columnIndex - GuardCells;

            ColumnGuardEnd = ...
                columnIndex + GuardCells;

            WindowPower = ...
                PowerMap( ...
                RowOuterStart:RowOuterEnd, ...
                ColumnOuterStart:ColumnOuterEnd);

            GuardPower = ...
                PowerMap( ...
                RowGuardStart:RowGuardEnd, ...
                ColumnGuardStart:ColumnGuardEnd);

            TrainingMask = true(size(WindowPower));

            GuardStartRow = ...
                GuardCells + 1;

            GuardEndRow = ...
                GuardCells + ...
                2 * GuardCells + 1;

            GuardStartColumn = GuardStartRow;

            GuardEndColumn = GuardEndRow;

            TrainingMask( ...
                GuardStartRow:GuardEndRow, ...
                GuardStartColumn:GuardEndColumn) = false;

            TrainingSamples = ...
                WindowPower(TrainingMask);

            if isempty(TrainingSamples)

                continue;

            end

            NoiseEstimate = mean(TrainingSamples);

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

%% ============================================================
% 20. LOCAL FUNCTION: PEAK EXTRACTION
%% ============================================================

function [PeakRows, PeakColumns, PeakPowers] = ...
    localExtractPeaks(PowerMap, DetectionMap)

    [NumberOfRows, NumberOfColumns] = size(PowerMap);

    CandidateRows = [];
    CandidateColumns = [];
    CandidatePowers = [];

    for rowIndex = 2:NumberOfRows-1

        for columnIndex = 2:NumberOfColumns-1

            if ~DetectionMap(rowIndex, columnIndex)

                continue;

            end

            LocalWindow = ...
                PowerMap( ...
                rowIndex-1:rowIndex+1, ...
                columnIndex-1:columnIndex+1);

            CellPower = ...
                PowerMap(rowIndex, columnIndex);

            if CellPower >= max(LocalWindow(:))

                CandidateRows(end+1, 1) = rowIndex; %#ok<AGROW>

                CandidateColumns(end+1, 1) = columnIndex; %#ok<AGROW>

                CandidatePowers(end+1, 1) = CellPower; %#ok<AGROW>

            end

        end

    end

    if isempty(CandidatePowers)

        PeakRows = zeros(0, 1);

        PeakColumns = zeros(0, 1);

        PeakPowers = zeros(0, 1);

        return;

    end

    %% Sort candidates from strongest to weakest

    CandidateTable = ...
        [CandidatePowers, CandidateRows, CandidateColumns];

    CandidateTable = ...
        sortrows(CandidateTable, -1);

    %% Non-maximum suppression

    SuppressionRange = 3;

    SuppressionDoppler = 3;

    Selected = false(size(CandidateTable, 1), 1);

    PeakRows = [];

    PeakColumns = [];

    PeakPowers = [];

    for candidateIndex = 1:size(CandidateTable, 1)

        CandidatePower = CandidateTable(candidateIndex, 1);

        CandidateRow = CandidateTable(candidateIndex, 2);

        CandidateColumn = CandidateTable(candidateIndex, 3);

        IsTooClose = false;

        for selectedIndex = 1:numel(PeakRows)

            RangeDistance = ...
                abs(CandidateRow - PeakRows(selectedIndex));

            DopplerDistance = ...
                abs(CandidateColumn - PeakColumns(selectedIndex));

            if RangeDistance <= SuppressionRange && ...
                    DopplerDistance <= SuppressionDoppler

                IsTooClose = true;

                break;

            end

        end

        if ~IsTooClose

            Selected(candidateIndex) = true;

            PeakRows(end+1, 1) = CandidateRow; %#ok<AGROW>

            PeakColumns(end+1, 1) = CandidateColumn; %#ok<AGROW>

            PeakPowers(end+1, 1) = CandidatePower; %#ok<AGROW>

        end

    end

    %% Limit unreasonable number of detections

    MaximumAllowedPeaks = 50;

    if numel(PeakPowers) > MaximumAllowedPeaks

        [~, SortIndex] = ...
            sort(PeakPowers, 'descend');

        SortIndex = ...
            SortIndex(1:MaximumAllowedPeaks);

        PeakRows = PeakRows(SortIndex);

        PeakColumns = PeakColumns(SortIndex);

        PeakPowers = PeakPowers(SortIndex);

    end

    %% Sort peaks by range

    [PeakRows, SortIndex] = sort(PeakRows);

    PeakColumns = PeakColumns(SortIndex);

    PeakPowers = PeakPowers(SortIndex);

end

%% ============================================================
% 21. LOCAL FUNCTION: TARGET MATCHING
%
% This function avoids the previous error:
%
% Index exceeds the number of array elements.
%
% It checks candidate indices before indexing the error arrays.
%% ============================================================

function MatchResult = localMatchTargets( ...
    TargetRanges_m, ...
    TargetVelocities_mps, ...
    DetectedRanges_m, ...
    DetectedVelocities_mps, ...
    RangeTolerance_m, ...
    VelocityTolerance_mps)

    NumberOfTargets = numel(TargetRanges_m);

    NumberOfDetections = numel(DetectedRanges_m);

    MatchResult = struct();

    MatchResult.MatchedTargetIndex = ...
        NaN(NumberOfTargets, 1);

    MatchResult.MatchedDetectionIndex = ...
        NaN(NumberOfTargets, 1);

    MatchResult.DetectedFlags = ...
        false(NumberOfTargets, 1);

    MatchResult.RangeErrors_m = [];

    MatchResult.VelocityErrors_mps = [];

    MatchResult.NumberOfDetectedTargets = 0;

    MatchResult.NumberOfFalseAlarms = 0;

    if NumberOfDetections == 0

        MatchResult.NumberOfFalseAlarms = 0;

        return;

    end

    %% Calculate target-to-detection differences

    RangeDifference = ...
        abs( ...
        TargetRanges_m(:) - ...
        DetectedRanges_m(:).');

    VelocityDifference = ...
        abs( ...
        TargetVelocities_mps(:) - ...
        DetectedVelocities_mps(:).');

    %% Normalized matching cost

    MatchingCost = ...
        RangeDifference / RangeTolerance_m + ...
        VelocityDifference / VelocityTolerance_mps;

    MatchingCost( ...
        RangeDifference > RangeTolerance_m | ...
        VelocityDifference > VelocityTolerance_mps) = inf;

    %% Greedy one-to-one matching

    UsedDetectionIndices = false(NumberOfDetections, 1);

    for targetIndex = 1:NumberOfTargets

        CandidateIndices = find( ...
            isfinite(MatchingCost(targetIndex, :)) & ...
            ~UsedDetectionIndices(:).');

        if isempty(CandidateIndices)

            continue;

        end

        CandidateCosts = ...
            MatchingCost(targetIndex, CandidateIndices);

        [~, BestCandidatePosition] = ...
            min(CandidateCosts);

        BestDetectionIndex = ...
            CandidateIndices(BestCandidatePosition);

        %% Safety check against invalid indices

        if BestDetectionIndex < 1 || ...
                BestDetectionIndex > NumberOfDetections

            continue;

        end

        UsedDetectionIndices(BestDetectionIndex) = true;

        MatchResult.MatchedTargetIndex(targetIndex) = ...
            targetIndex;

        MatchResult.MatchedDetectionIndex(targetIndex) = ...
            BestDetectionIndex;

        MatchResult.DetectedFlags(targetIndex) = true;

        MatchResult.NumberOfDetectedTargets = ...
            MatchResult.NumberOfDetectedTargets + 1;

        RangeError = ...
            DetectedRanges_m(BestDetectionIndex) - ...
            TargetRanges_m(targetIndex);

        VelocityError = ...
            DetectedVelocities_mps(BestDetectionIndex) - ...
            TargetVelocities_mps(targetIndex);

        MatchResult.RangeErrors_m(end+1, 1) = ...
            RangeError; %#ok<AGROW>

        MatchResult.VelocityErrors_mps(end+1, 1) = ...
            VelocityError; %#ok<AGROW>

    end

    MatchResult.NumberOfFalseAlarms = ...
        max(0, NumberOfDetections - ...
        MatchResult.NumberOfDetectedTargets);

end

%% ============================================================
% 22. LOCAL FUNCTION: RMSE WITHOUT NANMEAN
%% ============================================================

function Result = localRMSE(InputVector)

    ValidValues = ...
        InputVector(isfinite(InputVector));

    if isempty(ValidValues)

        Result = NaN;

    else

        Result = ...
            sqrt(mean(ValidValues.^2));

    end

end

%% ============================================================
% 23. LOCAL FUNCTION: MEAN WITHOUT NANMEAN
%% ============================================================

function Result = localMean(InputVector)

    ValidValues = ...
        InputVector(isfinite(InputVector));

    if isempty(ValidValues)

        Result = NaN;

    else

        Result = mean(ValidValues);

    end

end

%% ============================================================
% 24. LOCAL FUNCTION: STANDARD DEVIATION WITHOUT NANSTD
%% ============================================================

function Result = localStd(InputVector)

    ValidValues = ...
        InputVector(isfinite(InputVector));

    if numel(ValidValues) <= 1

        Result = 0;

    else

        Result = std(ValidValues);

    end

end

%% ============================================================
% 25. LOCAL FUNCTION: MAXIMUM ABSOLUTE VALUE
%% ============================================================

function Result = localMaximumAbsolute(InputVector)

    ValidValues = ...
        InputVector(isfinite(InputVector));

    if isempty(ValidValues)

        Result = NaN;

    else

        Result = max(abs(ValidValues));

    end

end