function SpectrumViewer(FFTData)

%=========================================================
% SARRS STUDIO
% Spectrum Viewer
%
% Displays:
%   1. Magnitude Spectrum
%   2. Power Spectrum
%   3. Phase Spectrum
%=========================================================

figure(...
    'Name','Spectrum Viewer',...
    'NumberTitle','off',...
    'Color','w',...
    'Position',[200 100 1200 800]);

%% Extract Data

Frequency = FFTData.Frequency(:);

Magnitude = abs(FFTData.Magnitude(:));

Power = abs(FFTData.Power(:));

Phase = FFTData.Phase(:);

%% -----------------------------
% Magnitude Spectrum
%------------------------------

subplot(3,1,1)

plot(...
    Frequency,...
    Magnitude,...
    'b',...
    'LineWidth',1.2);

grid on

xlabel('Normalized Frequency')

ylabel('Magnitude')

title('FFT Magnitude Spectrum')

%% -----------------------------
% Power Spectrum
%------------------------------

subplot(3,1,2)

plot(...
    Frequency,...
    10*log10(Power+eps),...
    'r',...
    'LineWidth',1.2);

grid on

xlabel('Normalized Frequency')

ylabel('Power (dB)')

title('Power Spectrum')

%% -----------------------------
% Phase Spectrum
%------------------------------

subplot(3,1,3)

plot(...
    Frequency,...
    Phase,...
    'k',...
    'LineWidth',1.2);

grid on

xlabel('Normalized Frequency')

ylabel('Phase (rad)')

title('Phase Spectrum')

sgtitle('Spectrum Viewer')