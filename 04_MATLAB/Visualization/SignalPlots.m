function SignalPlots(Waveform,Echo,Receiver,Matched)

%=========================================================
% SARRS STUDIO
% Signal Visualization
%=========================================================

figure('Name','SARRS Signal Processing','NumberTitle','off');

%% -------------------------------------------------------
subplot(4,1,1)

plot(Waveform.Signal,'b','LineWidth',1)

title('Transmit Pulse')

xlabel('Samples')

ylabel('Amplitude')

grid on

%% -------------------------------------------------------
subplot(4,1,2)

plot(real(Echo.Signal),'r')

title('Received Echo + Noise')

xlabel('Samples')

ylabel('Amplitude')

grid on

%% -------------------------------------------------------
subplot(4,1,3)

plot(real(Receiver.OutputSignal),'k')

title('Receiver Output')

xlabel('Samples')

ylabel('Amplitude')

grid on

%% -------------------------------------------------------
subplot(4,1,4)

plot(Matched.RangeAxis/1000,...
     abs(Matched.Output),...
     'b','LineWidth',1.5)

hold on

if ~isempty(Matched.PeakIndices)

    plot(Matched.PeakRanges/1000,...
         Matched.Peaks,...
         'rv',...
         'MarkerFaceColor','r',...
         'MarkerSize',8);

end

xlabel('Range (km)')

ylabel('Normalized Amplitude')

title('Matched Filter Output')

grid on

end