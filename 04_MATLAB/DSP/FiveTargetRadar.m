%% ============================================================
%  SARRS STUDIO
%  FIVE-TARGET FMCW RADAR SIMULATION
%
%  File name:
%  FiveTargetRadar.m
%
%  This script performs:
%  1. FMCW radar signal generation
%  2. Five-target simulation
%  3. Range FFT
%  4. Doppler FFT
%  5. Range profile plotting
%  6. Range-Doppler map plotting
%  7. Reliable MAT-file saving
%% ============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS STUDIO - FIVE-TARGET RADAR SIMULATION\n');
fprintf('============================================================\n');

%% ============================================================
% 1. RADAR PARAMETERS
%% ============================================================

c = 3e8;                    % Speed of light
fc = 77e9;                  % Carrier frequency: 77 GHz
lambda = c / fc;            % Wavelength

B = 100e6;                  % FMCW bandwidth: 100 MHz
Tchirp = 40e-6;             % Chirp duration: 40 us
slope = B / Tchirp;         % Chirp slope

Fs = 10e6;                  % ADC sampling frequency
Ns = round(Fs * Tchirp);    % Samples per chirp

Nchirps = 128;              % Number of chirps
PRF = 1 / Tchirp;           % Slow-time sampling frequency

fprintf('\nRADAR PARAMETERS\n');
fprintf('------------------------------------------------------------\n');
fprintf('Carrier frequency : %.2f GHz\n', fc/1e9);
fprintf('Bandwidth         : %.2f MHz\n', B/1e6);
fprintf('Chirp duration    : %.2f us\n', Tchirp*1e6);
fprintf('Sampling frequency: %.2f MHz\n', Fs/1e6);
fprintf('Samples/chirp     : %d\n', Ns);
fprintf('Number of chirps  : %d\n', Nchirps);
fprintf('Chirp slope       : %.3e Hz/s\n', slope);
fprintf('Wavelength        : %.6f m\n', lambda);

%% ============================================================
% 2. TARGET INFORMATION
%% ============================================================

TargetRanges = [25 50 75 110 145];

TargetVelocities = [10 -15 5 -8 20];

TargetAmplitudes = [1.00 0.85 0.75 0.65 0.55];

NumberOfTargets = length(TargetRanges);

fprintf('\nTARGET INFORMATION\n');
fprintf('------------------------------------------------------------\n');

for k = 1:NumberOfTargets

    fprintf(['Target %d: Range = %6.2f m, ' ...
             'Velocity = %6.2f m/s, Amplitude = %.2f\n'], ...
             k, ...
             TargetRanges(k), ...
             TargetVelocities(k), ...
             TargetAmplitudes(k));

end

%% ============================================================
% 3. TIME AXES
%% ============================================================

% Fast-time axis within one chirp
t_fast = (0:Ns-1) / Fs;

% Slow-time axis across chirps
t_slow = (0:Nchirps-1) * Tchirp;

%% ============================================================
% 4. GENERATE RECEIVED BEAT SIGNAL
%
% Beat frequency:
%
% fb = 2 * slope * R / c
%
% Doppler frequency:
%
% fd = 2 * v / lambda
%
% The slow-time Doppler phase is included separately so that
% the Doppler FFT correctly detects target velocities.
%% ============================================================

BeatSignal = zeros(Nchirps, Ns);

for targetIndex = 1:NumberOfTargets

    R0 = TargetRanges(targetIndex);
    v = TargetVelocities(targetIndex);
    A = TargetAmplitudes(targetIndex);

    % Range beat frequency
    fb_range = (2 * slope * R0) / c;

    % Doppler frequency
    fd = (2 * v) / lambda;

    % Range migration during the CPI
    RangeOverSlowTime = R0 + v .* t_slow;

    % Beat frequency variation due to moving target
    fb_moving = (2 * slope .* RangeOverSlowTime) / c;

    % Generate each chirp
    for chirpIndex = 1:Nchirps

        % Fast-time phase caused by target range
        phase_range = 2*pi * fb_moving(chirpIndex) .* t_fast;

        % Slow-time Doppler phase
        phase_doppler = 2*pi * fd * t_slow(chirpIndex);

        % Target beat signal
        targetSignal = A .* exp( ...
            1j .* (phase_range + phase_doppler) );

        % Add target contribution
        BeatSignal(chirpIndex, :) = ...
            BeatSignal(chirpIndex, :) + targetSignal;

    end

end

%% ============================================================
% 5. ADD AWGN NOISE
%% ============================================================

SNR_dB = 25;

signalPower = mean(abs(BeatSignal(:)).^2);

