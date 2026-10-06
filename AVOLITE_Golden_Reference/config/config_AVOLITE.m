function cfg = config_AVOLITE()
%CONFIG_AVOLITE Central configuration for AVOLITE Golden Reference.
%
% This file is the single source of truth for model parameters.
%
% All downstream MATLAB reference models shall obtain parameters
% from this configuration rather than hard-coding them locally.
%
% Project:
%   AVOLITE
%
% MATLAB:
%   R2025b
%
% Architecture:
%   RF Environment
%       -> Propagation
%       -> Antenna / Array
%       -> Adaptive RF Receiver
%       -> ADC
%       -> DSP
%       -> Detection
%       -> PDW
%       -> AoA / DOA
%       -> Environment State
%       -> Scheduler / AI

%% ============================================================
% PROJECT
% =============================================================

cfg.project.name = "AVOLITE";

cfg.project.version = "0.1.0-golden-reference";

cfg.project.matlabVersion = "R2025b";


%% ============================================================
% UNITS
% =============================================================

cfg.units.distance = "m";

cfg.units.time = "s";

cfg.units.frequency = "Hz";

cfg.units.power = "W";

cfg.units.voltage = "V";

cfg.units.current = "A";

cfg.units.temperature = "K";

% Internal angle representation
cfg.units.angleInternal = "rad";

% Display angle representation
cfg.units.angleDisplay = "deg";


%% ============================================================
% PHYSICAL CONSTANTS
% =============================================================

% Speed of light
cfg.constants.c_mps = 299792458;

% Boltzmann constant
cfg.constants.k_B_J_per_K = 1.380649e-23;

% Mathematical constant
cfg.constants.pi = pi;


%% ============================================================
% REPRODUCIBILITY
% =============================================================

cfg.random.seed = 20260926;


%% ============================================================
% SIMULATION
% =============================================================

cfg.simulation.startTime_s = 0;

% Initial reference simulation duration
cfg.simulation.stopTime_s = 0.1;

% Complex-envelope reference sample rate.
%
% IMPORTANT:
% This is NOT a direct sampling rate for a 10 GHz RF carrier.
%
% AVOLITE Golden Reference uses complex-envelope/baseband
% representation. The 100 MHz rate provides sufficient digital
% bandwidth for the configured 20 MHz RF channel.

cfg.simulation.sampleRate_Hz = 100e6;

cfg.simulation.timeStep_s = ...
    1 / cfg.simulation.sampleRate_Hz;


%% ============================================================
% SCENARIO
% =============================================================

cfg.scenario.numberOfEmitters = 8;


%% ============================================================
% PROPAGATION
% =============================================================

cfg.propagation.enableFreeSpacePathLoss = true;

cfg.propagation.enableAtmosphericLoss = false;

cfg.propagation.enableMultipath = false;

cfg.propagation.enableFading = false;

cfg.propagation.enableInterference = true;

cfg.propagation.enableNoise = true;

% Reference range for initial scenario
cfg.propagation.referenceDistance_m = 1000;

% System propagation loss factor
cfg.propagation.systemLoss_linear = 1.0;


%% ============================================================
% ENVIRONMENT / NOISE
% =============================================================

cfg.environment.temperature_K = 290;

% Additional external noise power
cfg.environment.externalNoisePower_W = 0;


%% ============================================================
% ANTENNA / ARRAY
% ============================================================

cfg.antenna.arrayType = "ULA";

% Number of physical antenna elements
cfg.antenna.numberOfElements = 4;

% Reference frequency for physical array design.
%
% IMPORTANT:
% Physical element spacing is fixed in meters.
% It is NOT recalculated for every emitter frequency.
%
% E1 at 10 GHz is used as the reference frequency.

cfg.antenna.referenceFrequency_Hz = 10e9;

% Reference wavelength
cfg.antenna.referenceWavelength_m = ...
    cfg.constants.c_mps / ...
    cfg.antenna.referenceFrequency_Hz;

% Half-wavelength spacing at the reference frequency
cfg.antenna.elementSpacing_m = ...
    cfg.antenna.referenceWavelength_m / 2;

% Default pointing direction
cfg.antenna.azimuth_deg = 0;

cfg.antenna.elevation_deg = 0;


%% ============================================================
% RF RECEIVER
% =============================================================

cfg.receiver.temperature_K = 290;

% RF front-end filter bandwidth
cfg.receiver.rfFilterBandwidth_Hz = 20e6;

% IF filter bandwidth
cfg.receiver.ifFilterBandwidth_Hz = 10e6;

