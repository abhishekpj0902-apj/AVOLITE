function Threat = ThreatClassifier(Tracks)

%=========================================================
% SARRS STUDIO
% Threat Classifier
%
% Evaluates Threat Level of Each Track
%=========================================================

Threat = struct([]);

for i = 1:length(Tracks)

    Range = norm(Tracks(i).Position);

    Velocity = Tracks(i).Velocity;

    Confidence = Tracks(i).Confidence;

    %----------------------------
    % Threat Score
    %----------------------------

    Score = 0;

    % Close targets are more dangerous
    if Range < 30000
        Score = Score + 3;
    elseif Range < 60000
        Score = Score + 2;
    else
        Score = Score + 1;
    end

    % Faster targets are more dangerous
    if Velocity > 500
        Score = Score + 3;
    elseif Velocity > 250
        Score = Score + 2;
    else
        Score = Score + 1;
    end

    % Higher confidence increases score
    if Confidence > 0.9
        Score = Score + 2;
    elseif Confidence > 0.7
        Score = Score + 1;
    end

    %----------------------------
    % Threat Level
    %----------------------------

    if Score >= 7
        Level = "HIGH";
    elseif Score >= 5
        Level = "MEDIUM";
    else
        Level = "LOW";
    end

    Threat(i).TrackID = Tracks(i).TrackID;
    Threat(i).Range = Range;
    Threat(i).Velocity = Velocity;
    Threat(i).ThreatScore = Score;
    Threat(i).ThreatLevel = Level;

end

end