function Noise = NoiseEstimator(InputSignal)

%=========================================================
% SARRS STUDIO
% Noise Estimator
%
% Estimates receiver noise statistics
%=========================================================

InputSignal = abs(InputSignal(:));

Noise = struct;

%% Basic Statistics

Noise.Mean     = mean(InputSignal);
Noise.Median   = median(InputSignal);
Noise.Std      = std(InputSignal);
Noise.RMS      = rms(InputSignal);

%% Extremes

Noise.Maximum  = max(InputSignal);
Noise.Minimum  = min(InputSignal);

%% Noise Power

Noise.Power = mean(InputSignal.^2);

%% Noise Floor

Noise.Floor = Noise.Median;

%% Dynamic Range

Noise.DynamicRange = ...
    Noise.Maximum - Noise.Minimum;

%% Estimated SNR

if Noise.RMS > 0

    Noise.SNR = ...
        20*log10(Noise.Maximum/Noise.RMS);

else

    Noise.SNR = Inf;

end

end