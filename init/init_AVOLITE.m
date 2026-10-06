%% AVOLITE - Project Initialization
% Self-Adaptive Reconfigurable RF Receiver
% Environment-Aware Intelligent Scan Scheduling

clear;
clc;

%% Project Root
projectRoot = fileparts(fileparts(mfilename('fullpath')));

%% Add project directories to MATLAB path
addpath(genpath(fullfile(projectRoot, 'config')));
addpath(genpath(fullfile(projectRoot, 'init')));
addpath(genpath(fullfile(projectRoot, 'matlab')));
addpath(genpath(fullfile(projectRoot, 'simulink')));
addpath(genpath(fullfile(projectRoot, 'simscape')));
addpath(genpath(fullfile(projectRoot, 'tests')));
addpath(genpath(fullfile(projectRoot, 'verification')));

%% Display project information
fprintf('\n');
fprintf('=============================================\n');
fprintf('              AVOLITE PROJECT\n');
fprintf('=============================================\n');
fprintf('Project Root:\n%s\n', projectRoot);
fprintf('=============================================\n');
fprintf('Initialization completed successfully.\n');
fprintf('=============================================\n');