noisePower = signalPower / (10^(SNR_dB/10));

noise = sqrt(noisePower/2) .* ...
    (randn(size(BeatSignal)) + 1j*randn(size(BeatSignal)));

ReceivedSignal = BeatSignal + noise;

%% ============================================================
% 6. RANGE FFT PROCESSING
%% ============================================================

% Window in fast-time
RangeWindow = hann(Ns).';

% Apply range window
RangeWindowedSignal = ReceivedSignal .* RangeWindow;

% Range FFT
RangeFFTFull = fft(RangeWindowedSignal, Ns, 2);

% Keep positive frequency bins only
Nrange = floor(Ns/2);

RangeFFT = RangeFFTFull(:, 1:Nrange);

% Range axis
RangeFrequencyAxis = (0:Nrange-1) * (Fs/Ns);

RangeAxis = (c .* RangeFrequencyAxis) ./ (2*slope);

% Range profile averaged over all chirps
RangeProfile = mean(abs(RangeFFT), 1);

% Normalize range profile
RangeProfileNormalized = RangeProfile ./ max(RangeProfile);

RangeProfile_dB = 20 .* log10(RangeProfileNormalized + eps);

%% ============================================================
% 7. DOPPLER FFT PROCESSING
%% ============================================================

% Window in slow-time
DopplerWindow = hann(Nchirps);

% Apply Doppler window
DopplerWindowedSignal = RangeFFT .* DopplerWindow;

% Doppler FFT along chirp dimension
DopplerFFTComplex = fftshift( ...
    fft(DopplerWindowedSignal, Nchirps, 1), 1);

% Doppler frequency axis
DopplerFrequencyAxis = ...
    (-Nchirps/2 : Nchirps/2-1) .* (PRF/Nchirps);

% Velocity axis
VelocityAxis = (lambda/2) .* DopplerFrequencyAxis;

% Magnitude of range-Doppler map
DopplerMap = abs(DopplerFFTComplex);

% Normalize map
DopplerMapNormalized = DopplerMap ./ max(DopplerMap(:));

% Convert to dB
DopplerMap_dB = 20 .* log10(DopplerMapNormalized + eps);

%% ============================================================
% 8. DISPLAY RANGE PROFILE
%% ============================================================

figure('Name', 'Five-Target Range Profile', ...
       'Color', 'w');

plot(RangeAxis, RangeProfile_dB, ...
     'LineWidth', 1.8);

hold on;

for k = 1:NumberOfTargets

    xline(TargetRanges(k), '--r', ...
        sprintf('%d m', TargetRanges(k)), ...
        'LineWidth', 1.2, ...
        'LabelOrientation', 'aligned', ...
        'LabelVerticalAlignment', 'middle');

end

grid on;

xlabel('Range (m)', 'FontSize', 12);
ylabel('Magnitude (dB)', 'FontSize', 12);

title('Five-Target Range Profile', ...
      'FontSize', 14, ...
      'FontWeight', 'bold');

xlim([0 200]);
ylim([-60 5]);

set(gca, 'FontSize', 11);

%% ============================================================
% 9. DISPLAY RANGE-DOPPLER MAP
%% ============================================================

figure('Name', 'Five-Target Range-Doppler Map', ...
       'Color', 'w');

imagesc(RangeAxis, VelocityAxis, DopplerMap_dB);

axis xy;
colormap turbo;
colorbar;

caxis([-40 0]);

hold on;

for k = 1:NumberOfTargets

    plot(TargetRanges(k), TargetVelocities(k), ...
        'wo', ...
        'MarkerSize', 9, ...
        'LineWidth', 1.5);

    text(TargetRanges(k) + 2, ...
         TargetVelocities(k), ...
         sprintf('T%d', k), ...
         'Color', 'w', ...
         'FontWeight', 'bold', ...
         'FontSize', 10);

end

xlabel('Range (m)', 'FontSize', 12);
ylabel('Velocity (m/s)', 'FontSize', 12);

title('Five-Target Range-Doppler Map', ...
      'FontSize', 14, ...
      'FontWeight', 'bold');

xlim([0 200]);
ylim([-25 25]);

set(gca, 'FontSize', 11);

%% ============================================================
% 10. SAVE RADAR RESULT
%% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SAVING RADAR SIMULATION RESULT\n');
fprintf('============================================================\n');

% Main result folder
ResultsFolder = fullfile(pwd, 'SARRS_Results');

% Temporary folder
TempFolder = fullfile(ResultsFolder, 'TEMP_FiveTargetRadar');

% Create folders if required
if ~exist(ResultsFolder, 'dir')
    mkdir(ResultsFolder);
end

