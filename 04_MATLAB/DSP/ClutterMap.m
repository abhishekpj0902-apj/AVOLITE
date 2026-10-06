function Clutter = ClutterMap(InputSignal)

%=========================================================
% SARRS STUDIO
% Clutter Map
%
% Estimates stationary clutter
%=========================================================

Signal = abs(InputSignal);

Window = 32;

Clutter.Level = movmean(Signal, Window);

Clutter.SuppressedSignal = Signal - Clutter.Level;

Clutter.SuppressedSignal( ...
    Clutter.SuppressedSignal < 0) = 0;

Clutter.Maximum = max(Clutter.Level);

Clutter.Mean = mean(Clutter.Level);

Clutter.Std = std(Clutter.Level);

end