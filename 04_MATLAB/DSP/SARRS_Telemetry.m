function Telemetry = SARRS_Telemetry( ...
    CurrentScan,...
    ScanInterval,...
    Target,...
    Radar,...
    EchoData,...
    ReceiverData,...
    Matched,...
    MTDData,...
    RDMap,...
    CFAR2D,...
    TrackTable)

%=========================================================
% SARRS STUDIO
% SARRS TELEMETRY ENGINE
%
% Purpose:
%   Collect system-level telemetry from every radar scan.
%
% Data flow:
%
%   RADAR PROCESSING
%          |
%          v
%      TELEMETRY
%          |
%          v
%   ADAPTIVE CONTROLLER
%          |
%          v
%   RESULTS LOGGER
%
% This module only observes the radar system.
% It does not directly modify RF processing.
%
%=========================================================


%% ========================================================
% Initialize
%=========================================================

Telemetry = struct();


%% ========================================================
% 1. SCAN INFORMATION
%=========================================================

Telemetry.ScanNumber = ...
    CurrentScan;

Telemetry.ScanInterval = ...
    ScanInterval;

Telemetry.SimulationTime = ...
    (CurrentScan - 1) * ScanInterval;

Telemetry.Timestamp = ...
    datetime("now");


%% ========================================================
% 2. TARGET / GROUND TRUTH TELEMETRY
%=========================================================

Telemetry.NumberOfTargets = ...
    length(Target);

Telemetry.TargetRange = [];

Telemetry.TargetVelocity = [];

Telemetry.TargetDoppler = [];

Telemetry.TargetRCS = [];

Telemetry.TargetX = [];

Telemetry.TargetY = [];

Telemetry.TargetZ = [];


if ~isempty(Target)

    NumTargets = length(Target);

    Telemetry.TargetRange = ...
        zeros(NumTargets,1);

    Telemetry.TargetVelocity = ...
        zeros(NumTargets,1);

    Telemetry.TargetDoppler = ...
        zeros(NumTargets,1);

    Telemetry.TargetRCS = ...
        zeros(NumTargets,1);

    Telemetry.TargetX = ...
        zeros(NumTargets,1);

    Telemetry.TargetY = ...
        zeros(NumTargets,1);

    Telemetry.TargetZ = ...
        zeros(NumTargets,1);


    for k = 1:NumTargets

        %% ------------------------------------------------
        % Current target history index
        % -------------------------------------------------

        if isfield(Target(k),'Distance')

            Index = ...
                min(max(CurrentScan,1), ...
                length(Target(k).Distance));

            Telemetry.TargetRange(k) = ...
                double(Target(k).Distance(Index));

        end


        %% ------------------------------------------------
        % Target velocity
        % -------------------------------------------------

        if isfield(Target(k),'Velocity')

            Telemetry.TargetVelocity(k) = ...
                double(Target(k).Velocity);

        end


        %% ------------------------------------------------
        % Target Doppler
        % -------------------------------------------------

        if isfield(Target(k),'Velocity') && ...
                isfield(Radar,'Wavelength') && ...
                Radar.Wavelength > 0

            Telemetry.TargetDoppler(k) = ...
                2 * Telemetry.TargetVelocity(k) / ...
                Radar.Wavelength;

        end


        %% ------------------------------------------------
        % Target RCS
        % -------------------------------------------------

        if isfield(Target(k),'RCS')

            Telemetry.TargetRCS(k) = ...
                double(Target(k).RCS);

        end


        %% ------------------------------------------------
        % Target X position
        % -------------------------------------------------

        if isfield(Target(k),'X')

            Index = ...
                min(max(CurrentScan,1), ...
                length(Target(k).X));

            Telemetry.TargetX(k) = ...
                double(Target(k).X(Index));

        end


        %% ------------------------------------------------
        % Target Y position
        % -------------------------------------------------

        if isfield(Target(k),'Y')

            Index = ...
                min(max(CurrentScan,1), ...
                length(Target(k).Y));

            Telemetry.TargetY(k) = ...
                double(Target(k).Y(Index));

        end


        %% ------------------------------------------------
        % Target Z position
        % -------------------------------------------------

        if isfield(Target(k),'Z')

            Index = ...
                min(max(CurrentScan,1), ...
                length(Target(k).Z));

            Telemetry.TargetZ(k) = ...
                double(Target(k).Z(Index));

        end

    end

