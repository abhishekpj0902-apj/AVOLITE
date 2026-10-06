function [pulseEvents, info] = extract_temporal_pulses( ...
    x, sampleRate_Hz, cfg, varargin)
%EXTRACT_TEMPORAL_PULSES Detect temporal pulse events.
%
% AVOLITE Golden Reference
%
% Inputs:
%   x               : complex or real time-domain signal
%   sampleRate_Hz   : sample rate [Hz]
%   cfg             : AVOLITE configuration
%
% Optional:
%   varargin{1}     : observation start time [s]
%
% Outputs:
%   pulseEvents     : detected temporal pulse events
%   info            : extraction diagnostics
%
% Output fields:
%   pulseID
%   startSample
%   endSample
%   ToA_s
%   pulseWidth_s
%   amplitude
%   PRI_s
%
% Detection method:
%   magnitude envelope + configurable relative threshold.
%
% This is a Golden Reference temporal detector.
% It deliberately does not use emitter ground truth.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(x) || isempty(x)

    error( ...
        'extract_temporal_pulses:InvalidSignal', ...
        'x must be a non-empty numeric signal.');

end

if ~isscalar(sampleRate_Hz) || ...
        ~isnumeric(sampleRate_Hz) || ...
        ~isfinite(sampleRate_Hz) || ...
        sampleRate_Hz <= 0

    error( ...
        'extract_temporal_pulses:InvalidSampleRate', ...
        'sampleRate_Hz must be positive and finite.');

end

if ~isstruct(cfg)

    error( ...
        'extract_temporal_pulses:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% OBSERVATION START TIME
% =============================================================

observationStartTime_s = 0;

if ~isempty(varargin)

    observationStartTime_s = varargin{1};

    if ~isscalar(observationStartTime_s) || ...
            ~isnumeric(observationStartTime_s) || ...
            ~isfinite(observationStartTime_s)

        error( ...
            'extract_temporal_pulses:InvalidStartTime', ...
            'Observation start time must be finite.');

    end

end

%% ============================================================
% COLUMN VECTOR
% =============================================================

x = x(:);

N = numel(x);

%% ============================================================
% MAGNITUDE ENVELOPE
% =============================================================

envelope = abs(x);

%% ============================================================
% PEAK AMPLITUDE
% ============================================================

peakAmplitude = max(envelope);

%% ============================================================
% ZERO-SIGNAL CASE
% ============================================================

if peakAmplitude <= 0

    pulseEvents = struct( ...
        'pulseID', {}, ...
        'startSample', {}, ...
        'endSample', {}, ...
        'ToA_s', {}, ...
        'pulseWidth_s', {}, ...
        'amplitude', {}, ...
        'PRI_s', {});

    info = struct();

    info.numberOfPulses = 0;

    info.threshold = 0;

    info.thresholdFraction = NaN;

    info.peakAmplitude = 0;

    info.sampleRate_Hz = ...
        sampleRate_Hz;

    info.samplePeriod_s = ...
        1 / sampleRate_Hz;

    info.observationStartTime_s = ...
        observationStartTime_s;

    info.signalLength_samples = ...
        N;

    info.PRIAvailable = false;

    return;

end

%% ============================================================
% DETECTION THRESHOLD
% ============================================================
%
% The threshold is defined relative to the observed peak.
%
% Default:
%       0.5 * peak amplitude
%
% This corresponds to a -6 dB amplitude threshold.

thresholdFraction = 0.5;

if isfield(cfg,'pdw') && ...
        isfield(cfg.pdw,'temporalThresholdFraction')

    thresholdFraction = ...
        cfg.pdw.temporalThresholdFraction;

end

if ~isscalar(thresholdFraction) || ...
        ~isnumeric(thresholdFraction) || ...
        ~isfinite(thresholdFraction) || ...
        thresholdFraction <= 0 || ...
        thresholdFraction >= 1

    error( ...
        'extract_temporal_pulses:InvalidThreshold', ...
        ['Temporal threshold fraction must be ' ...
         'greater than 0 and less than 1.']);

end

threshold = ...
    thresholdFraction * peakAmplitude;

%% ============================================================
% BINARY PULSE MASK
% =============================================================

pulseMask = ...
    envelope >= threshold;

%% ============================================================
% FIND RISING/FALLING EDGES
% ============================================================

maskPadded = ...
    [false; pulseMask; false];

edgeDifference = ...
    diff(double(maskPadded));

startIndices = ...
    find(edgeDifference == 1);

endIndices = ...
    find(edgeDifference == -1) - 1;

if numel(startIndices) ~= ...
        numel(endIndices)

    error( ...
        'extract_temporal_pulses:EdgeMismatch', ...
        'Pulse start/end edge mismatch.');

end

numberOfPulses = ...
    numel(startIndices);

%% ============================================================
% PREALLOCATE
% ============================================================

pulseID = ...
    (1:numberOfPulses).';

startSample = ...
    startIndices;

endSample = ...
    endIndices;

%% ============================================================
% TIME OF ARRIVAL
% ============================================================

ToA_s = ...
    observationStartTime_s + ...
    (startSample - 1) / sampleRate_Hz;

%% ============================================================
% PULSE WIDTH
% ============================================================

pulseWidth_s = ...
    (endSample - startSample + 1) / ...
    sampleRate_Hz;

%% ============================================================
% AMPLITUDE
% ============================================================

amplitude = ...
    zeros(numberOfPulses,1);

for k = 1:numberOfPulses

    pulseSamples = ...
        envelope( ...
            startSample(k):endSample(k));

    amplitude(k) = ...
        max(pulseSamples);

end

%% ============================================================
% PRI
% ============================================================
%
% PRI is the difference between consecutive pulse ToAs.
%
% The first pulse has no preceding pulse, therefore:
%
%   PRI_s(1) = NaN
%
% and:
%
%   PRI_s(k) = ToA_s(k) - ToA_s(k-1)

PRI_s = ...
    nan(numberOfPulses,1);

if numberOfPulses >= 2

    ToA_difference_s = ...
        diff(ToA_s);

    PRI_s(2:end) = ...
        ToA_difference_s;

end

%% ============================================================
% OUTPUT STRUCTURE
% =============================================================

pulseEvents = struct();

pulseEvents.pulseID = ...
    pulseID;

pulseEvents.startSample = ...
    startSample;

pulseEvents.endSample = ...
    endSample;

pulseEvents.ToA_s = ...
    ToA_s;

pulseEvents.pulseWidth_s = ...
    pulseWidth_s;

pulseEvents.amplitude = ...
    amplitude;

pulseEvents.PRI_s = ...
    PRI_s;

%% ============================================================
% DIAGNOSTICS
% ============================================================

info = struct();

info.numberOfPulses = ...
    numberOfPulses;

info.threshold = ...
    threshold;

info.thresholdFraction = ...
    thresholdFraction;

info.peakAmplitude = ...
    peakAmplitude;

info.sampleRate_Hz = ...
    sampleRate_Hz;

info.samplePeriod_s = ...
    1 / sampleRate_Hz;

info.observationStartTime_s = ...
    observationStartTime_s;

info.signalLength_samples = ...
    N;

info.PRIAvailable = ...
    numberOfPulses >= 2;

end