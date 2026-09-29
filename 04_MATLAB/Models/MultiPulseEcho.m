function EchoData = MultiPulseEcho( ...
    Target, RadarData, WaveformData, CurrentScan, PRFData, RequestedSNR_dB)

%=========================================================
% SARRS STUDIO
% Multi-PRF Multi-Pulse Multi-Target Echo Generator
%
% Features
% ------------------------------------------
% ✓ Radar Equation
% ✓ Propagation Delay
% ✓ Multi Target Echo
% ✓ Pulse-to-Pulse Doppler Phase
% ✓ Multi-PRF Pulse Timing
% ✓ AWGN Noise
% ✓ Multi-Scan Target Motion
% ✓ 2-D Fast-Time / Slow-Time Data
%=========================================================


%% ========================================================
% Default Scan Number
%========================================================
if nargin < 6 || isempty(RequestedSNR_dB)
    RequestedSNR_dB = 20;
end

if nargin < 4 || isempty(ScanNumber)

    ScanNumber = 1;

end


%% ========================================================
% Validate PRF Scheduler Data
%=========================================================

if nargin < 5 || isempty(PRFData)

    error( ...
        'MultiPulseEcho requires PRFData from MultiPRFPulseScheduler.');

end


%% ========================================================
% Radar Parameters
%=========================================================

c       = RadarData.c;
Pt      = RadarData.Power;
G       = 10^(RadarData.Gain/10);
lambda  = RadarData.Wavelength;

Fs = WaveformData.SampleRate;

Tx = WaveformData.Signal(:);

N = length(Tx);


%% ========================================================
% Multi-PRF Timing
%=========================================================

PRFList = PRFData.PRFList;

PulsePRF = PRFData.PulsePRF;

PulsePRI = PRFData.PulsePRI;

PulseTime = PRFData.PulseTime;

PulseGroup = PRFData.PulseGroup;

NumPulses = PRFData.NumPulses;


%% ========================================================
% Fast-Time Axis
%=========================================================

FastTime = (0:N-1)'/Fs;


%% ========================================================
% Initialize
%=========================================================

ReceivedSignal = ...
    complex(zeros(N,NumPulses));

NumTargets = length(TargetData);

EchoData.TargetEchoes = ...
    cell(NumTargets,1);

EchoData.Delay = ...
    zeros(1,NumTargets);

EchoData.DelaySamples = ...
    zeros(1,NumTargets);

EchoData.Power = ...
    zeros(1,NumTargets);

EchoData.Range = ...
    zeros(1,NumTargets);

EchoData.Velocity = ...
    zeros(1,NumTargets);

EchoData.Doppler = ...
    zeros(1,NumTargets);

EchoData.Amplitude = ...
    zeros(1,NumTargets);


%% ========================================================
% Store Timing Information
%=========================================================

EchoData.ScanNumber = ScanNumber;

EchoData.NumPulses = NumPulses;

EchoData.PRFList = PRFList;

EchoData.PulsePRF = PulsePRF;

EchoData.PulsePRI = PulsePRI;

EchoData.PulseTime = PulseTime;

EchoData.PulseGroup = PulseGroup;


%% ========================================================
% Generate Echo For Each Target
%=========================================================