end


%% ========================================================
% 3. RADAR CONFIGURATION
%=========================================================

Telemetry.RFFrequency = ...
    Radar.Frequency;

Telemetry.Wavelength = ...
    Radar.Wavelength;

Telemetry.TransmitPower = ...
    Radar.Power;

Telemetry.AntennaGain = ...
    Radar.Gain;

Telemetry.Bandwidth = ...
    Radar.Bandwidth;

Telemetry.SampleRate = ...
    Radar.SampleRate;

Telemetry.RangeResolution = ...
    Radar.RangeResolution;

Telemetry.MaximumRange = ...
    Radar.MaximumRange;

Telemetry.PRF = ...
    Radar.PRF;

Telemetry.PRI = ...
    Radar.PRI;


%% ========================================================
% 4. ECHO / PROPAGATION TELEMETRY
%=========================================================

Telemetry.NumberOfEchoTargets = ...
    EchoData.NumberOfTargets;


Telemetry.ReceivedPower = [];

Telemetry.EchoAmplitude = [];

Telemetry.EchoRange = [];

Telemetry.EchoVelocity = [];

Telemetry.EchoDoppler = [];

Telemetry.EchoDelay = [];

Telemetry.EchoDelaySamples = [];


if isfield(EchoData,'Power')

    Telemetry.ReceivedPower = ...
        double(EchoData.Power(:));

end


if isfield(EchoData,'Amplitude')

    Telemetry.EchoAmplitude = ...
        double(EchoData.Amplitude(:));

end


if isfield(EchoData,'Range')

    Telemetry.EchoRange = ...
        double(EchoData.Range(:));

end


if isfield(EchoData,'Velocity')

    Telemetry.EchoVelocity = ...
        double(EchoData.Velocity(:));

end


if isfield(EchoData,'Doppler')

    Telemetry.EchoDoppler = ...
        double(EchoData.Doppler(:));

end


if isfield(EchoData,'Delay')

    Telemetry.EchoDelay = ...
        double(EchoData.Delay(:));

end


if isfield(EchoData,'DelaySamples')

    Telemetry.EchoDelaySamples = ...
        double(EchoData.DelaySamples(:));

end


%% ========================================================
% 5. RECEIVER CONFIGURATION
%=========================================================

Telemetry.LNAGain = ...
    ReceiverData.LNAGain;

Telemetry.NoiseFigure = ...
    ReceiverData.NoiseFigure;

Telemetry.FilterLoss = ...
    ReceiverData.FilterLoss;

Telemetry.MixerLoss = ...
    ReceiverData.MixerLoss;

Telemetry.IFGain = ...
    ReceiverData.IFGain;

Telemetry.TotalReceiverGain = ...
    ReceiverData.TotalGain;


%% ========================================================
% 6. RECEIVER SIGNAL MEASUREMENTS
%=========================================================

InputSignal = ...
    double(ReceiverData.InputSignal);

OutputSignal = ...
    double(ReceiverData.OutputSignal);


%% --------------------------------------------------------
% Input signal power
%---------------------------------------------------------

Telemetry.InputSignalPower = ...
    mean(abs(InputSignal(:)).^2);


%% --------------------------------------------------------
% Output signal power
%---------------------------------------------------------

Telemetry.OutputSignalPower = ...
    mean(abs(OutputSignal(:)).^2);


%% --------------------------------------------------------
% Input RMS
%---------------------------------------------------------

Telemetry.InputRMS = ...
    sqrt(Telemetry.InputSignalPower);


%% --------------------------------------------------------
% Output RMS
%---------------------------------------------------------

Telemetry.OutputRMS = ...
    sqrt(Telemetry.OutputSignalPower);


%% ========================================================
% 7. RSSI
%=========================================================

if Telemetry.InputSignalPower > 0

    Telemetry.RSSI_dB = ...
        10 * log10(Telemetry.InputSignalPower);

else

    Telemetry.RSSI_dB = ...
        -Inf;

end


%% ========================================================
% 8. NOISE MEASUREMENT
%=========================================================

