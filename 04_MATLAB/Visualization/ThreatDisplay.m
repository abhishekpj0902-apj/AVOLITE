function ThreatDisplay(TrackData)

%=========================================================
% SARRS STUDIO
% Threat Display
%=========================================================

figure( ...
    'Name','Threat Display', ...
    'NumberTitle','off', ...
    'Color','w', ...
    'Position',[300 150 900 350]);

%% No Targets

if isempty(TrackData)

    uicontrol( ...
        'Style','text', ...
        'String','NO TARGETS DETECTED', ...
        'FontSize',16, ...
        'ForegroundColor','r', ...
        'BackgroundColor','w', ...
        'Units','normalized', ...
        'Position',[0.25 0.45 0.5 0.1]);

    return;

end

%% Create Table

N = length(TrackData);

Data = cell(N,6);

for k = 1:N

    %------------------------------
    % Track ID
    %------------------------------

    Data{k,1} = TrackData(k).TrackID;

    %------------------------------
    % Range
    %------------------------------

    Data{k,2} = round(TrackData(k).Range);

    %------------------------------
    % Amplitude
    %------------------------------

    Data{k,3} = round(TrackData(k).Amplitude,3);

    %------------------------------
    % Threat Level
    %------------------------------

    if TrackData(k).Range < 60000

        Threat = 'HIGH';

    elseif TrackData(k).Range < 90000

        Threat = 'MEDIUM';

    else

        Threat = 'LOW';

    end

    Data{k,4} = Threat;

    %------------------------------
    % Status
    %------------------------------

    if isstring(TrackData(k).Status)

        Data{k,5} = char(TrackData(k).Status);

    elseif ischar(TrackData(k).Status)

        Data{k,5} = TrackData(k).Status;

    else

        Data{k,5} = 'UNKNOWN';

    end

    %------------------------------
    % Age
    %------------------------------

    Data{k,6} = TrackData(k).Age;

end

%% Display Table

uitable( ...
    'Parent',gcf, ...
    'Data',Data, ...
    'ColumnName',{ ...
        'Track ID', ...
        'Range (m)', ...
        'Amplitude', ...
        'Threat', ...
        'Status', ...
        'Age'}, ...
    'Units','normalized', ...
    'Position',[0.02 0.05 0.96 0.90], ...
    'FontSize',11);

end