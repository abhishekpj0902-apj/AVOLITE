function EchoData = Echo( ...
    TargetData, ...
    RadarData, ...
    WaveformData, ...
    ScanNumber)

%=========================================================
%
% SARRS STUDIO
% Multi-Pulse Multi-Target Echo Generator
%
% Features:
%   Radar Equation
%   Propagation Delay
%   Doppler Shift
%   Multi-Target Echo
%   AWGN Noise
%   Multi-Scan Target Position
%   Slow-Time Pulse Processing
%   Individual Target Echo Storage
%   PRF-Selectable Echo Generation
%
% Input:
%   TargetData
%   RadarData
%   WaveformData
%   ScanNumber
%
% Output:
%   EchoData.Signal
%       Fast-time x Pulse matrix
%
%   EchoData.TargetEchoes
%       Individual target echo matrices
%
%=========================================================


%% ========================================================
% Input Validation
%=========================================================

if nargin < 3

    error( ...
        "Echo requires TargetData, RadarData, and WaveformData.");

end


if nargin < 4 || isempty(ScanNumber)

    ScanNumber = 1;

end


if ScanNumber < 1

    ScanNumber = 1;

end


if ~isstruct(TargetData)

    error("TargetData must be a structure array.");

end


if ~isstruct(RadarData)

    error("RadarData must be a structure.");

end


if ~isstruct(WaveformData)

    error("WaveformData must be a structure.");

end


%% ========================================================
% Radar Parameters
%=========================================================

c = RadarData.c;

Pt = RadarData.Power;

G = 10^(RadarData.Gain / 10);

lambda = RadarData.Wavelength;

Fs = RadarData.SampleRate;

PRF = RadarData.PRF;

% Use the PRI already calculated by Radar.m
PRI = RadarData.PRI;


%% ========================================================
% Pulse Configuration
%=========================================================

% Number of coherent pulses
NumPulses = 64;

% Transmitted complex-baseband waveform
Tx = double(WaveformData.Signal(:));

% Number of fast-time samples
N = length(Tx);


%% ========================================================
% Fast-Time and Slow-Time Vectors
%=========================================================

FastTime = (0:N-1).' / Fs;

SlowTime = (0:NumPulses-1) * PRI;


%% ========================================================
% Number of Targets
%=========================================================

NumTargets = length(TargetData);


%% ========================================================
% Initialize Receiver Signal
%=========================================================

ReceivedSignal = complex(zeros(N, NumPulses));

NoiseMatrix = complex(zeros(N, NumPulses));


%% ========================================================
% Initialize Output Structure
%=========================================================

EchoData.TargetEchoes = cell(NumTargets, 1);

EchoData.Delay = zeros(1, NumTargets);

EchoData.DelaySamples = zeros(1, NumTargets);

EchoData.Power = zeros(1, NumTargets);

EchoData.Range = zeros(1, NumTargets);

EchoData.Velocity = zeros(1, NumTargets);

EchoData.Doppler = zeros(1, NumTargets);

EchoData.Amplitude = zeros(1, NumTargets);

EchoData.ScanNumber = ScanNumber;

EchoData.NumPulses = NumPulses;

EchoData.PRF = PRF;

EchoData.PRI = PRI;

EchoData.SampleRate = Fs;

EchoData.NumberOfSamples = N;

EchoData.FastTime = FastTime;

EchoData.SlowTime = SlowTime;


%% ========================================================
% Generate Echo for Each Target
%=========================================================

