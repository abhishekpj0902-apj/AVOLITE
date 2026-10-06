function RDMap = RangeDopplerProcessor(InputData, Radar)
% RangeDopplerProcessor
%
% Generates a 2-D Range-Doppler map.
%
% Input:
%   InputData:
%       Numeric matrix or structure containing .Output
%
%   Radar:
%       Radar parameter structure
%
% Matrix organization:
%   Rows    = fast-time/range samples
%   Columns = slow-time pulses
%
% Processing:
%   1. Extract signal
%   2. Apply slow-time window
%   3. Doppler FFT
%   4. FFT shift
%   5. Generate range, Doppler, and velocity axes

    fprintf('\n==============================================\n');
    fprintf('RANGE-DOPPLER PROCESSOR\n');
    fprintf('==============================================\n');

    %% ---------------------------------------------------------
    % Extract input signal
    % ----------------------------------------------------------

    if isstruct(InputData)

        if isfield(InputData, 'Output')
            Signal = InputData.Output;

        elseif isfield(InputData, 'Signal')
            Signal = InputData.Signal;

        elseif isfield(InputData, 'Input')
            Signal = InputData.Input;

        else
            error('Input structure must contain Output, Signal, or Input.');
        end

    elseif isnumeric(InputData)

        Signal = InputData;

    else
        error('InputData must be numeric or a structure.');
    end

    Signal = double(Signal);

    if isempty(Signal)
        error('Input signal cannot be empty.');
    end

    if isvector(Signal)
        Signal = Signal(:);
    end

    [NumRangeSamples, NumPulses] = size(Signal);

    if NumPulses < 2
        error('At least two pulses are required for Doppler processing.');
    end

    %% ---------------------------------------------------------
    % Radar parameters
    % ----------------------------------------------------------

    c = 3e8;

    if isfield(Radar, 'Frequency')
        Frequency = Radar.Frequency;
    else
        Frequency = 10e9;
    end

    if isfield(Radar, 'Wavelength')
        Wavelength = Radar.Wavelength;
    else
        Wavelength = c / Frequency;
    end

    if isfield(Radar, 'PRF')
        PRF = Radar.PRF;
    else
        error('Radar structure must contain PRF.');
    end

    if isfield(Radar, 'SampleRate')
        SampleRate = Radar.SampleRate;
    else
        SampleRate = 100e6;
    end

    if isfield(Radar, 'PulseWidth')
        PulseWidth = Radar.PulseWidth;
    else
        PulseWidth = 1e-6;
    end

    %% ---------------------------------------------------------
    % Range axis
    % ----------------------------------------------------------

    % Fast-time sample spacing
    RangeBinSpacing = c / (2 * SampleRate);

    % Physical pulse-compression resolution
    RangeResolution = c * PulseWidth / 2;

    RangeAxis = (0:NumRangeSamples-1).' * RangeBinSpacing;

    %% ---------------------------------------------------------
    % Slow-time window
    % ----------------------------------------------------------

    SlowTimeWindow = hamming(NumPulses);

    % Convert to row vector for multiplication across columns
    SlowTimeWindow = SlowTimeWindow.';

    WindowedData = Signal .* SlowTimeWindow;

    %% ---------------------------------------------------------
    % Doppler FFT
    % ----------------------------------------------------------

    NumDopplerBins = 4096;

    RDComplex = fftshift( ...
        fft(WindowedData, NumDopplerBins, 2), ...
        2);

    RDMagnitude = abs(RDComplex);

    %% ---------------------------------------------------------
    % Normalize
    % ----------------------------------------------------------

    MaximumValue = max(RDMagnitude(:));

    if MaximumValue > 0
        RDData = RDMagnitude ./ MaximumValue;
    else
        RDData = RDMagnitude;
    end

    %% ---------------------------------------------------------
    % Correct FFT Doppler axis
    % ----------------------------------------------------------

    DopplerResolution = PRF / NumDopplerBins;

    DopplerAxis = ...
        (-NumDopplerBins/2 : NumDopplerBins/2-1) ...
        * DopplerResolution;

    VelocityAxis = DopplerAxis * Wavelength / 2;

    %% ---------------------------------------------------------
    % Strongest peak
    % ----------------------------------------------------------

    [GlobalPeakValue, GlobalIndex] = max(RDData(:));

    [GlobalRangeIndex, GlobalDopplerIndex] = ...
        ind2sub(size(RDData), GlobalIndex);

    GlobalRange = RangeAxis(GlobalRangeIndex);
    GlobalDoppler = DopplerAxis(GlobalDopplerIndex);
    GlobalVelocity = VelocityAxis(GlobalDopplerIndex);

    %% ---------------------------------------------------------
    % Output structure
    % ----------------------------------------------------------

    RDMap = struct();

    RDMap.Data = RDData;
    RDMap.ComplexData = RDComplex;

    RDMap.RangeAxis = RangeAxis;
    RDMap.FullRangeAxis = RangeAxis;

    RDMap.DopplerAxis = DopplerAxis;
    RDMap.VelocityAxis = VelocityAxis;

    RDMap.NumRangeBins = NumRangeSamples;
    RDMap.NumDopplerBins = NumDopplerBins;
    RDMap.NumPulses = NumPulses;

    RDMap.PRF = PRF;
    RDMap.PRFList = PRF;

    RDMap.SampleRate = SampleRate;
    RDMap.Wavelength = Wavelength;

    RDMap.RangeBinSpacing = RangeBinSpacing;
    RDMap.RangeResolution = RangeResolution;

    RDMap.DopplerResolution = DopplerResolution;
    RDMap.MaximumDoppler = PRF / 2;

    RDMap.PulseTime = (0:NumPulses-1) / PRF;

    RDMap.GlobalPeak = GlobalPeakValue;
    RDMap.GlobalRange = GlobalRange;
    RDMap.GlobalDoppler = GlobalDoppler;
    RDMap.GlobalVelocity = GlobalVelocity;

    RDMap.Peaks = struct( ...
        'Range', GlobalRange, ...
        'Velocity', GlobalVelocity, ...
        'Doppler', GlobalDoppler, ...
        'Amplitude', GlobalPeakValue, ...
        'RangeIndex', GlobalRangeIndex, ...
        'VelocityIndex', GlobalDopplerIndex);

    RDMap.NumberOfPeaks = 1;

    RDMap.Description = ...
        'Range-Doppler map using slow-time FFT after MTI';

    %% ---------------------------------------------------------
    % Display information
    % ----------------------------------------------------------

    fprintf('Input Range Samples : %d\n', NumRangeSamples);
    fprintf('Input Pulses        : %d\n', NumPulses);
    fprintf('Range Bins          : %d\n', NumRangeSamples);
    fprintf('Doppler Bins        : %d\n', NumDopplerBins);

    fprintf('PRF                 : %.2f Hz\n', PRF);
    fprintf('Range Bin Spacing   : %.3f m\n', RangeBinSpacing);
    fprintf('Range Resolution    : %.3f m\n', RangeResolution);
    fprintf('Doppler Resolution  : %.3f Hz\n', DopplerResolution);

    fprintf('Strongest Range     : %.3f km\n', ...
        GlobalRange / 1000);

    fprintf('Strongest Doppler   : %.3f Hz\n', ...
        GlobalDoppler);

    fprintf('Strongest Velocity  : %.3f m/s\n', ...
        GlobalVelocity);

    fprintf('==============================================\n');

end