if isfield(EchoData,'Noise')

    NoiseSignal = ...
        double(EchoData.Noise);

    Telemetry.NoisePower = ...
        mean(abs(NoiseSignal(:)).^2);

else

    Telemetry.NoisePower = 0;

end


%% --------------------------------------------------------
% Noise RMS
%---------------------------------------------------------

if Telemetry.NoisePower > 0

    Telemetry.NoiseRMS = ...
        sqrt(Telemetry.NoisePower);

else

    Telemetry.NoiseRMS = ...
        0;

end


%% --------------------------------------------------------
% Noise floor
%---------------------------------------------------------

if Telemetry.NoisePower > 0

    Telemetry.NoiseFloor_dB = ...
        10 * log10(Telemetry.NoisePower);

else

    Telemetry.NoiseFloor_dB = ...
        -Inf;

end


%% ========================================================
% 9. INPUT SNR
%=========================================================

SignalPower = ...
    Telemetry.InputSignalPower;

NoisePower = ...
    Telemetry.NoisePower;


if NoisePower > 0 && SignalPower > 0

    Telemetry.SNR_dB = ...
        10 * log10( ...
        SignalPower / NoisePower);

else

    Telemetry.SNR_dB = ...
        NaN;

end


%% ========================================================
% 10. COMPATIBILITY FIELDS FOR ADAPTIVE CONTROLLER
%=========================================================
%
% These fields maintain compatibility with the current
% SARRS_AdaptiveController.m.
%
% New telemetry naming:
%
%   SNR_dB
%   NoisePower
%   InputRMS
%   CFARDetections
%
% Controller compatibility:
%
%   InputSNR
%   NoiseRMS
%   ReceivedSignalRMS
%   CFARTargets
%
%=========================================================

Telemetry.InputSNR = ...
    Telemetry.SNR_dB;

Telemetry.ReceivedSignalRMS = ...
    Telemetry.InputRMS;


%% ========================================================
% 11. MATCHED FILTER TELEMETRY
%=========================================================

Telemetry.MatchedFilterPeak = ...
    0;

Telemetry.MatchedFilterPeakRange = ...
    0;

Telemetry.NumberOfMatchedPeaks = ...
    0;

Telemetry.MatchedFilterProcessingGain_dB = ...
    NaN;


if isfield(Matched,'NumberOfPeaks')

    Telemetry.NumberOfMatchedPeaks = ...
        Matched.NumberOfPeaks;

end


if isfield(Matched,'Peak')

    Telemetry.MatchedFilterPeak = ...
        Matched.Peak;

end


if isfield(Matched,'PeakRange')

    Telemetry.MatchedFilterPeakRange = ...
        Matched.PeakRange;

end


if isfield(Matched,'PulseLength')

    if Matched.PulseLength > 0

        Telemetry.MatchedFilterProcessingGain_dB = ...
            10 * log10(Matched.PulseLength);

    end

end


%% ========================================================
% 12. DOPPLER / MTD TELEMETRY
%=========================================================

Telemetry.DopplerBins = [];

Telemetry.DopplerPeak = NaN;

Telemetry.EstimatedDoppler = NaN;

Telemetry.EstimatedVelocity = NaN;

Telemetry.DopplerResolution = NaN;


if isstruct(MTDData)

    %% Doppler axis

    if isfield(MTDData,'DopplerAxis')

        Telemetry.DopplerBins = ...
            MTDData.DopplerAxis;

    end


    %% Peak frequency

    if isfield(MTDData,'PeakFrequency')

        Telemetry.DopplerPeak = ...
            double(MTDData.PeakFrequency);

        Telemetry.EstimatedDoppler = ...
            double(MTDData.PeakFrequency);

    end


    %% Peak velocity

    if isfield(MTDData,'PeakVelocity')

        Telemetry.EstimatedVelocity = ...
            double(MTDData.PeakVelocity);

    end


    %% Doppler resolution

    if isfield(MTDData,'DopplerResolution')

        Telemetry.DopplerResolution = ...
            double(MTDData.DopplerResolution);

    end

end


%% ========================================================
% 13. RANGE-DOPPLER TELEMETRY
%=========================================================

