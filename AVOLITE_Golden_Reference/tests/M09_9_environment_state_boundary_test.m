clc;
clear;
close all;

addpath(genpath( ...
    'C:\Users\ABHI\AVOLITE\AVOLITE_Golden_Reference'));

clear calculate_environment_state;
rehash;

%% ============================================================
% CONFIGURATION
% =============================================================

cfg = config_AVOLITE();

sampleRate_Hz = ...
    cfg.receiver.adcSampleRate_Hz;

numberOfSamples = 4096;

signalFrequency_Hz = 5e6;

signalAmplitude = 0.25;

noiseAmplitude = 0.025;

rng(cfg.random.seed);

%% ============================================================
% FUNCTION RESOLUTION
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.9 ENVIRONMENT-STATE BOUNDARY VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

resolvedFunction = which( ...
    'calculate_environment_state');

fprintf('Resolved function:\n');
fprintf('%s\n', resolvedFunction);

%% ============================================================
% CREATE VALID REFERENCE INPUT
% =============================================================

n = (0:numberOfSamples-1).';

signal = ...
    signalAmplitude .* ...
    exp(1j * ...
    2*pi*signalFrequency_Hz/sampleRate_Hz .* n);

noise = ...
    sqrt(noiseAmplitude^2 / 2) .* ...
    ( ...
        randn(numberOfSamples,1) + ...
        1j * randn(numberOfSamples,1) ...
    );

xValid = signal + noise;

[spectrumValid, ~] = ...
    compute_fft_spectrum( ...
        xValid, ...
        sampleRate_Hz, ...
        cfg);

[detectionValid, ~] = ...
    apply_cfar_detection( ...
        spectrumValid, ...
        cfg);

%% ============================================================
% TEST DEFINITIONS
% =============================================================

testNames = { ...
    'Empty signal'
    'Zero sample rate'
    'Negative sample rate'
    'Missing spectrum frequency'
    'Missing spectrum magnitude'
    'Missing detection mask'
    'Missing detection noise estimate'
    'Invalid cfg type'};

expectedIdentifiers = { ...
    'calculate_environment_state:InvalidSignal'
    'calculate_environment_state:InvalidSampleRate'
    'calculate_environment_state:InvalidSampleRate'
    'calculate_environment_state:MissingSpectrumField'
    'calculate_environment_state:MissingSpectrumField'
    'calculate_environment_state:MissingDetectionField'
    'calculate_environment_state:MissingDetectionField'
    'calculate_environment_state:InvalidConfiguration'};

numberOfTests = numel(testNames);

testPass = false(numberOfTests,1);

%% ============================================================
% TEST 1 — EMPTY SIGNAL
% =============================================================

try

    calculate_environment_state( ...
        zeros(0,1), ...
        sampleRate_Hz, ...
        spectrumValid, ...
        detectionValid, ...
        cfg);

