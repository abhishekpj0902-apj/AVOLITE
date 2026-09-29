function Pulse = PulseIntegrator(InputData,Method,NumPulses)

%=========================================================
% SARRS STUDIO
% Pulse Integrator
%
% Multi-Pulse Integration
%
% Data format:
%   Rows    = range / fast-time samples
%   Columns = pulses / slow-time samples
%
% Supports:
%   ✓ Coherent Integration
%   ✓ Non-Coherent Integration
%   ✓ Single-Pulse Input
%   ✓ Multi-Pulse Input
%=========================================================


%% ========================================================
% Defaults
%========================================================

if nargin < 2 || isempty(Method)

    Method = "NonCoherent";

end


%% ========================================================
% Extract Signal
%========================================================

if isstruct(InputData)

    if isfield(InputData,'Output')

        Signal = InputData.Output;

    elseif isfield(InputData,'Magnitude')

        Signal = InputData.Magnitude;

    elseif isfield(InputData,'Input')

        Signal = InputData.Input;

    else

        error( ...
            'PulseIntegrator: Unsupported input structure.');

    end

else

    Signal = InputData;

end


%% ========================================================
% Convert To Numeric
%========================================================

Signal = double(Signal);


%% ========================================================
% Preserve Matrix Structure
%========================================================

if isvector(Signal)

    Signal = Signal(:);

end


[NumSamples,AvailablePulses] = size(Signal);


%% ========================================================
% Determine Number Of Pulses
%========================================================

if nargin < 3 || isempty(NumPulses)

    NumPulses = AvailablePulses;

end


% Do not request more pulses than actually exist.

NumPulses = min(NumPulses,AvailablePulses);


if NumPulses < 1

    error( ...
        'PulseIntegrator: No pulses available.');

end


%% ========================================================
% Select Pulses
%========================================================

PulseData = ...
    Signal(:,1:NumPulses);


%% ========================================================
% Pulse Integration
%========================================================

switch upper(string(Method))

    %% ====================================================
    % Coherent Integration
    %=====================================================

    case "COHERENT"

        IntegratedSignal = ...
            sum(PulseData,2);


    %% ====================================================
    % Non-Coherent Integration
    %=====================================================

    case "NONCOHERENT"

        IntegratedSignal = ...
            sum(abs(PulseData),2);


    %% ====================================================
    % Invalid Method
    %=====================================================

    otherwise

        error( ...
            'PulseIntegrator: Unknown integration method "%s".',...
            string(Method));

end


%% ========================================================
% Normalize Optional
%========================================================

MaximumValue = max(abs(IntegratedSignal));

if MaximumValue > 0

    NormalizedOutput = ...
        IntegratedSignal ./ MaximumValue;

else

    NormalizedOutput = ...
        IntegratedSignal;

end


%% ========================================================
% Integration Gain
%========================================================

if NumPulses > 0

    switch upper(string(Method))

        case "COHERENT"

            IntegrationGain = ...
                20*log10(NumPulses);

        otherwise

            IntegrationGain = ...
                10*log10(NumPulses);

    end

else

    IntegrationGain = 0;

end


%% ========================================================
% Results
%========================================================

Pulse.Method = Method;

Pulse.Input = PulseData;

Pulse.Output = NormalizedOutput;

Pulse.RawOutput = IntegratedSignal;

Pulse.NumPulses = NumPulses;

Pulse.AvailablePulses = AvailablePulses;

Pulse.NumSamples = NumSamples;

Pulse.Gain = ...
    max(abs(IntegratedSignal));

Pulse.IntegrationGain = ...
    IntegrationGain;

Pulse.Description = ...
    "Multi-Pulse Pulse Integrator";


%% ========================================================
% Display
%========================================================

disp(' ')
disp('=========================================')
disp('Pulse Integrator')
disp('=========================================')

fprintf('Method            : %s\n', ...
    string(Method));

fprintf('Available Pulses  : %d\n', ...
    AvailablePulses);

fprintf('Integrated Pulses : %d\n', ...
    NumPulses);

fprintf('Samples           : %d\n', ...
    NumSamples);

fprintf('Integration Gain  : %.2f dB\n', ...
    IntegrationGain);

fprintf('Output Size       : %d x %d\n', ...
    size(NormalizedOutput,1),...
    size(NormalizedOutput,2));

disp(' ')

end