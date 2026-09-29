%% ============================================================
% SARRS STUDIO
% FIVE-TARGET DETECTION VALIDATION
%
% Purpose:
%   Calculate detected range, detected velocity,
%   range error, velocity error and RMSE.
%
% Required variables:
%   DopplerMap_dB
%   RangeAxis
%   VelocityAxis
%   TargetRanges
%   TargetVelocities
%
% ============================================================

clc;
close all;

fprintf('\n============================================================\n');
fprintf('SARRS STUDIO - FIVE-TARGET DETECTION VALIDATION\n');
fprintf('============================================================\n');

%% 1. Check required variables

RequiredVariables = { ...
    'DopplerMap_dB', ...
    'RangeAxis', ...
    'VelocityAxis', ...
    'TargetRanges', ...
    'TargetVelocities' ...
    };

for k = 1:numel(RequiredVariables)

    if ~exist(RequiredVariables{k}, 'var')

        error( ...
            'Missing required variable: %s\nRun LoadLatestRadarResultSafely first.', ...
            RequiredVariables{k});

    end

end

%% 2. Prepare data

Map_dB = double(DopplerMap_dB);

RangeAxis = double(RangeAxis(:));

VelocityAxis = double(VelocityAxis(:));

TargetRanges = double(TargetRanges(:));

TargetVelocities = double(TargetVelocities(:));

NumberOfTargets = numel(TargetRanges);

if numel(TargetVelocities) ~= NumberOfTargets

    error('TargetRanges and TargetVelocities must have equal lengths.');

end

if size(Map_dB, 1) ~= numel(VelocityAxis)

    error( ...
        'DopplerMap_dB row count does not match VelocityAxis length.');

end

if size(Map_dB, 2) ~= numel(RangeAxis)

    error( ...
        'DopplerMap_dB column count does not match RangeAxis length.');

end

%% 3. Search window around each expected target

RangeSearchWindow_m = 5;

VelocitySearchWindow_mps = 2;

DetectedRanges = nan(NumberOfTargets, 1);

DetectedVelocities = nan(NumberOfTargets, 1);

DetectedPeakValues_dB = nan(NumberOfTargets, 1);

RangeErrors_m = nan(NumberOfTargets, 1);

VelocityErrors_mps = nan(NumberOfTargets, 1);

%% 4. Detect the strongest peak near each target

for TargetIndex = 1:NumberOfTargets

    ExpectedRange = TargetRanges(TargetIndex);

    ExpectedVelocity = TargetVelocities(TargetIndex);

    ValidRange = ...
        abs(RangeAxis - ExpectedRange) <= RangeSearchWindow_m;

    ValidVelocity = ...
        abs(VelocityAxis - ExpectedVelocity) <= ...
        VelocitySearchWindow_mps;

    RangeIndices = find(ValidRange);

    VelocityIndices = find(ValidVelocity);

    if isempty(RangeIndices) || isempty(VelocityIndices)

        warning( ...
            'No search region found for target %d.', ...
            TargetIndex);

        continue;

    end

    LocalMap = ...
        Map_dB(VelocityIndices, RangeIndices);

    [PeakValue, LinearIndex] = max(LocalMap(:));

    [LocalVelocityIndex, LocalRangeIndex] = ...
        ind2sub(size(LocalMap), LinearIndex);

    ActualVelocityIndex = ...
        VelocityIndices(LocalVelocityIndex);

    ActualRangeIndex = ...
        RangeIndices(LocalRangeIndex);

    DetectedRanges(TargetIndex) = ...
        RangeAxis(ActualRangeIndex);

    DetectedVelocities(TargetIndex) = ...
        VelocityAxis(ActualVelocityIndex);

    DetectedPeakValues_dB(TargetIndex) = ...
        PeakValue;

    RangeErrors_m(TargetIndex) = ...
        DetectedRanges(TargetIndex) - ExpectedRange;

    VelocityErrors_mps(TargetIndex) = ...
        DetectedVelocities(TargetIndex) - ExpectedVelocity;

end

%% 5. Calculate performance metrics

ValidDetections = ...
    isfinite(DetectedRanges) & ...
    isfinite(DetectedVelocities);

NumberOfValidDetections = ...
    sum(ValidDetections);

DetectionProbability_percent = ...
    100 * NumberOfValidDetections / NumberOfTargets;

if NumberOfValidDetections > 0

    RangeRMSE_m = sqrt( ...
        mean(RangeErrors_m(ValidDetections).^2));

    VelocityRMSE_mps = sqrt( ...
        mean(VelocityErrors_mps(ValidDetections).^2));

    RangeMeanError_m = ...
        mean(RangeErrors_m(ValidDetections));

    VelocityMeanError_mps = ...
        mean(VelocityErrors_mps(ValidDetections));

    RangeMaximumError_m = ...
        max(abs(RangeErrors_m(ValidDetections)));

    VelocityMaximumError_mps = ...
        max(abs(VelocityErrors_mps(ValidDetections)));

else

    RangeRMSE_m = NaN;

    VelocityRMSE_mps = NaN;

    RangeMeanError_m = NaN;

    VelocityMeanError_mps = NaN;

    RangeMaximumError_m = NaN;

    VelocityMaximumError_mps = NaN;

end

%% 6. Display target-by-target results

