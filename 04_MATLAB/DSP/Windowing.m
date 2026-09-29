function Window = Windowing(InputSignal,WindowType)

%=========================================================
% SARRS STUDIO
% Windowing
%
% Supported Windows:
%   Rectangular
%   Hamming
%   Hanning
%   Blackman
%=========================================================

if nargin < 2

    WindowType = "Hamming";

end

Window = struct;

InputSignal = InputSignal(:);

N = length(InputSignal);

%% Select Window

switch upper(string(WindowType))

    case "HAMMING"

        W = hamming(N);

    case "HANNING"

        W = hann(N);

    case "BLACKMAN"

        W = blackman(N);

    otherwise

        W = ones(N,1);

        WindowType = "Rectangular";

end

%% Apply Window

OutputSignal = InputSignal .* W;

%% Store Results

Window.Type = WindowType;

Window.Input = InputSignal;

Window.Coefficients = W;

Window.Output = OutputSignal;

Window.Length = N;

Window.Energy = sum(W.^2);

Window.Gain = mean(W);

end