Telemetry.RangeDopplerPeak = NaN;

Telemetry.RangeDopplerPeakRange = NaN;

Telemetry.RangeDopplerPeakVelocity = NaN;

Telemetry.RangeDopplerPeakDoppler = NaN;

Telemetry.RangeDopplerResolution = NaN;


if isstruct(RDMap)

    %% ----------------------------------------------------
    % Preferred global values
    %-----------------------------------------------------

    if isfield(RDMap,'GlobalPeak')

        Telemetry.RangeDopplerPeak = ...
            double(RDMap.GlobalPeak);

    end


    if isfield(RDMap,'GlobalRange')

        Telemetry.RangeDopplerPeakRange = ...
            double(RDMap.GlobalRange);

    end


    if isfield(RDMap,'GlobalVelocity')

        Telemetry.RangeDopplerPeakVelocity = ...
            double(RDMap.GlobalVelocity);

    end


    if isfield(RDMap,'GlobalDoppler')

        Telemetry.RangeDopplerPeakDoppler = ...
            double(RDMap.GlobalDoppler);

    end


    %% ----------------------------------------------------
    % Doppler resolution
    %-----------------------------------------------------

    if isfield(RDMap,'DopplerResolution')

        Telemetry.RangeDopplerResolution = ...
            double(RDMap.DopplerResolution);

    end


    %% ----------------------------------------------------
    % Fallback peak calculation
    %-----------------------------------------------------

    if isnan(Telemetry.RangeDopplerPeak) && ...
            isfield(RDMap,'Data')

        RDData = ...
            double(RDMap.Data);

        if ~isempty(RDData)

            [PeakValue,LinearIndex] = ...
                max(abs(RDData(:)));

            [RangeIndex,DopplerIndex] = ...
                ind2sub( ...
                size(RDData),...
                LinearIndex);

            Telemetry.RangeDopplerPeak = ...
                PeakValue;


            if isfield(RDMap,'RangeAxis')

                RangeAxis = ...
                    double(RDMap.RangeAxis(:));

                if RangeIndex <= length(RangeAxis)

                    Telemetry.RangeDopplerPeakRange = ...
                        RangeAxis(RangeIndex);

                end

            end


            if isfield(RDMap,'VelocityAxis')

                VelocityAxis = ...
                    double(RDMap.VelocityAxis(:));

                if DopplerIndex <= length(VelocityAxis)

                    Telemetry.RangeDopplerPeakVelocity = ...
                        VelocityAxis(DopplerIndex);

                end

            end

        end

    end

end


%% ========================================================
% 14. CFAR TELEMETRY
%=========================================================

Telemetry.CFARDetections = ...
    0;

Telemetry.CFARTargetDetected = ...
    false;

Telemetry.CFARThreshold = ...
    NaN;

Telemetry.CFARThresholdScale = ...
    NaN;

Telemetry.CFARNoiseFloor = ...
    NaN;

Telemetry.CFARTargets = ...
    0;


if isstruct(CFAR2D)

    %% Number of detections

    if isfield(CFAR2D,'NumberOfTargets')

        Telemetry.CFARDetections = ...
            double(CFAR2D.NumberOfTargets);

    end


    %% Detection flag

    if isfield(CFAR2D,'TargetDetected')

        Telemetry.CFARTargetDetected = ...
            logical(CFAR2D.TargetDetected);

    end


    %% Threshold

    if isfield(CFAR2D,'Threshold')

        Telemetry.CFARThreshold = ...
            double(CFAR2D.Threshold);

    end


    %% Threshold scale

    if isfield(CFAR2D,'ThresholdScale')

        Telemetry.CFARThresholdScale = ...
            double(CFAR2D.ThresholdScale);

    end


    %% Noise floor

    if isfield(CFAR2D,'NoiseFloor')

        Telemetry.CFARNoiseFloor = ...
            double(CFAR2D.NoiseFloor);

    elseif isfield(CFAR2D,'ThresholdMap')

        ThresholdMap = ...
            double(CFAR2D.ThresholdMap);

        if ~isempty(ThresholdMap)

            Telemetry.CFARNoiseFloor = ...
                mean(ThresholdMap(:));

        end

    end

end


