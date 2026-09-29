%% ============================================================
% SARRS STUDIO
%
% TEST_CONFIG
%
% Purpose:
%   Validate all major SARRS configuration modules before
%   running the complete radar simulation.
%
% Configuration modules tested:
%   1. SimulationConfig
%   2. RadarConfig
%   3. ReceiverConfig
%   4. EnvironmentConfig
%   5. DisplayConfig
%   6. LoggingConfig
%
% This is a TEST SCRIPT.
% It does not modify the original configuration files.
%
% ============================================================

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('              SARRS STUDIO - CONFIG TEST\n');
fprintf('============================================================\n');

%% ============================================================
% 1. FIND PROJECT ROOT
% ============================================================

TestFolder = fileparts(mfilename('fullpath'));

% Tests folder is:
% D:\SARRS_STUDIO\04_MATLAB\Tests
%
% Therefore parent folder is:
% D:\SARRS_STUDIO\04_MATLAB

ProjectRoot = fileparts(TestFolder);

fprintf('\nProject Root:\n%s\n', ProjectRoot);

%% ============================================================
% 2. ADD PROJECT PATH
% ============================================================

addpath(genpath(ProjectRoot));

fprintf('\nProject paths added successfully.\n');

%% ============================================================
% 3. INITIALIZE TEST STATUS
% ============================================================

TotalTests = 0;
PassedTests = 0;
FailedTests = 0;

%% ============================================================
% 4. TEST SIMULATION CONFIGURATION
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 1: SIMULATION CONFIGURATION\n');
fprintf('------------------------------------------------------------\n');

try

    SimulationConfig;

    fprintf('SimulationConfig loaded successfully.\n');

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Simulation configuration loaded.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] SimulationConfig\n');
    fprintf('       %s\n', ME.message);

end

%% ============================================================
% 5. TEST RADAR CONFIGURATION
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 2: RADAR CONFIGURATION\n');
fprintf('------------------------------------------------------------\n');

try

    RadarConfigData = RadarConfig();

    fprintf('RadarConfig loaded successfully.\n');

    % Display available configuration
    disp(RadarConfigData);

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Radar configuration loaded.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] RadarConfig\n');
    fprintf('       %s\n', ME.message);

    RadarConfigData = [];

end

%% ============================================================
% 6. TEST RADAR OBJECT
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 3: RADAR MODEL\n');
fprintf('------------------------------------------------------------\n');

try

    RadarData = Radar();

    fprintf('Radar model initialized successfully.\n');

    if isfield(RadarData,'SampleRate')

        fprintf('Sample Rate       : %.3f MHz\n', ...
            RadarData.SampleRate/1e6);

    end

    if isfield(RadarData,'Bandwidth')

        fprintf('Bandwidth         : %.3f MHz\n', ...
            RadarData.Bandwidth/1e6);

    end

    if isfield(RadarData,'Gain')

        fprintf('Radar Gain        : %.2f dB\n', ...
            RadarData.Gain);

    end

    if isfield(RadarData,'Wavelength')

        fprintf('Wavelength        : %.6f m\n', ...
            RadarData.Wavelength);

    end

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Radar model initialized.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] Radar model\n');
    fprintf('       %s\n', ME.message);

    RadarData = [];

end

%% ============================================================
% 7. TEST RADAR CONFIGURATION PARAMETERS
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 4: RADAR PARAMETER VALIDATION\n');
fprintf('------------------------------------------------------------\n');