catch ME

    testPass(1) = ...
        strcmp(ME.identifier, expectedIdentifiers{1});

    fprintf('\nM09.9.1 Empty signal rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 2 — ZERO SAMPLE RATE
% =============================================================

try

    calculate_environment_state( ...
        xValid, ...
        0, ...
        spectrumValid, ...
        detectionValid, ...
        cfg);

catch ME

    testPass(2) = ...
        strcmp(ME.identifier, expectedIdentifiers{2});

    fprintf('\nM09.9.2 Zero sample rate rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 3 — NEGATIVE SAMPLE RATE
% =============================================================

try

    calculate_environment_state( ...
        xValid, ...
        -sampleRate_Hz, ...
        spectrumValid, ...
        detectionValid, ...
        cfg);

catch ME

    testPass(3) = ...
        strcmp(ME.identifier, expectedIdentifiers{3});

    fprintf('\nM09.9.3 Negative sample rate rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 4 — MISSING SPECTRUM FREQUENCY
% =============================================================

spectrumBad = spectrumValid;

spectrumBad = rmfield( ...
    spectrumBad, ...
    'frequency_Hz');

try

    calculate_environment_state( ...
        xValid, ...
        sampleRate_Hz, ...
        spectrumBad, ...
        detectionValid, ...
        cfg);

catch ME

    testPass(4) = ...
        strcmp(ME.identifier, expectedIdentifiers{4});

    fprintf('\nM09.9.4 Missing spectrum frequency rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 5 — MISSING SPECTRUM MAGNITUDE
% =============================================================

spectrumBad = spectrumValid;

spectrumBad = rmfield( ...
    spectrumBad, ...
    'magnitude');

try

    calculate_environment_state( ...
        xValid, ...
        sampleRate_Hz, ...
        spectrumBad, ...
        detectionValid, ...
        cfg);

catch ME

    testPass(5) = ...
        strcmp(ME.identifier, expectedIdentifiers{5});

    fprintf('\nM09.9.5 Missing spectrum magnitude rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 6 — MISSING DETECTION MASK
% =============================================================

detectionBad = detectionValid;

detectionBad = rmfield( ...
    detectionBad, ...
    'mask');

try

    calculate_environment_state( ...
        xValid, ...
        sampleRate_Hz, ...
        spectrumValid, ...
        detectionBad, ...
        cfg);

catch ME

    testPass(6) = ...
        strcmp(ME.identifier, expectedIdentifiers{6});

    fprintf('\nM09.9.6 Missing detection mask rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 7 — MISSING DETECTION NOISE ESTIMATE
% =============================================================

detectionBad = detectionValid;

detectionBad = rmfield( ...
    detectionBad, ...
    'noisePowerEstimate');

try

    calculate_environment_state( ...
        xValid, ...
        sampleRate_Hz, ...
        spectrumValid, ...
        detectionBad, ...
        cfg);

catch ME

    testPass(7) = ...
        strcmp(ME.identifier, expectedIdentifiers{7});

    fprintf('\nM09.9.7 Missing detection noise estimate rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% TEST 8 — INVALID CONFIGURATION TYPE
% =============================================================

cfgBad = [];

try

    calculate_environment_state( ...
        xValid, ...
        sampleRate_Hz, ...
        spectrumValid, ...
        detectionValid, ...
        cfgBad);

catch ME

    testPass(8) = ...
        strcmp(ME.identifier, expectedIdentifiers{8});

    fprintf('\nM09.9.8 Invalid configuration rejected:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% NAN CHARACTERIZATION
% =============================================================

xNaN = xValid;

xNaN(100) = NaN;

nanAccepted = false;

nanReceivedPower = NaN;

try

    [nanState, ~] = ...
        calculate_environment_state( ...
            xNaN, ...
            sampleRate_Hz, ...
            spectrumValid, ...
            detectionValid, ...
            cfg);

    nanAccepted = true;

    nanReceivedPower = ...
        nanState.receivedPower_W;

catch ME

    fprintf('\nM09.9.NaN NaN-input behavior:\n');
    fprintf('    Rejected: %s\n', ME.message);

end

%% ============================================================
% INF CHARACTERIZATION
% =============================================================

xInf = xValid;

xInf(100) = Inf;

infAccepted = false;

infReceivedPower = NaN;

try

    [infState, ~] = ...
        calculate_environment_state( ...
            xInf, ...
            sampleRate_Hz, ...
            spectrumValid, ...
            detectionValid, ...
            cfg);

    infAccepted = true;

    infReceivedPower = ...
        infState.receivedPower_W;

catch ME

    fprintf('\nM09.9.Inf Inf-input behavior:\n');
    fprintf('    Rejected: %s\n', ME.message);

end

%% ============================================================
% VALID-INPUT CONTROL TEST
% =============================================================

validInputPass = false;

try

    [environmentStateValid, infoValid] = ...
        calculate_environment_state( ...
            xValid, ...
            sampleRate_Hz, ...
            spectrumValid, ...
            detectionValid, ...
            cfg);

    validInputPass = ...
        isstruct(environmentStateValid) && ...
        isstruct(infoValid);

catch ME

    fprintf('\nValid-input control error:\n');
    fprintf('    %s\n', ME.message);

end

%% ============================================================
% HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.9 ENVIRONMENT-STATE BOUNDARY VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Resolved function:\n');
fprintf('%s\n', resolvedFunction);

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('Reference samples = %d\n', ...
    numberOfSamples);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf('%-45s %10s\n', ...
    'Boundary condition', ...
    'Result');

fprintf('%s\n', ...
    repmat('-',1,60));

for k = 1:numberOfTests

    fprintf('%-45s %10s\n', ...
        testNames{k}, ...
        passFailText(testPass(k)));

end

%% ============================================================
% NAN / INF CHARACTERIZATION
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('NON-FINITE INPUT CHARACTERIZATION\n');
fprintf('============================================================\n');

fprintf('\n');

if nanAccepted

    fprintf('NaN signal behavior = ACCEPTED\n');
    fprintf('NaN received power  = %s\n', ...
        valueText(nanReceivedPower));

else

    fprintf('NaN signal behavior = REJECTED\n');

end

fprintf('\n');

if infAccepted

    fprintf('Inf signal behavior = ACCEPTED\n');
    fprintf('Inf received power  = %s\n', ...
        valueText(infReceivedPower));

else

    fprintf('Inf signal behavior = REJECTED\n');

end

fprintf('\n');

fprintf(['NaN/Inf behavior is characterized separately because ', ...
         'the current Golden Reference implementation does not ', ...
         'explicitly require finite signal samples.\n']);

%% ============================================================
% VALID CONTROL RESULT
% =============================================================

fprintf('\n');

fprintf('Valid-input control case = %s\n', ...
    passFailText(validInputPass));

%% ============================================================
% SUMMARY
% =============================================================

mandatoryBoundaryPass = ...
    all(testPass);

fprintf('\n');

fprintf('============================================================\n');
fprintf('BOUNDARY-TEST INTERPRETATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf(['The mandatory boundary checks verify the input-validation ', ...
         'behavior explicitly implemented by ', ...
         'calculate_environment_state.\n']);

fprintf('\n');

fprintf(['NaN and Inf signal behavior are reported separately and ', ...
         'are not counted as mandatory boundary failures.\n']);

fprintf('\n');

fprintf(['The configuration test uses a non-structure cfg as the ', ...
         'invalid configuration case. Removing an optional ', ...
         'configuration field is not treated as invalid because ', ...
         'the current function does not require that field.\n']);

fprintf('\n');

fprintf(['The valid-input control confirms that boundary testing ', ...
         'has not broken the normal interface.\n']);

%% ============================================================
% FINAL RESULT
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.9 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Mandatory boundary validation = %s\n', ...
    passFailText(mandatoryBoundaryPass));

fprintf('Valid-input control           = %s\n', ...
    passFailText(validInputPass));

fprintf('\n');

m09_9_pass = ...
    mandatoryBoundaryPass && ...
    validInputPass;

if m09_9_pass

    fprintf('M09.9 RESULT = PASS\n');

else

    fprintf('M09.9 RESULT = REVIEW\n');

end

fprintf('\n');

fprintf('============================================================\n');
fprintf('M09.9 ENVIRONMENT-STATE BOUNDARY VERIFICATION COMPLETE\n');
fprintf('============================================================\n');

%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function text = passFailText(value)

    if value

        text = 'PASS';

    else

        text = 'FAIL';

    end

end


function text = valueText(value)

    if isempty(value)

        text = 'empty';

    elseif isnan(value)

        text = 'NaN';

    elseif isinf(value)

        text = 'Inf';

    else

        text = sprintf('%.12e',value);

    end

end