function Result = MultiPRFAmbiguityResolver(Track, Radar)
% ==============================================================
% MULTI-PRF AMBIGUITY RESOLVER
% ==============================================================
%
% Input:
%   Track : MATLAB table containing:
%           PRF_Hz
%           Range_m
%           AliasedDoppler_Hz
%           Amplitude              optional
%
%   Radar : structure containing:
%           PRF
%           Wavelength
%
%           Optional:
%           MaxVelocitySearch_mps
%           DopplerStep_Hz
%           DopplerTolerance_Hz
%
% Output:
%   Result : structure containing:
%           Range_m
%           MeasuredPRFs_Hz
%           MeasuredDopplers_Hz
%           TrueDoppler_Hz
%           TrueVelocity_mps
%           DopplerError_Hz
%           PredictedDopplers_Hz
%           CandidateTable
%           Valid
%
% ==============================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('MULTI-PRF DOPPLER AMBIGUITY RESOLUTION\n');
fprintf('====================================================\n');

%% -------------------------------------------------------------
% 1. Validate Track input
% --------------------------------------------------------------

if isempty(Track)
    error('Input Track table is empty.');
end

if ~istable(Track)
    error('Track must be a MATLAB table.');
end

requiredFields = { ...
    'PRF_Hz', ...
    'Range_m', ...
    'AliasedDoppler_Hz' ...
    };

for k = 1:numel(requiredFields)

    if ~ismember(requiredFields{k}, ...
            Track.Properties.VariableNames)

        error('Missing Track field: %s', ...
            requiredFields{k});

    end

end

%% -------------------------------------------------------------
% 2. Validate Radar input
% --------------------------------------------------------------

if ~isstruct(Radar)
    error('Radar must be a structure.');
end

if ~isfield(Radar, 'Wavelength')
    error('Radar.Wavelength is missing.');
end

if ~isfield(Radar, 'PRF')
    error('Radar.PRF is missing.');
end

lambda = double(Radar.Wavelength);
currentRadarPRF = double(Radar.PRF);

if ~isscalar(lambda) || ...
        ~isfinite(lambda) || ...
        lambda <= 0

    error('Radar.Wavelength must be a positive scalar.');
end

if ~isscalar(currentRadarPRF) || ...
        ~isfinite(currentRadarPRF) || ...
        currentRadarPRF <= 0

    error('Radar.PRF must be a positive scalar.');
end

%% -------------------------------------------------------------
% 3. Search configuration
% --------------------------------------------------------------

if isfield(Radar, 'MaxVelocitySearch_mps')

    maxVelocity = double( ...
        Radar.MaxVelocitySearch_mps);

else

    maxVelocity = 500;

end

if isempty(maxVelocity) || ...
        ~isscalar(maxVelocity) || ...
        ~isfinite(maxVelocity) || ...
        maxVelocity <= 0

    maxVelocity = 500;

end

if isfield(Radar, 'DopplerStep_Hz')

    dopplerStep = double( ...
        Radar.DopplerStep_Hz);

else

    dopplerStep = 1;

end

if isempty(dopplerStep) || ...
        ~isscalar(dopplerStep) || ...
        ~isfinite(dopplerStep) || ...
        dopplerStep <= 0

    dopplerStep = 1;

end

if isfield(Radar, 'DopplerTolerance_Hz')

    dopplerTolerance = double( ...
        Radar.DopplerTolerance_Hz);

else

    dopplerTolerance = 10;

end

if isempty(dopplerTolerance) || ...
        ~isscalar(dopplerTolerance) || ...
        ~isfinite(dopplerTolerance) || ...
        dopplerTolerance <= 0

    dopplerTolerance = 10;

end

%% -------------------------------------------------------------
% 4. Extract Track data safely
% --------------------------------------------------------------

PRFs = double(Track.PRF_Hz(:));

Ranges = double(Track.Range_m(:));

MeasuredDopplers = double( ...
    Track.AliasedDoppler_Hz(:));

numberOfRows = numel(PRFs);

if numel(Ranges) ~= numberOfRows
    error('Track.Range_m size does not match Track.PRF_Hz.');
end

if numel(MeasuredDopplers) ~= numberOfRows
    error('Track.AliasedDoppler_Hz size does not match Track.PRF_Hz.');
end

if ismember('Amplitude', ...
        Track.Properties.VariableNames)

    Amplitudes = double(Track.Amplitude(:));

    if numel(Amplitudes) ~= numberOfRows
        error('Track.Amplitude size does not match Track.PRF_Hz.');
    end

else

    Amplitudes = ones(numberOfRows, 1);

end

%% -------------------------------------------------------------
% 5. Validate numeric data
% --------------------------------------------------------------

if any(~isfinite(PRFs))
    error('Track contains invalid PRF values.');
end

if any(~isfinite(Ranges))
    error('Track contains invalid range values.');
end

if any(~isfinite(MeasuredDopplers))
    error('Track contains invalid Doppler values.');
end

if any(~isfinite(Amplitudes))
    Amplitudes(~isfinite(Amplitudes)) = 0;