if ~isempty(RadarConfigData)

    % --------------------------------------------------------
    % Required fields
    % --------------------------------------------------------

    RequiredFields = { ...
        'Mode', ...
        'PrimaryPRF', ...
        'PRFList', ...
        'NumPRFs', ...
        'RequiredMaximumRange', ...
        'RequiredMaximumVelocity'};

    for k = 1:numel(RequiredFields)

        FieldName = RequiredFields{k};

        TotalTests = TotalTests + 1;

        if isfield(RadarConfigData,FieldName)

            PassedTests = PassedTests + 1;

            fprintf( ...
                '[PASS] RadarConfig field: %s\n', ...
                FieldName);

        else

            FailedTests = FailedTests + 1;

            fprintf( ...
                '[FAIL] Missing RadarConfig field: %s\n', ...
                FieldName);

        end

    end

    % --------------------------------------------------------
    % PRF validation
    % --------------------------------------------------------

    if isfield(RadarConfigData,'PRFList')

        TotalTests = TotalTests + 1;

        if all(RadarConfigData.PRFList > 0)

            PassedTests = PassedTests + 1;

            fprintf('[PASS] All PRF values are positive.\n');

        else

            FailedTests = FailedTests + 1;

            fprintf('[FAIL] Invalid PRF value detected.\n');

        end

    end

    % --------------------------------------------------------
    % Number of PRFs
    % --------------------------------------------------------

    if isfield(RadarConfigData,'PRFList') && ...
            isfield(RadarConfigData,'NumPRFs')

        TotalTests = TotalTests + 1;

        if numel(RadarConfigData.PRFList) == ...
                RadarConfigData.NumPRFs

            PassedTests = PassedTests + 1;

            fprintf( ...
                '[PASS] NumPRFs matches PRFList.\n');

        else

            FailedTests = FailedTests + 1;

            fprintf( ...
                '[FAIL] NumPRFs does not match PRFList.\n');

        end

    end

else

    fprintf('Radar configuration unavailable.\n');

end

%% ============================================================
% 8. CALCULATE RADAR OPERATING LIMITS
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 5: RADAR OPERATING LIMITS\n');
fprintf('------------------------------------------------------------\n');

if ~isempty(RadarConfigData) && ~isempty(RadarData)

    try

        % ----------------------------------------------------
        % Maximum unambiguous range
        % ----------------------------------------------------

        if isfield(RadarData,'c')

            RadarConfigData.MaxUnambiguousRange = ...
                RadarData.c ./ ...
                (2 .* RadarConfigData.PRFList);

        else

            % Standard speed of light fallback
            c = 299792458;

            RadarConfigData.MaxUnambiguousRange = ...
                c ./ ...
                (2 .* RadarConfigData.PRFList);

        end

        % ----------------------------------------------------
        % Maximum unambiguous velocity
        % ----------------------------------------------------

        if isfield(RadarData,'Wavelength')

            RadarConfigData.MaxUnambiguousVelocity = ...
                RadarData.Wavelength .* ...
                RadarConfigData.PRFList ./ 4;

        end

        fprintf('\nMulti-PRF Operating Limits:\n');

        for k = 1:numel(RadarConfigData.PRFList)

            fprintf( ...
                'PRF %d : %.2f Hz | Range = %.3f km | Vmax = +/- %.3f m/s\n', ...
                k, ...
                RadarConfigData.PRFList(k), ...
                RadarConfigData.MaxUnambiguousRange(k)/1000, ...
                RadarConfigData.MaxUnambiguousVelocity(k));

        end

        TotalTests = TotalTests + 1;
        PassedTests = PassedTests + 1;

        fprintf('\n[PASS] Radar operating limits calculated.\n');

    catch ME

        TotalTests = TotalTests + 1;
        FailedTests = FailedTests + 1;

        fprintf('[FAIL] Radar operating limit calculation.\n');
        fprintf('       %s\n', ME.message);

    end

end

%% ============================================================
% 9. TEST RECEIVER CONFIGURATION
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 6: RECEIVER CONFIGURATION\n');
fprintf('------------------------------------------------------------\n');

try

    ReceiverConfig;

    fprintf('ReceiverConfig loaded successfully.\n');

    % If a variable named Receiver exists,
    % display important receiver parameters.

    if exist('Receiver','var')

        if isstruct(Receiver)

            if isfield(Receiver,'LNAGain')

                fprintf( ...
                    'LNA Gain          : %.2f dB\n', ...
                    Receiver.LNAGain);

            end

            if isfield(Receiver,'NoiseFigure')

                fprintf( ...
                    'Noise Figure      : %.2f dB\n', ...
                    Receiver.NoiseFigure);

            end

            if isfield(Receiver,'IFGain')

                fprintf( ...
                    'IF Gain            : %.2f dB\n', ...
                    Receiver.IFGain);

            end

            if isfield(Receiver,'TotalGain')

                fprintf( ...
                    'Total Gain         : %.2f dB\n', ...
                    Receiver.TotalGain);

            end

        end

    end

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Receiver configuration loaded.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] ReceiverConfig\n');
    fprintf('       %s\n', ME.message);

end