%% --------------------------------------------------------
% Compatibility alias
%---------------------------------------------------------

Telemetry.CFARTargets = ...
    Telemetry.CFARDetections;


%% ========================================================
% 15. TRACK TELEMETRY
%=========================================================

Telemetry.NumberOfTracks = ...
    length(TrackTable);

Telemetry.TrackRanges = [];

Telemetry.TrackVelocities = [];

Telemetry.TrackIDs = [];

Telemetry.TrackStatus = [];


if ~isempty(TrackTable)

    NumTracks = ...
        length(TrackTable);


    Telemetry.TrackRanges = ...
        zeros(NumTracks,1);

    Telemetry.TrackVelocities = ...
        zeros(NumTracks,1);

    Telemetry.TrackIDs = ...
        zeros(NumTracks,1);

    Telemetry.TrackStatus = ...
        strings(NumTracks,1);


    for k = 1:NumTracks

        %% ------------------------------------------------
        % Track ID
        %-------------------------------------------------

        if isfield(TrackTable(k),'TrackID')

            Telemetry.TrackIDs(k) = ...
                double(TrackTable(k).TrackID);

        else

            Telemetry.TrackIDs(k) = ...
                k;

        end


        %% ------------------------------------------------
        % Track range
        %-------------------------------------------------

        if isfield(TrackTable(k),'FilteredRange')

            Telemetry.TrackRanges(k) = ...
                double(TrackTable(k).FilteredRange);

        elseif isfield(TrackTable(k),'Range')

            Telemetry.TrackRanges(k) = ...
                double(TrackTable(k).Range);

        elseif isfield(TrackTable(k),'PredictedRange')

            Telemetry.TrackRanges(k) = ...
                double(TrackTable(k).PredictedRange);

        end


        %% ------------------------------------------------
        % Track velocity
        %-------------------------------------------------

        if isfield(TrackTable(k),'FilteredVelocity')

            Telemetry.TrackVelocities(k) = ...
                double(TrackTable(k).FilteredVelocity);

        elseif isfield(TrackTable(k),'Velocity')

            Telemetry.TrackVelocities(k) = ...
                double(TrackTable(k).Velocity);

        elseif isfield(TrackTable(k),'PredictedVelocity')

            Telemetry.TrackVelocities(k) = ...
                double(TrackTable(k).PredictedVelocity);

        end


        %% ------------------------------------------------
        % Track status
        %-------------------------------------------------

        if isfield(TrackTable(k),'Status')

            Telemetry.TrackStatus(k) = ...
                string(TrackTable(k).Status);

        elseif isfield(TrackTable(k),'State')

            Telemetry.TrackStatus(k) = ...
                string(TrackTable(k).State);

        else

            Telemetry.TrackStatus(k) = ...
                "Unknown";

        end

    end

end


%% ========================================================
% 16. PRIMARY TRACK
%=========================================================

if ~isempty(Telemetry.TrackRanges)

    Telemetry.PrimaryTrackRange = ...
        Telemetry.TrackRanges(1);

    Telemetry.PrimaryTrackVelocity = ...
        Telemetry.TrackVelocities(1);

else

    Telemetry.PrimaryTrackRange = ...
        NaN;

    Telemetry.PrimaryTrackVelocity = ...
        NaN;

end


%% ========================================================
% 17. RECEIVER HEALTH
%=========================================================

Telemetry.ReceiverHealth = ...
    "UNKNOWN";


if isnan(Telemetry.SNR_dB)

    Telemetry.ReceiverHealth = ...
        "UNKNOWN";

elseif Telemetry.SNR_dB < 3

    Telemetry.ReceiverHealth = ...
        "POOR";

elseif Telemetry.SNR_dB < 10

    Telemetry.ReceiverHealth = ...
        "DEGRADED";

else

    Telemetry.ReceiverHealth = ...
        "NORMAL";

end


%% ========================================================
% 18. DETECTION QUALITY
%=========================================================

Telemetry.DetectionQuality = ...
    "NO_DETECTION";