end

if any(PRFs <= 0)
    error('All PRF values must be positive.');
end

%% -------------------------------------------------------------
% 6. Check number of unique PRFs
% --------------------------------------------------------------

uniquePRFs = unique(PRFs);

if numel(uniquePRFs) < 2

    warning('At least two different PRFs are required.');

    Result = struct();

    Result.Range_m = median(Ranges, 'omitnan');

    Result.MeasuredPRFs_Hz = PRFs;

    Result.MeasuredDopplers_Hz = ...
        MeasuredDopplers;

    Result.TrueDoppler_Hz = NaN;

    Result.TrueVelocity_mps = NaN;

    Result.DopplerError_Hz = NaN;

    Result.Wavelength_m = lambda;

    Result.MaxVelocitySearch_mps = maxVelocity;

    Result.DopplerStep_Hz = dopplerStep;

    Result.DopplerTolerance_Hz = dopplerTolerance;

    Result.Valid = false;

    Result.CurrentRadarPRF_Hz = ...
        currentRadarPRF;

    Result.PredictedDopplers_Hz = [];

    Result.SelectedAmplitudes = ...
        Amplitudes;

    Result.CandidateTable = table();

    Result.SignMode = NaN;

    fprintf('Associated range       : %.3f km\n', ...
        Result.Range_m / 1000);

    fprintf('PRFs used              : ');

    fprintf('%.0f ', uniquePRFs);

    fprintf('Hz\n');

    fprintf('Resolution valid       : false\n');

    fprintf('Reason                 : Only one unique PRF\n');

    fprintf('====================================================\n');

    return;

end

%% -------------------------------------------------------------
% 7. Select strongest detection for each PRF
% --------------------------------------------------------------

SelectedPRFs = zeros(numel(uniquePRFs), 1);

SelectedDopplers = zeros(numel(uniquePRFs), 1);

SelectedRanges = zeros(numel(uniquePRFs), 1);

SelectedAmplitudes = zeros(numel(uniquePRFs), 1);

for k = 1:numel(uniquePRFs)

    thisPRF = uniquePRFs(k);

    indexes = find(PRFs == thisPRF);

    if isempty(indexes)
        continue;
    end

    [~, strongestLocalIndex] = ...
        max(Amplitudes(indexes));

    selectedIndex = ...
        indexes(strongestLocalIndex);

    SelectedPRFs(k) = ...
        PRFs(selectedIndex);

    SelectedDopplers(k) = ...
        MeasuredDopplers(selectedIndex);

    SelectedRanges(k) = ...
        Ranges(selectedIndex);

    SelectedAmplitudes(k) = ...
        Amplitudes(selectedIndex);

end

%% -------------------------------------------------------------
% 8. Search true Doppler range
% --------------------------------------------------------------

maxDoppler = ...
    2 * maxVelocity / lambda;

searchDopplers = ...
    (-maxDoppler):dopplerStep:(maxDoppler);

%% -------------------------------------------------------------
% 9. Search all possible ambiguity candidates
% --------------------------------------------------------------

candidateDopplers = [];

candidateVelocities = [];

candidateResiduals = [];

candidateMaximumResiduals = [];

candidatePredictedDopplers = {};

candidateValid = [];

for candidateIndex = 1:numel(searchDopplers)

    candidateDoppler = ...
        searchDopplers(candidateIndex);

    predictedDopplers = zeros( ...
        numel(SelectedPRFs), 1);

    residuals = zeros( ...
        numel(SelectedPRFs), 1);

    for p = 1:numel(SelectedPRFs)

        thisPRF = SelectedPRFs(p);

        measuredDoppler = ...
            SelectedDopplers(p);

        % Fold candidate into the interval:
        % approximately [-PRF/2, +PRF/2]
        predictedDoppler = ...
            candidateDoppler - ...
            round(candidateDoppler / thisPRF) * ...
            thisPRF;

        predictedDopplers(p) = ...
            predictedDoppler;

        residuals(p) = abs( ...
            predictedDoppler - measuredDoppler);

    end

    totalResidual = sum(residuals);

    maximumResidual = max(residuals);

    isCandidateValid = ...
        maximumResidual <= dopplerTolerance;

    if isCandidateValid

        candidateDopplers(end + 1, 1) = ...
            candidateDoppler;

        candidateVelocities(end + 1, 1) = ...
            candidateDoppler * lambda / 2;

        candidateResiduals(end + 1, 1) = ...
            totalResidual;

        candidateMaximumResiduals(end + 1, 1) = ...
            maximumResidual;

        candidatePredictedDopplers{end + 1, 1} = ...
            predictedDopplers;

        candidateValid(end + 1, 1) = ...
            true;

    end

end

%% -------------------------------------------------------------
% 10. Build candidate table
% --------------------------------------------------------------

if isempty(candidateDopplers)

    CandidateTable = table();

    bestDoppler = NaN;

    trueVelocity = NaN;

    bestResidual = NaN;

    bestPredictedDopplers = [];

    resolutionValid = false;