%% ============================================================
% 10. TEST ENVIRONMENT CONFIGURATION
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 7: ENVIRONMENT CONFIGURATION\n');
fprintf('------------------------------------------------------------\n');

try

    EnvironmentConfig;

    fprintf('EnvironmentConfig loaded successfully.\n');

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Environment configuration loaded.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] EnvironmentConfig\n');
    fprintf('       %s\n', ME.message);

end

%% ============================================================
% 11. TEST DISPLAY CONFIGURATION
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 8: DISPLAY CONFIGURATION\n');
fprintf('------------------------------------------------------------\n');

try

    DisplayConfig;

    fprintf('DisplayConfig loaded successfully.\n');

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Display configuration loaded.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] DisplayConfig\n');
    fprintf('       %s\n', ME.message);

end

%% ============================================================
% 12. TEST LOGGING CONFIGURATION
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 9: LOGGING CONFIGURATION\n');
fprintf('------------------------------------------------------------\n');

try

    LoggingConfig;

    fprintf('LoggingConfig loaded successfully.\n');

    TotalTests = TotalTests + 1;
    PassedTests = PassedTests + 1;

    fprintf('[PASS] Logging configuration loaded.\n');

catch ME

    TotalTests = TotalTests + 1;
    FailedTests = FailedTests + 1;

    fprintf('[FAIL] LoggingConfig\n');
    fprintf('       %s\n', ME.message);

end

%% ============================================================
% 13. TEST BASIC PHYSICAL PARAMETERS
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('TEST 10: PHYSICAL PARAMETER SANITY CHECK\n');
fprintf('------------------------------------------------------------\n');

if ~isempty(RadarData)

    % --------------------------------------------------------
    % Sample rate
    % --------------------------------------------------------

    if isfield(RadarData,'SampleRate')

        TotalTests = TotalTests + 1;

        if RadarData.SampleRate > 0

            PassedTests = PassedTests + 1;

            fprintf( ...
                '[PASS] Sample rate = %.3f MHz\n', ...
                RadarData.SampleRate/1e6);

        else

            FailedTests = FailedTests + 1;

            fprintf('[FAIL] Invalid sample rate.\n');

        end

    end

    % --------------------------------------------------------
    % Bandwidth
    % --------------------------------------------------------

    if isfield(RadarData,'Bandwidth')

        TotalTests = TotalTests + 1;

        if RadarData.Bandwidth > 0

            PassedTests = PassedTests + 1;

            fprintf( ...
                '[PASS] Bandwidth = %.3f MHz\n', ...
                RadarData.Bandwidth/1e6);

        else

            FailedTests = FailedTests + 1;

            fprintf('[FAIL] Invalid bandwidth.\n');

        end

    end

    % --------------------------------------------------------
    % Wavelength
    % --------------------------------------------------------

    if isfield(RadarData,'Wavelength')

        TotalTests = TotalTests + 1;

        if RadarData.Wavelength > 0

            PassedTests = PassedTests + 1;

            fprintf( ...
                '[PASS] Wavelength = %.6f m\n', ...
                RadarData.Wavelength);

        else

            FailedTests = FailedTests + 1;

            fprintf('[FAIL] Invalid wavelength.\n');

        end

    end

end

%% ============================================================
% 14. FINAL TEST SUMMARY
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('                  CONFIG TEST SUMMARY\n');
fprintf('============================================================\n');

fprintf('Total Tests       : %d\n', TotalTests);
fprintf('Passed Tests      : %d\n', PassedTests);
fprintf('Failed Tests      : %d\n', FailedTests);

if TotalTests > 0

    PassPercentage = ...
        100 * PassedTests / TotalTests;

    fprintf('Pass Percentage   : %.2f %%\n', ...
        PassPercentage);

end

fprintf('============================================================\n');

%% ============================================================
% FINAL STATUS
% ============================================================

if FailedTests == 0

    fprintf('\n');
    fprintf('*** CONFIGURATION TEST PASSED ***\n');
    fprintf('All tested configuration modules are operational.\n');
    fprintf('SARRS configuration is ready for simulation.\n');
    fprintf('\n');

else

    fprintf('\n');
    fprintf('*** CONFIGURATION TEST FAILED ***\n');
    fprintf('%d test(s) require attention.\n', FailedTests);
    fprintf('\n');

end

fprintf('============================================================\n');
fprintf('              END OF TEST_CONFIG\n');
fprintf('============================================================\n');