if ~exist(TempFolder, 'dir')
    mkdir(TempFolder);
end

% Timestamp
TimeStamp = datestr(now, 'yyyymmdd_HHMMSS');

% Final and temporary file names
FinalFileName = sprintf( ...
    'FiveTargetRadar_Result_%s.mat', TimeStamp);

TempFileName = sprintf( ...
    'TEMP_FiveTargetRadar_Result_%s.mat', TimeStamp);

FinalFilePath = fullfile(ResultsFolder, FinalFileName);
TempFilePath = fullfile(TempFolder, TempFileName);

fprintf('\nSaving temporary MAT file:\n');
fprintf('%s\n', TempFilePath);

%% ============================================================
% 11. CREATE STRUCTURE
%% ============================================================

RadarResult = struct();

RadarResult.RadarParameters = struct( ...
    'c', c, ...
    'fc', fc, ...
    'lambda', lambda, ...
    'B', B, ...
    'Tchirp', Tchirp, ...
    'slope', slope, ...
    'Fs', Fs, ...
    'Ns', Ns, ...
    'Nchirps', Nchirps, ...
    'PRF', PRF, ...
    'SNR_dB', SNR_dB);

RadarResult.TargetInformation = struct( ...
    'TargetRanges', TargetRanges, ...
    'TargetVelocities', TargetVelocities, ...
    'TargetAmplitudes', TargetAmplitudes);

RadarResult.SignalData = struct( ...
    'BeatSignal', BeatSignal, ...
    'ReceivedSignal', ReceivedSignal);

RadarResult.RangeProcessing = struct( ...
    'RangeFFT', RangeFFT, ...
    'RangeAxis', RangeAxis, ...
    'RangeProfile', RangeProfile, ...
    'RangeProfile_dB', RangeProfile_dB);

RadarResult.DopplerProcessing = struct( ...
    'DopplerFFTComplex', DopplerFFTComplex, ...
    'DopplerMap', DopplerMap, ...
    'DopplerMap_dB', DopplerMap_dB, ...
    'DopplerFrequencyAxis', DopplerFrequencyAxis, ...
    'VelocityAxis', VelocityAxis);

%% ============================================================
% 12. SAVE ALL IMPORTANT VARIABLES
%% ============================================================

% Save to temporary file first
save(TempFilePath, ...
    'RadarResult', ...
    'c', ...
    'fc', ...
    'lambda', ...
    'B', ...
    'Tchirp', ...
    'slope', ...
    'Fs', ...
    'Ns', ...
    'Nchirps', ...
    'PRF', ...
    'BeatSignal', ...
    'ReceivedSignal', ...
    'RangeFFT', ...
    'RangeAxis', ...
    'RangeProfile', ...
    'RangeProfile_dB', ...
    'DopplerFFTComplex', ...
    'DopplerMap', ...
    'DopplerMap_dB', ...
    'DopplerFrequencyAxis', ...
    'VelocityAxis', ...
    'TargetRanges', ...
    'TargetVelocities', ...
    'TargetAmplitudes', ...
    '-v7');

% Verify temporary file exists and is not empty
if ~exist(TempFilePath, 'file')

    error('Temporary MAT file was not created.');

end

TempFileInfo = dir(TempFilePath);

if TempFileInfo.bytes <= 0

    error('Temporary MAT file is empty.');

end

% Move temporary file to final result folder
[MoveStatus, MoveMessage] = movefile( ...
    TempFilePath, FinalFilePath, 'f');

if ~MoveStatus

    error('Could not move MAT file: %s', MoveMessage);

end

%% ============================================================
% 13. FINAL FILE VERIFICATION
%% ============================================================

if ~exist(FinalFilePath, 'file')

    error('Final MAT file was not created.');

end

FinalFileInfo = dir(FinalFilePath);

if FinalFileInfo.bytes <= 0

    error('Final MAT file is empty.');

end

fprintf('\nRADAR RESULT SAVED SUCCESSFULLY\n');
fprintf('------------------------------------------------------------\n');
fprintf('Final MAT file:\n');
fprintf('%s\n', FinalFilePath);

fprintf('File size: %.2f KB\n', ...
    FinalFileInfo.bytes/1024);

%% ============================================================
% 14. PRINT EXPECTED TARGET DATA
%% ============================================================

fprintf('\nEXPECTED TARGET RANGES:\n');
disp(TargetRanges);

fprintf('EXPECTED TARGET VELOCITIES:\n');
disp(TargetVelocities);

fprintf('\n');
fprintf('============================================================\n');
fprintf('SIMULATION COMPLETED SUCCESSFULLY\n');
fprintf('============================================================\n');