for k = 1:NumTargets


    %% ====================================================
    % Target Range
    %=====================================================

    DistanceHistory = ...
        TargetData(k).Distance;

    CurrentIndex = ...
        min(max(ScanNumber,1), ...
        length(DistanceHistory));

    R = DistanceHistory(CurrentIndex);


    %% ====================================================
    % Target Velocity
    %=====================================================

    if isfield(TargetData(k),'Velocity')

        V = TargetData(k).Velocity;

    else

        V = 0;

    end


    %% ====================================================
    % Target RCS
    %=====================================================

    if isfield(TargetData(k),'RCS')

        sigma = TargetData(k).RCS;

    else

        sigma = 1;

    end


    %% ====================================================
    % Propagation Delay
    %=====================================================

    tau = 2*R/c;

    DelaySamples = round(tau*Fs);

    EchoData.Range(k) = R;

    EchoData.Velocity(k) = V;

    EchoData.Delay(k) = tau;

    EchoData.DelaySamples(k) = ...
        DelaySamples;


    %% ====================================================
    % Radar Equation
    %=====================================================

    Pr = ...
        Pt*G^2*lambda^2*sigma / ...
        ((4*pi)^3 * R^4);

    EchoData.Power(k) = Pr;


    %% ====================================================
    % Echo Amplitude
    %=====================================================

    Amp = sqrt(Pr);

    % Simulation scaling
    ScaleFactor = 5e5;

    Amp = Amp * ScaleFactor;

    EchoData.Amplitude(k) = Amp;


    %% ====================================================
    % Doppler Frequency
    %=====================================================

    fd = 2*V/lambda;

    EchoData.Doppler(k) = fd;


    %% ====================================================
    % Create Multi-Pulse Echo
    %=====================================================

    TargetEcho = ...
        complex(zeros(N,NumPulses));


    %% ====================================================
    % Delayed Pulse
    %=====================================================

    if DelaySamples < N

        L = N - DelaySamples;

        DelayedPulse = ...
            complex(zeros(N,1));

        DelayedPulse(DelaySamples+1:end) = ...
            Tx(1:L);

    else

        DelayedPulse = ...
            complex(zeros(N,1));

    end


    %% ====================================================
    % Pulse-to-Pulse Doppler Phase
    %
    % IMPORTANT:
    %
    % PulseTime contains the actual time of every
    % transmitted pulse.
    %
    % Therefore Doppler phase is:
    %
    % exp(j*2*pi*fd*PulseTime)
    %
    % This supports non-uniform / multi-PRF timing.
    %=====================================================

    for p = 1:NumPulses

        DopplerPhase = ...
            exp(1j * ...
            2*pi*fd*PulseTime(p));

        TargetEcho(:,p) = ...
            Amp * ...
            DelayedPulse * ...
            DopplerPhase;

    end


    %% ====================================================
    % Store Individual Target Echo
    %=====================================================

    EchoData.TargetEchoes{k} = ...
        TargetEcho;


    %% ====================================================
    % Add Target Echo To Receiver Signal
    %=====================================================

    ReceivedSignal = ...
        ReceivedSignal + TargetEcho;

end


%% ========================================================
% AWGN Noise
%=========================================================

%% ============================================================
% CONFIGURABLE AWGN NOISE
% ============================================================

SignalPower = mean(abs(ReceivedSignal(:)).^2);

% Convert requested SNR from dB to linear scale
SNRLinear = 10^(RequestedSNR_dB/10);

% Required noise power for the requested SNR
NoisePower = SignalPower / SNRLinear;

% Complex AWGN
NoiseMatrix = sqrt(NoisePower/2) .* ...
    (randn(size(ReceivedSignal)) + ...
     1j*randn(size(ReceivedSignal)));

% Add noise before receiver gain
ReceivedSignal = ReceivedSignal + NoiseMatrix;


%% ========================================================
% Output
%=========================================================

EchoData.Signal = ReceivedSignal;

EchoData.Noise = Noise;

EchoData.NumberOfTargets = NumTargets;

EchoData.NumberOfSamples = N;

EchoData.SampleRate = Fs;

EchoData.Description = ...
    "Multi-PRF Multi-Pulse Multi-Target Echo Generator";


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Multi-PRF Target Echo Generator');
disp('=========================================');

fprintf('Scan Number       : %d\n', ...
    ScanNumber);

fprintf('Number of Pulses  : %d\n', ...
    NumPulses);

fprintf('Number of PRFs    : %d\n', ...
    length(PRFList));

fprintf('Fast-Time Samples : %d\n', ...
    N);

fprintf('Echo Matrix Size  : %d x %d\n', ...
    size(ReceivedSignal,1), ...
    size(ReceivedSignal,2));


%% ========================================================
% PRF Schedule Display
%=========================================================

disp(' ');
disp('PRF Schedule');

for k = 1:length(PRFList)

    Count = ...
        sum(PulsePRF == PRFList(k));

    fprintf( ...
        'PRF %d : %.0f Hz | Pulses : %d | PRI : %.6f s\n',...
        k,...
        PRFList(k),...
        Count,...
        1/PRFList(k));

end


%% ========================================================
% Target Display
%=========================================================

for k = 1:NumTargets

    fprintf('\nTarget %d\n',k);

    fprintf('Range    : %.0f m\n', ...
        EchoData.Range(k));

    fprintf('Velocity : %.0f m/s\n', ...
        EchoData.Velocity(k));

    fprintf('Doppler  : %.2f Hz\n', ...
        EchoData.Doppler(k));

    fprintf('Amplitude: %.3f\n', ...
        EchoData.Amplitude(k));

    fprintf('Delay    : %d samples\n', ...
        EchoData.DelaySamples(k));

end

end