fprintf('\n============================================================\n');
fprintf('TARGET-BY-TARGET DETECTION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf( ...
    '%8s %15s %15s %15s %15s %15s\n', ...
    'Target', ...
    'Expected R(m)', ...
    'Detected R(m)', ...
    'Range Err(m)', ...
    'Expected V', ...
    'Detected V');

fprintf('%s\n', ...
    repmat('-', 1, 95));

for TargetIndex = 1:NumberOfTargets

    fprintf( ...
        '%8d %15.3f %15.3f %15.3f %15.3f %15.3f\n', ...
        TargetIndex, ...
        TargetRanges(TargetIndex), ...
        DetectedRanges(TargetIndex), ...
        RangeErrors_m(TargetIndex), ...
        TargetVelocities(TargetIndex), ...
        DetectedVelocities(TargetIndex));

end

fprintf('\nVelocity errors:\n');

disp(VelocityErrors_mps);

%% 7. Display final metrics

fprintf('\n============================================================\n');
fprintf('FINAL PERFORMANCE METRICS\n');
fprintf('============================================================\n');

fprintf( ...
    'Total targets             : %d\n', ...
    NumberOfTargets);

fprintf( ...
    'Valid detections          : %d\n', ...
    NumberOfValidDetections);

fprintf( ...
    'Detection probability     : %.2f %%\n', ...
    DetectionProbability_percent);

fprintf( ...
    'Range RMSE                : %.6f m\n', ...
    RangeRMSE_m);

fprintf( ...
    'Range mean error          : %.6f m\n', ...
    RangeMeanError_m);

fprintf( ...
    'Range maximum absolute err: %.6f m\n', ...
    RangeMaximumError_m);

fprintf( ...
    'Velocity RMSE             : %.6f m/s\n', ...
    VelocityRMSE_mps);

fprintf( ...
    'Velocity mean error       : %.6f m/s\n', ...
    VelocityMeanError_mps);

fprintf( ...
    'Velocity maximum abs err  : %.6f m/s\n', ...
    VelocityMaximumError_mps);

%% 8. Save results into a structure

ValidationResults = struct();

ValidationResults.TargetRanges_m = TargetRanges;

ValidationResults.TargetVelocities_mps = TargetVelocities;

ValidationResults.DetectedRanges_m = DetectedRanges;

ValidationResults.DetectedVelocities_mps = DetectedVelocities;

ValidationResults.DetectedPeakValues_dB = ...
    DetectedPeakValues_dB;

ValidationResults.RangeErrors_m = RangeErrors_m;

ValidationResults.VelocityErrors_mps = VelocityErrors_mps;

ValidationResults.NumberOfTargets = NumberOfTargets;

ValidationResults.NumberOfValidDetections = ...
    NumberOfValidDetections;

ValidationResults.DetectionProbability_percent = ...
    DetectionProbability_percent;

ValidationResults.RangeRMSE_m = RangeRMSE_m;

ValidationResults.RangeMeanError_m = ...
    RangeMeanError_m;

ValidationResults.RangeMaximumError_m = ...
    RangeMaximumError_m;

ValidationResults.VelocityRMSE_mps = ...
    VelocityRMSE_mps;

ValidationResults.VelocityMeanError_mps = ...
    VelocityMeanError_mps;

ValidationResults.VelocityMaximumError_mps = ...
    VelocityMaximumError_mps;

%% 9. Save validation result

ValidationFolder = fullfile( ...
    pwd, ...
    'SARRS_Results');

if ~exist(ValidationFolder, 'dir')

    mkdir(ValidationFolder);

end

ValidationFile = fullfile( ...
    ValidationFolder, ...
    'FiveTarget_Detection_Validation.mat');

save( ...
    ValidationFile, ...
    'ValidationResults');

fprintf('\nValidation result saved to:\n%s\n', ...
    ValidationFile);

%% 10. Plot detected points

figure( ...
    'Name', ...
    'SARRS Five-Target Detection Validation', ...
    'NumberTitle', ...
    'off', ...
    'Color', ...
    'w');

imagesc( ...
    RangeAxis, ...
    VelocityAxis, ...
    Map_dB);

axis xy;

xlabel('Range (m)');

ylabel('Velocity (m/s)');

title('Five-Target Range-Doppler Detection Validation');

colorbar;

grid on;

hold on;

plot( ...
    TargetRanges, ...
    TargetVelocities, ...
    'rx', ...
    'MarkerSize', ...
    12, ...
    'LineWidth', ...
    2, ...
    'DisplayName', ...
    'Expected targets');

plot( ...
    DetectedRanges, ...
    DetectedVelocities, ...
    'wo', ...
    'MarkerSize', ...
    9, ...
    'LineWidth', ...
    1.5, ...
    'DisplayName', ...
    'Detected peaks');

for TargetIndex = 1:NumberOfTargets

    text( ...
        DetectedRanges(TargetIndex) + 1, ...
        DetectedVelocities(TargetIndex), ...
        sprintf('T%d', TargetIndex), ...
        'Color', ...
        'w', ...
        'FontWeight', ...
        'bold');

end

legend('Location', 'best');

xlim([0 170]);

ylim([-25 25]);

hold off;

fprintf('\n============================================================\n');
fprintf('VALIDATION COMPLETE\n');
fprintf('============================================================\n');