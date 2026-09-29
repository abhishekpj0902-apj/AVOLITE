function RangeDopplerViewer(MTD)

%=========================================================
% SARRS STUDIO
% Range Doppler Viewer
%
% Displays
%   Range vs Velocity Map
%=========================================================

figure(...
    'Name','Range Doppler Map',...
    'NumberTitle','off',...
    'Color','w');

%% Input

Spectrum = abs(MTD.Magnitude(:));

N = length(Spectrum);

Velocity = MTD.VelocityAxis(:);

Range = linspace(0,150,N);

%% Create pseudo Range-Doppler map

RDMap = Spectrum * ones(1,64);

imagesc(...
    linspace(min(Velocity),max(Velocity),64),...
    Range,...
    20*log10(RDMap+eps));

axis xy

xlabel('Velocity (m/s)');
ylabel('Range (km)');

title('Range Doppler Map');

colorbar

colormap(jet)

grid on