% Initial local oscillator frequency.
%
% This is the initial baseline value.
% The scheduler / receiver controller will modify this later.

cfg.receiver.localOscillator_Hz = 10e9;

% Receiver gain
cfg.receiver.gain_dB = 30;

% Receiver noise figure
cfg.receiver.noiseFigure_dB = 5;

% Receiver reference impedance
cfg.receiver.referenceImpedance_ohm = 50;


%% ============================================================
% ADC
% =============================================================

cfg.receiver.adcSampleRate_Hz = 100e6;

cfg.receiver.adcBits = 14;

% ADC full-scale voltage.
%
% Convention used by Golden Reference:
%   -0.5 V <= I,Q <= +0.5 V
%
% Therefore this value represents 1 V peak-to-peak
% range per real ADC component.

cfg.receiver.adcFullScale_V = 1.0;


%% ============================================================
% DIGITAL DOWN CONVERSION
% =============================================================

cfg.dsp.ddc.enabled = true;

% Initial digital LO.
%
% This is intentionally separate from the physical RF LO.
% The DDC operates on the sampled complex-envelope signal.

cfg.dsp.ddc.loFrequency_Hz = 5e6;

% Input/output sample rate.
%
% Current Golden Reference does not decimate in the DDC.
% Therefore output sample rate equals input sample rate.

cfg.dsp.ddc.outputSampleRate_Hz = ...
    cfg.receiver.adcSampleRate_Hz;

% DDC low-pass channel bandwidth.
%
% This represents the retained complex-envelope channel.

cfg.dsp.ddc.filterBandwidth_Hz = ...
    cfg.receiver.rfFilterBandwidth_Hz;

% FIR filter order
cfg.dsp.ddc.filterOrder = 64;


%% ============================================================
% DIGITAL FILTER
% =============================================================

cfg.dsp.filter.enable = true;

cfg.dsp.filter.type = "lowpass";

cfg.dsp.filter.cutoffFrequency_Hz = 5e6;

cfg.dsp.filter.order = 64;


%% ============================================================
% FFT
% =============================================================

cfg.dsp.fftSize = 4096;

cfg.dsp.window = "hann";

cfg.dsp.enableZeroPadding = false;


%% ============================================================
% DETECTION / CFAR
% =============================================================

cfg.detection.enable = true;

cfg.detection.method = "CA-CFAR";

cfg.detection.probabilityOfFalseAlarm = 1e-6;

cfg.detection.referenceCells = 24;

cfg.detection.guardCells = 4;


%% ============================================================
% PDW
% =============================================================

cfg.pdw.enable = true;

cfg.pdw.extractToA = true;

cfg.pdw.extractFrequency = true;

cfg.pdw.extractPulseWidth = true;

cfg.pdw.extractAmplitude = true;

cfg.pdw.extractPRI = true;

cfg.pdw.extractSNR = true;


%% ============================================================
% AOA / DOA
% =============================================================

cfg.aoa.enable = true;

cfg.aoa.method = "ULA_phase_difference";

cfg.aoa.referenceAngle_deg = 0;

cfg.aoa.maxAbsAngle_deg = 90;


%% ============================================================
% ENVIRONMENT STATE
% =============================================================

cfg.environmentState.enable = true;

cfg.environmentState.calculateReceivedPower = true;

cfg.environmentState.calculateNoisePower = true;

cfg.environmentState.calculateSNR = true;

cfg.environmentState.calculateInterferencePower = true;

cfg.environmentState.calculateSpectralOccupancy = true;

cfg.environmentState.calculateDetectionRate = true;

cfg.environmentState.calculateFalseAlarmRate = true;


%% ============================================================
% BASELINE SCHEDULER
% =============================================================

cfg.scheduler.enable = true;

cfg.scheduler.mode = "baseline";

cfg.scheduler.strategy = "priority_uncertainty";

cfg.scheduler.explorationProbability = 0.20;

cfg.scheduler.defaultDwellTime_s = 1e-3;

cfg.scheduler.minimumDwellTime_s = 100e-6;

cfg.scheduler.maximumDwellTime_s = 10e-3;


%% ============================================================
% VALIDATION / VERIFICATION
% =============================================================

cfg.verification.enableAssertions = true;

% Numerical comparison tolerance used later when comparing
% MATLAB Golden Reference against Simulink implementation.

cfg.verification.relativeTolerance = 1e-6;

cfg.verification.absoluteTolerance = 1e-9;


end