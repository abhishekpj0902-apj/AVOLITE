function RangeData = RangeEstimator(MatchedData,Radar)

%=========================================================
% SARRS STUDIO
% Range Estimator
%
% Calculates target ranges from matched-filter peaks.
%
% Supports:
%   ✓ Multi-pulse matched-filter output
%   ✓ Existing range axis
%   ✓ Peak-based range estimation
%=========================================================


%% ========================================================
% Radar Parameters
%========================================================

c = Radar.c;


%% ========================================================
% Range Axis
%========================================================

if isfield(MatchedData,'RangeAxis') && ...
        ~isempty(MatchedData.RangeAxis)

    RangeAxis = double(MatchedData.RangeAxis(:));

else

    if ~isfield(MatchedData,'Output')

        error( ...
            'RangeEstimator: MatchedData.Output not found.');

    end

    Output = MatchedData.Output;

    % Number of fast-time/range samples only.
    NumSamples = size(Output,1);

    % Prefer matched-filter sample rate.
    if isfield(MatchedData,'SampleRate')

        Fs = MatchedData.SampleRate;

    else

        Fs = Radar.Bandwidth * 5;

    end

    RangeAxis = ...
        (0:NumSamples-1)' * c /(2*Fs);

end


%% ========================================================
% Peak Indices
%=========================================================

if isfield(MatchedData,'PeakIndices')

    PeakIndices = ...
        double(MatchedData.PeakIndices(:));

else

    PeakIndices = [];

end


%% ========================================================
% Validate Peak Indices
%=========================================================

ValidIndices = ...
    PeakIndices >= 1 & ...
    PeakIndices <= length(RangeAxis);

PeakIndices = ...
    PeakIndices(ValidIndices);


%% ========================================================
% Peak Ranges
%=========================================================

PeakRanges = ...
    RangeAxis(PeakIndices);


%% ========================================================
% Results
%=========================================================

RangeData.RangeAxis = RangeAxis;

RangeData.PeakIndices = PeakIndices;

RangeData.PeakRanges = PeakRanges;

RangeData.NumberOfTargets = ...
    length(PeakRanges);

RangeData.RangeResolution = ...
    Radar.RangeResolution;

RangeData.MaximumRange = ...
    Radar.MaximumRange;

RangeData.Description = ...
    "Range Estimator";


%% ========================================================
% Display
%=========================================================

disp(' ')
disp('=========================================')
disp('Range Estimation')
disp('=========================================')

fprintf( ...
    'Targets Detected : %d\n\n',...
    RangeData.NumberOfTargets);


for k = 1:RangeData.NumberOfTargets

    fprintf( ...
        'Target %d\n',...
        k);

    fprintf( ...
        'Range : %.2f m\n',...
        RangeData.PeakRanges(k));

    fprintf('\n');

end


end