function DopplerData = MultiPRFDoppler(AliasedFrequencies,Radar,RadarConfigData)

%=========================================================
% SARRS STUDIO
% Multi-PRF Doppler Ambiguity Resolver
%
% Purpose:
%   Resolves Doppler ambiguity using multiple PRFs.
%
% Inputs:
%   AliasedFrequencies : measured Doppler for each PRF
%   Radar              : Radar physical model
%   RadarConfigData    : Radar operating configuration
%
% Output:
%   DopplerData
%
%=========================================================


%% ========================================================
% Input Validation
%=========================================================

if nargin < 3

    error( ...
        'MultiPRFDoppler requires AliasedFrequencies, Radar and RadarConfigData.');

end


if ~isfield(RadarConfigData,'PRFList')

    error( ...
        'RadarConfigData.PRFList not found.');

end


%% ========================================================
% PRF Configuration
%=========================================================

PRFList = ...
    RadarConfigData.PRFList(:).';

NumPRFs = ...
    length(PRFList);


%% ========================================================
% Validate Frequency Input
%=========================================================

AliasedFrequencies = ...
    double(AliasedFrequencies(:).');


if length(AliasedFrequencies) ~= NumPRFs

    error( ...
        'Number of aliased frequencies must equal number of PRFs.');

end


%% ========================================================
% Maximum Search Velocity
%=========================================================

MaxVelocity = ...
    RadarConfigData.RequiredMaximumVelocity;


lambda = ...
    Radar.Wavelength;


%% ========================================================
% Convert Velocity Requirement To Doppler
%=========================================================

MaxDoppler = ...
    2 * MaxVelocity / lambda;


%% ========================================================
% Search Resolution
%=========================================================

SearchStep = 1;


%% ========================================================
% Candidate Doppler Search
%=========================================================

CandidateFrequencies = ...
    -MaxDoppler:SearchStep:MaxDoppler;


BestFrequency = NaN;

BestError = Inf;


%% ========================================================
% Search For Common Doppler
%=========================================================

for k = 1:length(CandidateFrequencies)

    Candidate = ...
        CandidateFrequencies(k);

    TotalError = 0;

    for p = 1:NumPRFs

        PRF = PRFList(p);

        %% -----------------------------------------------
        % Expected Aliased Doppler
        % -----------------------------------------------

        Expected = ...
            Candidate - ...
            round(Candidate/PRF) * PRF;

        %% -----------------------------------------------
        % Wrap to +/- PRF/2
        % -----------------------------------------------

        if Expected > PRF/2

            Expected = Expected - PRF;

        elseif Expected < -PRF/2

            Expected = Expected + PRF;

        end

        %% -----------------------------------------------
        % Difference
        % -----------------------------------------------

        ErrorValue = ...
            abs(Expected - AliasedFrequencies(p));

        TotalError = ...
            TotalError + ErrorValue;

    end


    %% ----------------------------------------------------
    % Best Candidate
    % -----------------------------------------------------

    if TotalError < BestError

        BestError = TotalError;

        BestFrequency = Candidate;

    end

end


%% ========================================================
% Convert Doppler To Velocity
%=========================================================

EstimatedVelocity = ...
    BestFrequency * lambda / 2;


%% ========================================================
% Output
%=========================================================

DopplerData.PRFList = ...
    PRFList;

DopplerData.AliasedFrequencies = ...
    AliasedFrequencies;

DopplerData.EstimatedDoppler = ...
    BestFrequency;

DopplerData.EstimatedVelocity = ...
    EstimatedVelocity;

DopplerData.Error = ...
    BestError;

DopplerData.MaximumDoppler = ...
    MaxDoppler;

DopplerData.MaximumVelocity = ...
    MaxVelocity;

DopplerData.Description = ...
    "Multi-PRF Doppler Ambiguity Resolver";


%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('Multi-PRF Doppler Resolver');
disp('=========================================');

fprintf('Number of PRFs : %d\n',NumPRFs);

fprintf('Maximum Velocity : +/- %.2f m/s\n', ...
    MaxVelocity);

fprintf('Maximum Doppler  : +/- %.2f Hz\n', ...
    MaxDoppler);

disp(' ');

for p = 1:NumPRFs

    fprintf( ...
        'PRF %d : %.0f Hz | Aliased Doppler = %.2f Hz\n',...
        p,...
        PRFList(p),...
        AliasedFrequencies(p));

end

fprintf('\nEstimated Doppler : %.2f Hz\n', ...
    BestFrequency);

fprintf('Estimated Velocity : %.2f m/s\n', ...
    EstimatedVelocity);

fprintf('Resolution Error   : %.2f Hz\n', ...
    BestError);

end