if Telemetry.CFARDetections > 0

    if isnan(Telemetry.SNR_dB)

        Telemetry.DetectionQuality = ...
            "UNKNOWN";

    elseif Telemetry.SNR_dB >= 10

        Telemetry.DetectionQuality = ...
            "GOOD";

    elseif Telemetry.SNR_dB >= 3

        Telemetry.DetectionQuality = ...
            "MODERATE";

    else

        Telemetry.DetectionQuality = ...
            "WEAK";

    end

end


%% ========================================================
% 19. ADAPTIVE CONTROLLER INPUTS
%=========================================================
%
% This is the clean interface between telemetry and
% SARRS_AdaptiveController.m
%
%=========================================================

Telemetry.AdaptiveInputs = struct();


Telemetry.AdaptiveInputs.InputSNR = ...
    Telemetry.InputSNR;

Telemetry.AdaptiveInputs.SNR_dB = ...
    Telemetry.SNR_dB;

Telemetry.AdaptiveInputs.NoiseRMS = ...
    Telemetry.NoiseRMS;

Telemetry.AdaptiveInputs.NoisePower = ...
    Telemetry.NoisePower;

Telemetry.AdaptiveInputs.ReceivedSignalRMS = ...
    Telemetry.ReceivedSignalRMS;

Telemetry.AdaptiveInputs.CFARTargets = ...
    Telemetry.CFARTargets;

Telemetry.AdaptiveInputs.CFARDetections = ...
    Telemetry.CFARDetections;

Telemetry.AdaptiveInputs.CFARThresholdScale = ...
    Telemetry.CFARThresholdScale;

Telemetry.AdaptiveInputs.NumberOfTracks = ...
    Telemetry.NumberOfTracks;

Telemetry.AdaptiveInputs.EstimatedVelocity = ...
    Telemetry.EstimatedVelocity;

Telemetry.AdaptiveInputs.EstimatedDoppler = ...
    Telemetry.EstimatedDoppler;

Telemetry.AdaptiveInputs.RSSI_dB = ...
    Telemetry.RSSI_dB;

Telemetry.AdaptiveInputs.ReceiverGain = ...
    Telemetry.TotalReceiverGain;

Telemetry.AdaptiveInputs.FilterLoss = ...
    Telemetry.FilterLoss;

Telemetry.AdaptiveInputs.MixerLoss = ...
    Telemetry.MixerLoss;


%% ========================================================
% 20. DESCRIPTION
%=========================================================

Telemetry.Description = ...
    "SARRS scan-level telemetry";


%% ========================================================
% 21. DISPLAY
%=========================================================

disp(' ');
disp('=========================================');
disp('SARRS TELEMETRY');
disp('=========================================');

fprintf('Scan Number       : %d\n', ...
    Telemetry.ScanNumber);

fprintf('Simulation Time   : %.2f s\n', ...
    Telemetry.SimulationTime);

fprintf('Targets           : %d\n', ...
    Telemetry.NumberOfTargets);

fprintf('Input RMS         : %.6g\n', ...
    Telemetry.InputRMS);

fprintf('Output RMS        : %.6g\n', ...
    Telemetry.OutputRMS);

fprintf('SNR               : %.2f dB\n', ...
    Telemetry.SNR_dB);

fprintf('RSSI              : %.2f dB\n', ...
    Telemetry.RSSI_dB);

fprintf('Noise Floor       : %.2f dB\n', ...
    Telemetry.NoiseFloor_dB);

fprintf('Receiver Gain     : %.2f dB\n', ...
    Telemetry.TotalReceiverGain);

fprintf('Matched Peaks     : %d\n', ...
    Telemetry.NumberOfMatchedPeaks);

fprintf('CFAR Detections   : %d\n', ...
    Telemetry.CFARDetections);

fprintf('CFAR Threshold    : %.2f\n', ...
    Telemetry.CFARThresholdScale);

fprintf('Doppler Peak      : %.2f Hz\n', ...
    Telemetry.DopplerPeak);

fprintf('Estimated Velocity: %.2f m/s\n', ...
    Telemetry.EstimatedVelocity);

fprintf('Tracks            : %d\n', ...
    Telemetry.NumberOfTracks);

fprintf('Receiver Health   : %s\n', ...
    string(Telemetry.ReceiverHealth));

fprintf('Detection Quality : %s\n', ...
    string(Telemetry.DetectionQuality));

disp(' ');

end