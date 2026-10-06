TrainingCells = 8;
GuardCells = 2;
ThresholdFactor = 5;

RangeDopplerPower = abs(RangeDopplerMap).^2;

DetectionMap = CA_CFAR_2D( ...
    RangeDopplerPower, ...
    TrainingCells, ...
    GuardCells, ...
    ThresholdFactor);
figure;
imagesc(DetectionMap);
axis xy;
colorbar;
xlabel('Doppler Bin');
ylabel('Range Bin');
title('2D-CFAR Detection Map');