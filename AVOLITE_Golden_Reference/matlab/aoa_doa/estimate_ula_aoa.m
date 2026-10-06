function [estimatedAngle_deg, info] = estimate_ula_aoa( ...
    x_array, ...
    frequency_Hz, ...
    geometry, ...
    cfg)
%ESTIMATE_ULA_AOA Estimate azimuth AoA using ULA phase differences.
%
% AVOLITE Golden Reference
%
% Inputs:
%   x_array      : array element signals
%                  [samples x elements]
%   frequency_Hz : signal frequency [Hz]
%   geometry     : output of create_ula_geometry()
%   cfg          : AVOLITE configuration
%
% Outputs:
%   estimatedAngle_deg : estimated azimuth angle [deg]
%   info               : estimation diagnostics
%
% Method:
%   Adjacent-element phase-difference estimation.
%
% IMPORTANT:
%   This estimator does not use emitter ground truth.

%% ============================================================
% INPUT VALIDATION
% =============================================================

if ~isnumeric(x_array) || isempty(x_array)

    error( ...
        'estimate_ula_aoa:InvalidArraySignal', ...
        'x_array must be a non-empty numeric matrix.');

end

if ~isscalar(frequency_Hz) || ...
        ~isnumeric(frequency_Hz) || ...
        ~isfinite(frequency_Hz) || ...
        frequency_Hz <= 0

    error( ...
        'estimate_ula_aoa:InvalidFrequency', ...
        'frequency_Hz must be positive and finite.');

end

if ~isstruct(geometry)

    error( ...
        'estimate_ula_aoa:InvalidGeometry', ...
        'geometry must be a structure.');

end

if ~isstruct(cfg)

    error( ...
        'estimate_ula_aoa:InvalidConfiguration', ...
        'cfg must be a structure.');

end

%% ============================================================
% REQUIRED GEOMETRY FIELDS
% =============================================================

requiredGeometryFields = { ...
    'numberOfElements', ...
    'elementSpacing_m', ...
    'position_m'};

for k = 1:numel(requiredGeometryFields)

    fieldName = ...
        requiredGeometryFields{k};

    if ~isfield(geometry,fieldName)

        error( ...
            'estimate_ula_aoa:MissingGeometryField', ...
            'Missing geometry field: %s', ...
            fieldName);

    end

end

%% ============================================================
% ARRAY DIMENSION CHECK
% =============================================================

numberOfElements = ...
    geometry.numberOfElements;

if size(x_array,2) ~= numberOfElements

    error( ...
        'estimate_ula_aoa:ArrayDimensionMismatch', ...
        ['x_array has %d elements but geometry specifies %d.'], ...
        size(x_array,2), ...
        numberOfElements);

end

if numberOfElements < 2

    error( ...
        'estimate_ula_aoa:InsufficientElements', ...
        'At least two ULA elements are required.');

end

%% ============================================================
% ULA SPACING
% =============================================================

elementSpacing_m = ...
    geometry.elementSpacing_m;

if ~isscalar(elementSpacing_m) || ...
        ~isfinite(elementSpacing_m) || ...
        elementSpacing_m <= 0

    error( ...
        'estimate_ula_aoa:InvalidSpacing', ...
        'Element spacing must be positive and finite.');

end

%% ============================================================
% WAVELENGTH
% =============================================================

c_mps = ...
    cfg.constants.c_mps;

lambda_m = ...
    c_mps / frequency_Hz;

%% ============================================================
% PHASE DIFFERENCE
% ============================================================
%
% Existing AVOLITE steering convention:
%
%   a_n = exp(-j*k*x_n*sin(theta))
%
% Therefore adjacent elements have phase difference:
%
%   Delta_phi = -k*d*sin(theta)
%
% Hence:
%
%   sin(theta) =
%       -Delta_phi / (k*d)

x_array = ...
    x_array;

%% ============================================================
% REMOVE DC OFFSET / USE SAMPLE MEAN
% =============================================================

elementMean = ...
    mean(x_array,1);

%% ============================================================
% ADJACENT ELEMENT PHASE DIFFERENCES
% =============================================================

adjacentPhaseDifference_rad = ...
    zeros(numberOfElements-1,1);

for k = 1:numberOfElements-1

    crossProduct = ...
        conj(elementMean(k)) * ...
        elementMean(k+1);

    adjacentPhaseDifference_rad(k) = ...
        angle(crossProduct);

end

%% ============================================================
% PHASE DIFFERENCE AVERAGING
% =============================================================

phaseDifference_rad = ...
    mean(adjacentPhaseDifference_rad);

%% ============================================================
% ANGLE ESTIMATION
% =============================================================

wavenumber_rad_per_m = ...
    2*pi / lambda_m;

sinTheta = ...
    -phaseDifference_rad / ...
    (wavenumber_rad_per_m * elementSpacing_m);

%% ============================================================
% NUMERICAL CLAMP
% =============================================================

sinThetaClamped = ...
    min(max(sinTheta,-1),1);

estimatedAngle_rad = ...
    asin(sinThetaClamped);

estimatedAngle_deg = ...
    rad2deg(estimatedAngle_rad);

%% ============================================================
% CONFIGURED ANGLE LIMIT
% =============================================================

if isfield(cfg,'aoa') && ...
        isfield(cfg.aoa,'maxAbsAngle_deg')

    maxAbsAngle_deg = ...
        cfg.aoa.maxAbsAngle_deg;

else

    maxAbsAngle_deg = 90;

end

estimatedAngle_deg = ...
    min(max( ...
        estimatedAngle_deg, ...
        -maxAbsAngle_deg), ...
        maxAbsAngle_deg);

%% ============================================================
% ARRAY PHASE CONSISTENCY
% =============================================================

phaseDifferenceResidual_rad = ...
    adjacentPhaseDifference_rad - ...
    phaseDifference_rad;

%% ============================================================
% DIAGNOSTICS
% =============================================================

info = struct();

info.method = ...
    "ULA_phase_difference";

info.frequency_Hz = ...
    frequency_Hz;

info.wavelength_m = ...
    lambda_m;

info.elementSpacing_m = ...
    elementSpacing_m;

info.numberOfElements = ...
    numberOfElements;

info.phaseDifference_rad = ...
    phaseDifference_rad;

info.phaseDifference_deg = ...
    rad2deg(phaseDifference_rad);

info.adjacentPhaseDifference_rad = ...
    adjacentPhaseDifference_rad;

info.phaseDifferenceResidual_rad = ...
    phaseDifferenceResidual_rad;

info.sinThetaRaw = ...
    sinTheta;

info.sinThetaClamped = ...
    sinThetaClamped;

info.estimatedAngle_rad = ...
    estimatedAngle_rad;

info.estimatedAngle_deg = ...
    estimatedAngle_deg;

info.maxAbsAngle_deg = ...
    maxAbsAngle_deg;

info.groundTruthUsed = ...
    false;

end