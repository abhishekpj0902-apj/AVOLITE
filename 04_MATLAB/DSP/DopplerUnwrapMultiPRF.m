function Result = DopplerUnwrapMultiPRF( ...
    AliasedDoppler, PRFList, Wavelength, VelocityLimits)

% DopplerUnwrapMultiPRF
% Multi-PRF Doppler ambiguity resolution.

    if nargin < 4
        VelocityLimits = [-600 600];
    end

    AliasedDoppler = AliasedDoppler(:).';
    PRFList = PRFList(:).';

    if numel(AliasedDoppler) ~= numel(PRFList)
        error("AliasedDoppler and PRFList must have equal length.");
    end

    % Candidate velocity grid
    VelocityStep = 0.1;

    CandidateVelocity = ...
        (VelocityLimits(1):VelocityStep:VelocityLimits(2)).';

    % Convert velocity to true Doppler frequency
    CandidateDoppler = ...
        2 .* CandidateVelocity ./ Wavelength;

    ErrorMatrix = zeros( ...
        length(CandidateVelocity), ...
        length(PRFList));

    for k = 1:length(PRFList)

        PRF = PRFList(k);

        % Predicted aliased Doppler for every candidate velocity
        PredictedAliased = ...
            mod(CandidateDoppler + PRF/2, PRF) - PRF/2;

        % Circular error between predicted and measured Doppler
        DopplerError = ...
            mod(PredictedAliased - AliasedDoppler(k) ...
            + PRF/2, PRF) - PRF/2;

        ErrorMatrix(:, k) = abs(DopplerError);

    end

    % Total least-squares error
    TotalError = sum(ErrorMatrix.^2, 2);

    % Select the best candidate
    [MinimumError, BestIndex] = min(TotalError);

    BestVelocity = CandidateVelocity(BestIndex);
    BestDoppler = 2 * BestVelocity / Wavelength;

    Result = struct();

    Result.TrueVelocity = BestVelocity;
    Result.TrueDoppler = BestDoppler;
    Result.Error = sqrt(MinimumError);

    Result.AliasedDoppler = AliasedDoppler;
    Result.PRFList = PRFList;
    Result.Wavelength = Wavelength;

end