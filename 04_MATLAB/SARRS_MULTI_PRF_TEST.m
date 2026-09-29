clc;
clear;
close all;

fprintf('\n==============================================\n');
fprintf('SARRS STUDIO MULTI-PRF PROCESSING TEST\n');
fprintf('==============================================\n');

%% =========================================================
% 1. Generate target model
% ==========================================================

TargetData = Target();

%% =========================================================
% 2. Generate radar parameters for three PRFs
% ==========================================================

Radar800  = Radar(800);
Radar900  = Radar(900);
Radar1000 = Radar(1000);

%% =========================================================
% 3. Generate waveforms
% ==========================================================

Waveform800  = Waveform(Radar800);
Waveform900  = Waveform(Radar900);
Waveform1000 = Waveform(Radar1000);

%% =========================================================
% 4. Generate target echoes
% ==========================================================

Echo800 = Echo(TargetData, Radar800, Waveform800, 1);

Echo900 = Echo(TargetData, Radar900, Waveform900, 1);

Echo1000 = Echo(TargetData, Radar1000, Waveform1000, 1);

%% =========================================================
% 5. Pulse compression
% ==========================================================

Matched800 = PulseCompression(Echo800);

Matched900 = PulseCompression(Echo900);

Matched1000 = PulseCompression(Echo1000);

%% =========================================================
% 6. MTI filtering
% ==========================================================

MTI800 = MTI(Matched800);

MTI900 = MTI(Matched900);

MTI1000 = MTI(Matched1000);

%% =========================================================
% 7. Range-Doppler processing
% ==========================================================

RD800 = RangeDopplerProcessor(MTI800, Radar800);

RD900 = RangeDopplerProcessor(MTI900, Radar900);

RD1000 = RangeDopplerProcessor(MTI1000, Radar1000);

%% =========================================================
% 8. Display final results
% ==========================================================

fprintf('\n==============================================\n');
fprintf('MULTI-PRF PIPELINE COMPLETED\n');
fprintf('==============================================\n');

fprintf('\nPRF = 800 Hz\n');
fprintf('Range-Doppler Map Size: %d x %d\n', ...
    size(RD800.Data, 1), size(RD800.Data, 2));

fprintf('Strongest Range   : %.3f km\n', ...
    RD800.GlobalRange / 1000);

fprintf('Strongest Doppler : %.3f Hz\n', ...
    RD800.GlobalDoppler);

fprintf('Strongest Velocity : %.3f m/s\n', ...
    RD800.GlobalVelocity);

fprintf('\nPRF = 900 Hz\n');
fprintf('Range-Doppler Map Size: %d x %d\n', ...
    size(RD900.Data, 1), size(RD900.Data, 2));

fprintf('Strongest Range   : %.3f km\n', ...
    RD900.GlobalRange / 1000);

fprintf('Strongest Doppler : %.3f Hz\n', ...
    RD900.GlobalDoppler);

fprintf('Strongest Velocity : %.3f m/s\n', ...
    RD900.GlobalVelocity);

fprintf('\nPRF = 1000 Hz\n');
fprintf('Range-Doppler Map Size: %d x %d\n', ...
    size(RD1000.Data, 1), size(RD1000.Data, 2));

fprintf('Strongest Range   : %.3f km\n', ...
    RD1000.GlobalRange / 1000);

fprintf('Strongest Doppler : %.3f Hz\n', ...
    RD1000.GlobalDoppler);

fprintf('Strongest Velocity : %.3f m/s\n', ...
    RD1000.GlobalVelocity);

fprintf('\nAll variables are now available in the workspace.\n');