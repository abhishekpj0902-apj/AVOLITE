clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

sampleRate_Hz = ...
    cfg.receiver.adcSampleRate_Hz;

numberOfSamples = 4096;

signalFrequency_Hz = 5e6;

noiseAmplitude = 0.025;

signalAmplitude = 0.250;

rng(cfg.random.seed);

%% ============================================================
% CASE 1 — NOISE ONLY
% =============================================================

n = (0:numberOfSamples-1).';

noiseOnly = ...
    sqrt(noiseAmplitude^2 / 2) .* ...
    ( ...
        randn(numberOfSamples,1) + ...
        1j * randn(numberOfSamples,1) ...
    );

%% ============================================================
% CASE 2 — SIGNAL + NOISE
% =============================================================

signal = ...
    signalAmplitude .* ...
    exp(1j * ...
    2*pi*signalFrequency_Hz/sampleRate_Hz .* n);

signalPlusNoise = ...
    signal + noiseOnly;

%% ============================================================
% PROCESS NOISE-ONLY CASE
% =============================================================

[spectrumNoise, ~] = ...
    compute_fft_spectrum( ...
        noiseOnly, ...
        sampleRate_Hz, ...
        cfg);

[detectionNoise, cfarInfoNoise] = ...
    apply_cfar_detection( ...
        spectrumNoise, ...
        cfg);

[environmentNoise, infoNoise] = ...
    calculate_environment_state( ...
        noiseOnly, ...
        sampleRate_Hz, ...
        spectrumNoise, ...
        detectionNoise, ...
        cfg);

%% ============================================================
% PROCESS SIGNAL+NOISE CASE
% =============================================================

[spectrumSignal, ~] = ...
    compute_fft_spectrum( ...
        signalPlusNoise, ...
        sampleRate_Hz, ...
        cfg);

[detectionSignal, cfarInfoSignal] = ...
    apply_cfar_detection( ...
        spectrumSignal, ...
        cfg);

[environmentSignal, infoSignal] = ...
    calculate_environment_state( ...
        signalPlusNoise, ...
        sampleRate_Hz, ...
        spectrumSignal, ...
        detectionSignal, ...
        cfg);

%% ============================================================
% EXPECTED CONFIGURATION
% =============================================================

configuredPfa = ...
    cfg.detection.probabilityOfFalseAlarm;

%% ============================================================
% EXTRACT FALSE-ALARM FIELDS
% =============================================================

falseAlarmNoise = ...
    environmentNoise.falseAlarmRate;

falseAlarmSignal = ...
    environmentSignal.falseAlarmRate;

groundTruthNoise = ...
    infoNoise.groundTruthUsed;

groundTruthSignal = ...
    infoSignal.groundTruthUsed;

%% ============================================================
% PRINT HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.8 FALSE-ALARM-RATE / GROUND-TRUTH HANDLING\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('Samples            = %d\n', ...
    numberOfSamples);

fprintf('Configured CFAR Pfa = %.12e\n', ...
    configuredPfa);

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');

fprintf('CASE                         FALSE ALARM RATE     GROUND TRUTH\n');
fprintf('----------------------------------------------------------------\n');

fprintf('Noise only                   %18s     %12d\n', ...
    formatNaN(falseAlarmNoise), ...
    groundTruthNoise);

fprintf('Signal + noise               %18s     %12d\n', ...
    formatNaN(falseAlarmSignal), ...
    groundTruthSignal);

%% ============================================================
% DETECTION COUNTS
% =============================================================

fprintf('\n');

fprintf('Noise-only detected bins     = %d\n', ...
    sum(detectionNoise.mask));

fprintf('Signal+noise detected bins   = %d\n', ...
    sum(detectionSignal.mask));

fprintf('Noise-only valid CUTs        = %d\n', ...
    cfarInfoNoise.validCUTCount);

fprintf('Signal+noise valid CUTs      = %d\n', ...
    cfarInfoSignal.validCUTCount);

%% ============================================================
% CHECK 1 — FALSE ALARM UNAVAILABLE
% =============================================================

falseAlarmUnavailablePass = ...
    isnan(falseAlarmNoise) && ...
    isnan(falseAlarmSignal);

%% ============================================================
% CHECK 2 — GROUND TRUTH NOT USED
% =============================================================

groundTruthIsolationPass = ...
    ~groundTruthNoise && ...
    ~groundTruthSignal;

%% ============================================================
% CHECK 3 — CONFIGURED PFA PRESERVED
% =============================================================

configuredPfaPass = ...
    isfield(infoNoise, 'configuredCFAR_Pfa') && ...
    isfield(infoSignal, 'configuredCFAR_Pfa') && ...
    infoNoise.configuredCFAR_Pfa == configuredPfa && ...
    infoSignal.configuredCFAR_Pfa == configuredPfa;

%% ============================================================
% CHECK 4 — PFA IS NOT FALSE-ALARM MEASUREMENT
% =============================================================

pfaSeparationPass = ...
    isnan(falseAlarmNoise) && ...
    isnan(falseAlarmSignal) && ...
    isfinite(configuredPfa);

%% ============================================================
% PRINT CHECKS
% =============================================================

fprintf('\n');

fprintf('False-alarm unavailable without ground truth = %s\n', ...
    passFailText(falseAlarmUnavailablePass));

fprintf('Ground-truth isolation                       = %s\n', ...
    passFailText(groundTruthIsolationPass));

fprintf('Configured CFAR Pfa preserved                = %s\n', ...
    passFailText(configuredPfaPass));

fprintf('Pfa / measured false-alarm separation        = %s\n', ...
    passFailText(pfaSeparationPass));

%% ============================================================
% DOMAIN INTERPRETATION
% =============================================================

fprintf('\n');

fprintf('============================================================\n');
fprintf('FALSE-ALARM DOMAIN INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['Configured CFAR Pfa is a detector design parameter. ', ...
         'It is not treated as a measured false-alarm rate.\n']);

fprintf('\n');

fprintf(['A measured false-alarm rate requires appropriate ', ...
         'target-absent opportunities and ground-truth ', ...
         'labeling.\n']);

fprintf('\n');

fprintf(['Because this test does not provide target labels, ', ...
         'environmentState.falseAlarmRate must remain NaN.\n']);

fprintf('\n');

fprintf(['groundTruthUsed must remain false so the environment ', ...
         'state does not silently claim unavailable ground truth.\n']);

%% ============================================================
% FINAL RESULT
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.8 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

overallPass = ...
    falseAlarmUnavailablePass && ...
    groundTruthIsolationPass && ...
    configuredPfaPass && ...
    pfaSeparationPass;

fprintf('\n');

fprintf('False-alarm availability handling = %s\n', ...
    passFailText(falseAlarmUnavailablePass));

fprintf('Ground-truth isolation            = %s\n', ...
    passFailText(groundTruthIsolationPass));

fprintf('Configured Pfa preservation       = %s\n', ...
    passFailText(configuredPfaPass));

fprintf('Pfa / measured-rate separation    = %s\n', ...
    passFailText(pfaSeparationPass));

fprintf('\n');

if overallPass

    fprintf('M09.8 RESULT = PASS\n');

else

    fprintf('M09.8 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.8 FALSE-ALARM / GROUND-TRUTH VERIFICATION COMPLETE\n');
fprintf('============================================================\n');

%% ============================================================
% LOCAL FUNCTIONS
% =============================================================

function text = passFailText(value)

    if value
        text = 'PASS';
    else
        text = 'FAIL';
    end

end

function text = formatNaN(value)

    if isnan(value)
        text = 'NaN';
    else
        text = sprintf('%.12f', value);
    end

end