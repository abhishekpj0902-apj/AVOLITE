function PRFData = MultiPRFPulseScheduler(RadarConfigData)

%=========================================================
% SARRS STUDIO
% Multi-PRF Pulse Scheduler
%
% Creates the PRF/PRI schedule used by the multi-PRF
% Doppler processing chain.
%=========================================================

%% ========================================================
% Input Validation
%=========================================================

if nargin < 1
    error('MultiPRFPulseScheduler requires RadarConfigData.');
end

if ~isfield(RadarConfigData,'PRFList')
    error('RadarConfigData.PRFList not found.');
end

if ~isfield(RadarConfigData,'NumPulses')
    error('RadarConfigData.NumPulses not found.');
end


%% ========================================================
% Configuration
%=========================================================

PRFList = double(RadarConfigData.PRFList(:).');

NumPRFs = length(PRFList);

NumPulses = RadarConfigData.NumPulses;


%% ========================================================
% Pulse Distribution
%=========================================================

% Divide the available pulses as evenly as possible
% between the configured PRFs.

PulsesPerPRF = floor(NumPulses / NumPRFs);

Remainder = mod(NumPulses,NumPRFs);


%% ========================================================
% Create Pulse PRF Sequence
%=========================================================

PulsePRF = zeros(1,NumPulses);

PulseIndex = 1;


for k = 1:NumPRFs

    Count = PulsesPerPRF;

    if k <= Remainder
        Count = Count + 1;
    end

    EndIndex = ...
        PulseIndex + Count - 1;

    PulsePRF(PulseIndex:EndIndex) = ...
        PRFList(k);

    PulseIndex = EndIndex + 1;

end


%% ========================================================
% PRI Sequence
%=========================================================

PulsePRI = 1 ./ PulsePRF;


%% ========================================================
% Pulse Time
%=========================================================

PulseTime = zeros(1,NumPulses);

for p = 2:NumPulses

    PulseTime(p) = ...
        PulseTime(p-1) + PulsePRI(p-1);

end


%% ========================================================
% PRF Group
%=========================================================

PulseGroup = zeros(1,NumPulses);

for p = 1:NumPulses

    [~,Group] = ...
        min(abs(PRFList - PulsePRF(p)));

    PulseGroup(p) = Group;

end


%% ========================================================
% Output
%=========================================================

PRFData.PRFList = PRFList;

PRFData.NumPRFs = NumPRFs;

PRFData.NumPulses = NumPulses;

PRFData.PulsePRF = PulsePRF;

PRFData.PulsePRI = PulsePRI;

PRFData.PulseTime = PulseTime;

PRFData.PulseGroup = PulseGroup;

PRFData.PulsesPerPRF = ...
    PulsesPerPRF;

PRFData.Description = ...
    "Multi-PRF Pulse Scheduler";


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Multi-PRF Pulse Scheduler');
disp('=========================================');

fprintf('Total Pulses : %d\n',NumPulses);

fprintf('Number of PRFs : %d\n',NumPRFs);

disp(' ');

for k = 1:NumPRFs

    Count = sum(PulseGroup == k);

    fprintf( ...
        'PRF %d : %.0f Hz | Pulses : %d | PRI : %.6f s\n',...
        k,...
        PRFList(k),...
        Count,...
        1/PRFList(k));

end


disp(' ');
disp('Pulse Schedule:');

fprintf('\nPulse     PRF(Hz)       PRI(s)       Time(s)       Group\n');

fprintf( ...
    '---------------------------------------------------------\n');

for p = 1:NumPulses

    fprintf( ...
        '%3d     %8.0f     %10.6f     %10.6f       %d\n',...
        p,...
        PulsePRF(p),...
        PulsePRI(p),...
        PulseTime(p),...
        PulseGroup(p));

end

end