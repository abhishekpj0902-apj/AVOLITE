function Doppler = DopplerEstimator(MTDData,Radar)

%=========================================================
% SARRS STUDIO
% Doppler Estimator
%
% Estimates Doppler Frequency and Velocity
% from the multi-pulse MTD output.
%
% Data format:
%   Rows    = range bins
%   Columns = Doppler bins
%=========================================================


%% ========================================================
% Display Header
%========================================================

disp(' ')
disp('=========================================')
disp('Doppler Estimation')
disp('=========================================')


%% ========================================================
% Validate Input
%========================================================

if ~isstruct(MTDData)

    error( ...
        'DopplerEstimator: MTDData must be a structure.');

end


if ~isfield(MTDData,'Spectrum')

    error( ...
        'DopplerEstimator: MTDData.Spectrum not found.');

end


%% ========================================================
% Extract Spectrum
%========================================================

Spectrum = abs(double(MTDData.Spectrum));


%% ========================================================
% Extract Axes
%========================================================

FreqAxis = double(MTDData.FrequencyAxis(:));

VelAxis = double(MTDData.VelocityAxis(:));


%% ========================================================
% Validate Dimensions
%========================================================

[NumRangeBins,NumDopplerBins] = ...
    size(Spectrum);


if length(FreqAxis) ~= NumDopplerBins

    error( ...
        'DopplerEstimator: Frequency axis size mismatch.');

end


if length(VelAxis) ~= NumDopplerBins

    error( ...
        'DopplerEstimator: Velocity axis size mismatch.');

end


%% ========================================================
% Create Range-Integrated Doppler Profile
%========================================================

% Combine energy over range bins.

DopplerProfile = ...
    max(Spectrum,[],1);


DopplerProfile = ...
    DopplerProfile(:);


%% ========================================================
% Normalize
%========================================================

MaximumValue = max(DopplerProfile);

if MaximumValue > 0

    NormalizedProfile = ...
        DopplerProfile ./ MaximumValue;

else

    NormalizedProfile = ...
        DopplerProfile;

end


%% ========================================================
% Peak Detection
%========================================================

if MaximumValue > 0

    MinHeight = ...
        0.20 * MaximumValue;

else

    MinHeight = 0;

end


% For 64 Doppler bins, a very large fixed distance
% such as 500 is inappropriate.

MinDistance = max(1,round(NumDopplerBins/16));


[Peaks,Locs] = findpeaks( ...
    DopplerProfile,...
    'MinPeakHeight',MinHeight,...
    'MinPeakDistance',MinDistance);


%% ========================================================
% Results
%========================================================

Doppler.Peaks = Peaks;

Doppler.Indices = Locs;

Doppler.Frequency = ...
    FreqAxis(Locs);

Doppler.Velocity = ...
    VelAxis(Locs);

Doppler.NumberOfTargets = ...
    length(Locs);

Doppler.Profile = ...
    DopplerProfile;

Doppler.NormalizedProfile = ...
    NormalizedProfile;

Doppler.FrequencyAxis = ...
    FreqAxis;

Doppler.VelocityAxis = ...
    VelAxis;

Doppler.NumRangeBins = ...
    NumRangeBins;

Doppler.NumDopplerBins = ...
    NumDopplerBins;

Doppler.Description = ...
    "Multi-Pulse Doppler Estimator";


%% ========================================================
% Display
%=========================================================

fprintf( ...
    'Range Bins    : %d\n',...
    NumRangeBins);

fprintf( ...
    'Doppler Bins  : %d\n',...
    NumDopplerBins);

fprintf( ...
    'Targets Found : %d\n\n',...
    Doppler.NumberOfTargets);


for k = 1:Doppler.NumberOfTargets

    fprintf( ...
        'Target %d\n',...
        k);

    fprintf( ...
        'Doppler  : %.2f Hz\n',...
        Doppler.Frequency(k));

    fprintf( ...
        'Velocity : %.2f m/s\n\n',...
        Doppler.Velocity(k));

end


%% ========================================================
% Plot
%=========================================================

figure( ...
    'Name','Doppler Estimator',...
    'NumberTitle','off');


plot( ...
    VelAxis,...
    NormalizedProfile,...
    'LineWidth',1.5);

hold on;


if ~isempty(Locs)

    plot( ...
        Doppler.Velocity,...
        NormalizedProfile(Locs),...
        'rv',...
        'MarkerFaceColor','r',...
        'MarkerSize',8);

end


xlabel('Velocity (m/s)');

ylabel('Normalized Magnitude');

title('Estimated Target Velocities');

grid on;

hold off;


end