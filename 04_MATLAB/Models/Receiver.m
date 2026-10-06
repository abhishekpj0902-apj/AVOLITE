function ReceiverData = Receiver(EchoData)

%=========================================================
% SARRS STUDIO
% RF Receiver Front-End
%
% Supports:
%   ✓ Multi-pulse input
%   ✓ LNA
%   ✓ Band Pass Filter Loss
%   ✓ Mixer Loss
%   ✓ IF Amplifier
%   ✓ Total Receiver Gain
%=========================================================


%% ========================================================
% LNA
%=========================================================

ReceiverData.LNAGain = 30;        % dB

ReceiverData.NoiseFigure = 2;     % dB


%% ========================================================
% Band Pass Filter
%=========================================================

ReceiverData.FilterLoss = 1;      % dB


%% ========================================================
% Mixer
%=========================================================

ReceiverData.MixerLoss = 6;       % dB


%% ========================================================
% IF Amplifier
%=========================================================

ReceiverData.IFGain = 40;         % dB


%% ========================================================
% Total Gain
%=========================================================

ReceiverData.TotalGain = ...
    ReceiverData.LNAGain ...
    - ReceiverData.FilterLoss ...
    - ReceiverData.MixerLoss ...
    + ReceiverData.IFGain;


%% ========================================================
% Convert dB Gain to Linear Voltage Gain
%=========================================================

GainLinear = ...
    10^(ReceiverData.TotalGain/20);


%% ========================================================
% Receiver Input
%=========================================================

InputSignal = double(EchoData.Signal);


%% ========================================================
% Receiver Output
%=========================================================

ReceiverData.InputSignal = InputSignal;

ReceiverData.OutputSignal = ...
    InputSignal * GainLinear;


%% ========================================================
% Metadata
%=========================================================

ReceiverData.SampleRate = EchoData.SampleRate;

ReceiverData.NumPulses = EchoData.NumPulses;

%% ========================================================
% Multi-PRF Timing Information
%=========================================================

if isfield(EchoData,'PRF')

    ReceiverData.PRF = EchoData.PRF;

else

    ReceiverData.PRF = EchoData.PulsePRF(1);

end

if isfield(EchoData,'PRFList')

    ReceiverData.PRFList = ...
        EchoData.PRFList;

end

if isfield(EchoData,'PulsePRF')

    ReceiverData.PulsePRF = ...
        EchoData.PulsePRF;

end

if isfield(EchoData,'PulsePRI')

    ReceiverData.PulsePRI = ...
        EchoData.PulsePRI;

end

if isfield(EchoData,'PulseTime')

    ReceiverData.PulseTime = ...
        EchoData.PulseTime;

end

if isfield(EchoData,'PulseGroup')

    ReceiverData.PulseGroup = ...
        EchoData.PulseGroup;

end

%% ========================================================
% PRI Compatibility
%=========================================================

if isfield(EchoData,'PRI')

    ReceiverData.PRI = EchoData.PRI;

else

    % Multi-PRF system does not have one fixed PRI.
    % Keep the primary PRF PRI as the compatibility value.

    ReceiverData.PRI = ...
        1 / ReceiverData.PRF;

end

ReceiverData.NumberOfSamples = ...
    size(InputSignal,1);


%% ========================================================
% Display
%=========================================================

disp(' ')
disp('=========================================')
disp('RF Receiver Front-End')
disp('=========================================')

fprintf('LNA Gain       : %.1f dB\n', ...
    ReceiverData.LNAGain);

fprintf('Filter Loss    : %.1f dB\n', ...
    ReceiverData.FilterLoss);

fprintf('Mixer Loss     : %.1f dB\n', ...
    ReceiverData.MixerLoss);

fprintf('IF Gain        : %.1f dB\n', ...
    ReceiverData.IFGain);

fprintf('Total Gain     : %.1f dB\n', ...
    ReceiverData.TotalGain);

fprintf('Number Samples : %d\n', ...
    ReceiverData.NumberOfSamples);

fprintf('Number Pulses  : %d\n', ...
    ReceiverData.NumPulses);

fprintf('Output Size    : %d x %d\n', ...
    size(ReceiverData.OutputSignal,1), ...
    size(ReceiverData.OutputSignal,2));

disp(' ')

end