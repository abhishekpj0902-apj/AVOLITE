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

%% ============================================================
% TEST PARAMETERS
% =============================================================

amplitudes = [ ...
    0.01 ...
    0.05 ...
    0.10 ...
    0.25 ...
    0.50];

frequencies_Hz = [ ...
    1e6 ...
    5e6 ...
    10e6];

numberOfSamples = 4096;

numberOfAmplitudes = ...
    numel(amplitudes);

numberOfFrequencies = ...
    numel(frequencies_Hz);

measuredPower_W = ...
    zeros(numberOfAmplitudes, numberOfFrequencies);

expectedPower_W = ...
    zeros(numberOfAmplitudes, numberOfFrequencies);

powerError_W = ...
    zeros(numberOfAmplitudes, numberOfFrequencies);

relativePowerError = ...
    zeros(numberOfAmplitudes, numberOfFrequencies);

%% ============================================================
% TEST LOOP
% =============================================================

for amplitudeCase = 1:numberOfAmplitudes

    amplitude = ...
        amplitudes(amplitudeCase);

    for frequencyCase = 1:numberOfFrequencies

        frequency_Hz = ...
            frequencies_Hz(frequencyCase);

        n = ...
            (0:numberOfSamples-1).';

        x = ...
            amplitude .* ...
            exp(1j * ...
            2*pi*frequency_Hz/sampleRate_Hz .* n);

        %% ----------------------------------------------------
        % FFT
        % -----------------------------------------------------

        [spectrum, ~] = ...
            compute_fft_spectrum( ...
                x, ...
                sampleRate_Hz, ...
                cfg);

        %% ----------------------------------------------------
        % CFAR
        % -----------------------------------------------------

        [detection, ~] = ...
            apply_cfar_detection( ...
                spectrum, ...
                cfg);

        %% ----------------------------------------------------
        % ENVIRONMENT STATE
        % -----------------------------------------------------

        [environmentState, ~] = ...
            calculate_environment_state( ...
                x, ...
                sampleRate_Hz, ...
                spectrum, ...
                detection, ...
                cfg);

        %% ----------------------------------------------------
        % REFERENCE POWER
        % -----------------------------------------------------

        expectedPower = ...
            amplitude^2;

        measuredPower = ...
            environmentState.receivedPower_W;

        %% ----------------------------------------------------
        % ERRORS
        % -----------------------------------------------------

        absoluteError = ...
            measuredPower - expectedPower;

        relativeError = ...
            absoluteError / expectedPower;

        %% ----------------------------------------------------
        % STORE
        % -----------------------------------------------------

        expectedPower_W( ...
            amplitudeCase, frequencyCase) = ...
            expectedPower;

        measuredPower_W( ...
            amplitudeCase, frequencyCase) = ...
            measuredPower;

        powerError_W( ...
            amplitudeCase, frequencyCase) = ...
            absoluteError;

        relativePowerError( ...
            amplitudeCase, frequencyCase) = ...
            relativeError;

    end

end

%% ============================================================
% PRINT HEADER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.2 RECEIVED-POWER VERIFICATION\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Sample rate       = %.6f MHz\n', ...
    sampleRate_Hz / 1e6);

fprintf('Samples per case  = %d\n', ...
    numberOfSamples);

%% ============================================================
% RESULTS TABLE
% =============================================================

fprintf('\n');

fprintf( ...
    '%10s %12s %20s %20s %20s\n', ...
    'Amplitude', ...
    'Frequency', ...
    'Expected [W]', ...
    'Measured [W]', ...
    'Relative Error');

fprintf('%s\n', ...
    repmat('-', 1, 90));

for amplitudeCase = 1:numberOfAmplitudes

    for frequencyCase = 1:numberOfFrequencies

        fprintf( ...
            '%10.4f %12.3f %20.12e %20.12e %19.6e\n', ...
            amplitudes(amplitudeCase), ...
            frequencies_Hz(frequencyCase) / 1e6, ...
            expectedPower_W(amplitudeCase, frequencyCase), ...
            measuredPower_W(amplitudeCase, frequencyCase), ...
            relativePowerError(amplitudeCase, frequencyCase));

    end

    fprintf('%s\n', ...
        repmat('-', 1, 90));

end

%% ============================================================
% MAXIMUM ERROR
% =============================================================

maximumAbsoluteError_W = ...
    max(abs(powerError_W(:)));

maximumRelativeError = ...
    max(abs(relativePowerError(:)));

fprintf('\n');

fprintf('Maximum absolute power error = %.12e W\n', ...
    maximumAbsoluteError_W);

fprintf('Maximum relative power error = %.12e\n', ...
    maximumRelativeError);

fprintf('Maximum relative power error = %.9f %%\n', ...
    100 * maximumRelativeError);

%% ============================================================
% MONOTONICITY CHECK
% =============================================================

monotonicityPass = true;

for frequencyCase = 1:numberOfFrequencies

    measuredColumn = ...
        measuredPower_W(:, frequencyCase);

    if any(diff(measuredColumn) < 0)

        monotonicityPass = false;

    end

end

%% ============================================================
% REFERENCE RELATIONSHIP CHECK
% =============================================================

expectedRelationship = ...
    amplitudes(:).^2;

relationshipPass = true;

for frequencyCase = 1:numberOfFrequencies

    measuredColumn = ...
        measuredPower_W(:, frequencyCase);

    referenceColumn = ...
        expectedRelationship;

    relativeColumnError = ...
        abs(measuredColumn - referenceColumn) ./ ...
        referenceColumn;

    if any(relativeColumnError > 1e-12)

        relationshipPass = false;

    end

end

%% ============================================================
% RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.2 VERIFICATION RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Power monotonicity       = %s\n', ...
    passFailText(monotonicityPass));

fprintf('Amplitude^2 relationship = %s\n', ...
    passFailText(relationshipPass));

fprintf('\n');

%% ============================================================
% OVERALL RESULT
% =============================================================

overallPass = ...
    monotonicityPass && ...
    relationshipPass;

if overallPass

    fprintf('M09.2 RESULT = PASS');

else

    fprintf('M09.2 RESULT = REVIEW');

end

fprintf('\n');

fprintf('\n');
fprintf('============================================================\n');
fprintf('M09.2 RECEIVED-POWER VERIFICATION COMPLETE\n');
fprintf('============================================================\n');

%% ============================================================
% LOCAL FUNCTION
% =============================================================

function text = passFailText(value)

    if value

        text = 'PASS';

    else

        text = 'FAIL';

    end

end