for k = 1:NumTargets


    %% ====================================================
    % Current Target Range
    %=====================================================

    DistanceHistory = TargetData(k).Distance;


    if isempty(DistanceHistory)

        error("Target %d has an empty Distance field.", k);

    end


    if ScanNumber > length(DistanceHistory)

        CurrentIndex = length(DistanceHistory);

    else

        CurrentIndex = ScanNumber;

    end


    R = DistanceHistory(CurrentIndex);


    %% ====================================================
    % Target Velocity
    %=====================================================

    if isfield(TargetData, 'Velocity')

        V = TargetData(k).Velocity;

    else

        V = 0;

    end


    %% ====================================================
    % Target Radar Cross Section
    %=====================================================

    if isfield(TargetData, 'RCS')

        sigma = TargetData(k).RCS;

    else

        sigma = 1;

    end


    %% ====================================================
    % Store Target Parameters
    %=====================================================

    EchoData.Range(k) = R;

    EchoData.Velocity(k) = V;


    %% ====================================================
    % Propagation Delay
    %=====================================================

    tau = 2 * R / c;

    EchoData.Delay(k) = tau;


    % Convert delay into integer fast-time samples
    DelaySamples = round(tau * Fs);

    EchoData.DelaySamples(k) = DelaySamples;


    %% ====================================================
    % Radar Equation
    %=====================================================

    Pr = ...
        Pt * G^2 * lambda^2 * sigma / ...
        ((4*pi)^3 * R^4);


    EchoData.Power(k) = Pr;


    %% ====================================================
    % Echo Amplitude
    %=====================================================

    Amp = sqrt(Pr);


    % Simulation scaling factor
    ScaleFactor = 5e5;

    Amp = Amp * ScaleFactor;


    EchoData.Amplitude(k) = Amp;


    %% ====================================================
    % Doppler Frequency
    %=====================================================

    % Monostatic radar Doppler equation:
    %
    % fd = 2V/lambda

    fd = 2 * V / lambda;

    EchoData.Doppler(k) = fd;


    %% ====================================================
    % Initialize Target Echo Matrix
    %=====================================================

    TargetEcho = complex(zeros(N, NumPulses));


    %% ====================================================
    % Generate Each Pulse
    %=====================================================

    for p = 1:NumPulses


        %% =================================================
        % Delayed Transmitted Pulse
        %=================================================

        PulseEcho = complex(zeros(N, 1));


        if DelaySamples < N

            L = N - DelaySamples;


            PulseEcho(DelaySamples+1:end) = ...
                Tx(1:L);

        end


        %% =================================================
        % Slow-Time Doppler Phase
        %=================================================

        % The phase progression depends on PRI.
        %
        % For different PRFs:
        %
        % PRF = 800 Hz
        % PRF = 900 Hz
        % PRF = 1000 Hz
        %
        % the Doppler phase progression changes.

        DopplerPhase = ...
            exp(1j * 2*pi * fd * SlowTime(p));


        %% =================================================
        % Apply Doppler Phase
        %=================================================

        PulseEcho = ...
            PulseEcho * DopplerPhase;


        %% =================================================
        % Apply Target Amplitude
        %=================================================

        PulseEcho = ...
            Amp * PulseEcho;


        %% =================================================
        % Store Pulse
        %=================================================

        TargetEcho(:, p) = PulseEcho;


    end


    %% ====================================================
    % Store Individual Target Echo
    %=====================================================

    EchoData.TargetEchoes{k} = TargetEcho;


    %% ====================================================
    % Add Target Echo to Receiver Signal
    %=====================================================

    ReceivedSignal = ...
        ReceivedSignal + TargetEcho;


end


%% ========================================================
% Add AWGN Noise
%=========================================================

NoiseAmplitude = 2e-7;


NoiseMatrix = ...
    NoiseAmplitude * ...
    (randn(N, NumPulses) + ...
     1j * randn(N, NumPulses));


ReceivedSignal = ...
    ReceivedSignal + NoiseMatrix;


%% ========================================================
% Final Output
%=========================================================

EchoData.Signal = ReceivedSignal;

EchoData.Noise = NoiseMatrix;

EchoData.NumberOfTargets = NumTargets;

EchoData.Description = ...
    "PRF-Selectable Multi-Pulse Multi-Target Echo Generator";


%% ========================================================
% Display Summary
%=========================================================

disp(' ');
disp('==============================================');
disp('PRF-Selectable Multi-Pulse Target Echo');
disp('==============================================');

fprintf('Scan Number       : %d\n', ScanNumber);

fprintf('Number of Targets : %d\n', NumTargets);

fprintf('Number of Pulses  : %d\n', NumPulses);

fprintf('PRF               : %.2f Hz\n', PRF);

fprintf('PRI               : %.9f s\n', PRI);

fprintf('Fast-Time Samples : %d\n', N);

fprintf('Echo Matrix Size  : %d x %d\n', ...
    N, NumPulses);


%% ========================================================
% Display Target Information
%=========================================================

for k = 1:NumTargets


    fprintf('\nTarget %d\n', k);

    fprintf('Range     : %.2f m\n', ...
        EchoData.Range(k));

    fprintf('Velocity  : %.2f m/s\n', ...
        EchoData.Velocity(k));

    fprintf('Doppler   : %.2f Hz\n', ...
        EchoData.Doppler(k));

    fprintf('Amplitude : %.6f\n', ...
        EchoData.Amplitude(k));

    fprintf('Delay     : %d samples\n', ...
        EchoData.DelaySamples(k));


end


disp(' ');
disp('Echo generation completed.');
disp(' ');

end