else

    CandidateTable = table( ...
        candidateDopplers, ...
        candidateVelocities, ...
        candidateResiduals, ...
        candidateMaximumResiduals, ...
        candidateValid, ...
        'VariableNames', { ...
        'CandidateDoppler_Hz', ...
        'CandidateVelocity_mps', ...
        'TotalResidual_Hz', ...
        'MaximumResidual_Hz', ...
        'Valid'});

    % =============================================================
% SELECT CANDIDATE
% =============================================================

% First sort by Doppler residual
CandidateTable = sortrows( ...
    CandidateTable, ...
    {'TotalResidual_Hz', 'MaximumResidual_Hz'}, ...
    {'ascend', 'ascend'});

% Default selection:
% mathematically smallest residual
selectedCandidateIndex = 1;

% Optional known target velocity prior
useVelocityPrior = false;

if isfield(Radar, 'ExpectedVelocity_mps')

    expectedVelocity = ...
        double(Radar.ExpectedVelocity_mps);

    if isscalar(expectedVelocity) && ...
            isfinite(expectedVelocity)

        useVelocityPrior = true;

    end

end

if useVelocityPrior

    velocityDifference = abs( ...
        CandidateTable.CandidateVelocity_mps - ...
        expectedVelocity);

    % Only consider candidates within the same residual quality
    bestResidualValue = ...
        min(CandidateTable.TotalResidual_Hz);

    residualMargin = 0.5;

    acceptableCandidates = ...
        CandidateTable.TotalResidual_Hz <= ...
        bestResidualValue + residualMargin;

    candidateIndexes = ...
        find(acceptableCandidates);

    if ~isempty(candidateIndexes)

        [~, localIndex] = min( ...
            velocityDifference(candidateIndexes));

        selectedCandidateIndex = ...
            candidateIndexes(localIndex);

    end

end

% Selected result
bestDoppler = ...
    CandidateTable.CandidateDoppler_Hz( ...
    selectedCandidateIndex);

trueVelocity = ...
    CandidateTable.CandidateVelocity_mps( ...
    selectedCandidateIndex);

bestResidual = ...
    CandidateTable.TotalResidual_Hz( ...
    selectedCandidateIndex);

    % Recalculate predicted Dopplers for selected candidate
    bestPredictedDopplers = zeros( ...
        numel(SelectedPRFs), 1);

    for p = 1:numel(SelectedPRFs)

        thisPRF = SelectedPRFs(p);

        bestPredictedDopplers(p) = ...
            bestDoppler - ...
            round(bestDoppler / thisPRF) * ...
            thisPRF;

    end

    resolutionValid = true;

end

%% -------------------------------------------------------------
% 11. Associated range
% --------------------------------------------------------------

associatedRange = ...
    median(SelectedRanges, 'omitnan');

%% -------------------------------------------------------------
% 12. Print result
% --------------------------------------------------------------

fprintf('Associated range       : %.3f km\n', ...
    associatedRange / 1000);

fprintf('PRFs used              : ');

fprintf('%.0f ', SelectedPRFs);

fprintf('Hz\n');

fprintf('Measured Dopplers      : ');

fprintf('%.2f ', SelectedDopplers);

fprintf('Hz\n');

if resolutionValid

    fprintf('True Doppler           : %.2f Hz\n', ...
        bestDoppler);

    fprintf('True velocity          : %.2f m/s\n', ...
        trueVelocity);

    fprintf('Residual Doppler error : %.2f Hz\n', ...
        bestResidual);

else

    fprintf('True Doppler           : NaN\n');

    fprintf('True velocity          : NaN\n');

    fprintf('Residual Doppler error : NaN\n');

end

fprintf('Number of candidates   : %d\n', ...
    height(CandidateTable));

fprintf('Resolution valid       : %s\n', ...
    string(resolutionValid));

fprintf('====================================================\n');

%% -------------------------------------------------------------
% 13. Output structure
% --------------------------------------------------------------

Result = struct();

Result.Range_m = ...
    associatedRange;

Result.MeasuredPRFs_Hz = ...
    SelectedPRFs;

Result.MeasuredDopplers_Hz = ...
    SelectedDopplers;

Result.TrueDoppler_Hz = ...
    bestDoppler;

Result.TrueVelocity_mps = ...
    trueVelocity;

Result.DopplerError_Hz = ...
    bestResidual;

Result.Wavelength_m = ...
    lambda;

Result.MaxVelocitySearch_mps = ...
    maxVelocity;

Result.DopplerStep_Hz = ...
    dopplerStep;

Result.DopplerTolerance_Hz = ...
    dopplerTolerance;

Result.Valid = ...
    resolutionValid;

Result.CurrentRadarPRF_Hz = ...
    currentRadarPRF;

Result.PredictedDopplers_Hz = ...
    bestPredictedDopplers;

Result.SelectedAmplitudes = ...
    SelectedAmplitudes;

Result.CandidateTable = ...
    CandidateTable;

Result.SignMode = ...
    NaN;

end