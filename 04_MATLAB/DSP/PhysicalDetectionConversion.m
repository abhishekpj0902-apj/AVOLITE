%% SARRS STUDIO - Physical Detection Conversion
% Run this script after generating PeakRangeBins and PeakDopplerBins.

clc;

%% Radar configuration
if ~exist('Radar800','var')
    Radar800 = struct;
    Radar800.PRF = 800;
    Radar800.SampleRate = 100e6;
    Radar800.Wavelength = 0.03;
    Radar800.c = 3e8;
end

Radar = Radar800;

if ~isfield(Radar,'c') || isempty(Radar.c)
    Radar.c = 3e8;
end

if ~isfield(Radar,'SampleRate') || isempty(Radar.SampleRate)
    Radar.SampleRate = 100e6;
end

if ~isfield(Radar,'PRF') || isempty(Radar.PRF)
    Radar.PRF = 800;
end

if ~isfield(Radar,'Wavelength') || isempty(Radar.Wavelength)
    Radar.Wavelength = 0.03;
end

%% Check required variables
if ~exist('RangeDopplerPower','var')
    error('RangeDopplerPower is missing. Run the CFAR test first.');
end

if ~exist('PeakRangeBins','var') || ~exist('PeakDopplerBins','var')
    error('PeakRangeBins or PeakDopplerBins is missing. Run peak extraction first.');
end

%% Matrix dimensions
NRange = size(RangeDopplerPower,1);
NDoppler = size(RangeDopplerPower,2);

%% Physical axes
RangeAxis_m = (0:NRange-1) * Radar.c / (2*Radar.SampleRate);

DopplerAxis_Hz = ((1:NDoppler) - ceil(NDoppler/2)) * ...
                 (Radar.PRF / NDoppler);

VelocityAxis_mps = DopplerAxis_Hz * Radar.Wavelength / 2;

%% Convert detected bins
DetectedRanges_m = RangeAxis_m(PeakRangeBins);
DetectedDopplers_Hz = DopplerAxis_Hz(PeakDopplerBins);
DetectedVelocities_mps = DetectedDopplers_Hz * Radar.Wavelength / 2;

%% Detection table
DetectionPhysicalTable = table( ...
    PeakRangeBins(:), ...
    PeakDopplerBins(:), ...
    DetectedRanges_m(:), ...
    DetectedDopplers_Hz(:), ...
    DetectedVelocities_mps(:), ...
    'VariableNames', ...
    {'RangeBin','DopplerBin','Range_m','Doppler_Hz','Velocity_mps'});

fprintf('\n============================================\n');
fprintf('PHYSICAL DETECTION CONVERSION RESULT\n');
fprintf('============================================\n');
fprintf('PRF             : %.2f Hz\n', Radar.PRF);
fprintf('Sample rate     : %.2f MHz\n', Radar.SampleRate/1e6);
fprintf('Wavelength      : %.4f m\n', Radar.Wavelength);
fprintf('Number of peaks : %d\n', height(DetectionPhysicalTable));
fprintf('============================================\n');

disp(DetectionPhysicalTable);

%% Plot
figure;
scatter(DetectedDopplers_Hz, DetectedRanges_m/1000, ...
        60, DetectedVelocities_mps, 'filled');
grid on;
colorbar;
xlabel('Doppler Frequency (Hz)');
ylabel('Range (km)');
title('Detected Targets in Physical Range-Doppler Coordinates');

%% Export variables to base workspace
assignin('base','Radar',Radar);
assignin('base','RangeAxis_m',RangeAxis_m);
assignin('base','DopplerAxis_Hz',DopplerAxis_Hz);
assignin('base','VelocityAxis_mps',VelocityAxis_mps);
assignin('base','DetectedRanges_m',DetectedRanges_m);
assignin('base','DetectedDopplers_Hz',DetectedDopplers_Hz);
assignin('base','DetectedVelocities_mps',DetectedVelocities_mps);
assignin('base','DetectionPhysicalTable',DetectionPhysicalTable);

fprintf('Physical detection variables exported successfully.\n');
