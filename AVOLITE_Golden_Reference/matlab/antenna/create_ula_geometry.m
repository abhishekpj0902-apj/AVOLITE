function array = create_ula_geometry(cfg)
%CREATE_ULA_GEOMETRY Create physical uniform linear array geometry.
%
% Coordinate convention:
%   X-axis = array axis
%   Y-axis = broadside direction
%   Z-axis = vertical
%
% Element positions are fixed physical locations.
%
% Inputs:
%   cfg - AVOLITE configuration
%
% Output:
%   array - ULA geometry structure

%% ============================================================
% INPUT VALIDATION
% =============================================================

N = cfg.antenna.numberOfElements;

d = cfg.antenna.elementSpacing_m;

if N < 2 || floor(N) ~= N
    error( ...
        'create_ula_geometry:InvalidElementCount', ...
        'Number of antenna elements must be an integer >= 2.');
end

if ~isfinite(d) || d <= 0
    error( ...
        'create_ula_geometry:InvalidSpacing', ...
        'Element spacing must be positive.');
end

%% ============================================================
% ELEMENT POSITIONS
% =============================================================

elementIndex = (0:N-1).';

x_m = elementIndex * d;

y_m = zeros(N,1);

z_m = zeros(N,1);

position_m = [x_m y_m z_m];

%% ============================================================
% OUTPUT
% =============================================================

array.type = "ULA";

array.numberOfElements = N;

array.elementSpacing_m = d;

array.elementIndex = elementIndex;

array.position_m = position_m;

array.referenceFrequency_Hz = ...
    cfg.antenna.referenceFrequency_Hz;

array.referenceWavelength_m = ...
    cfg.antenna.referenceWavelength_m;

end