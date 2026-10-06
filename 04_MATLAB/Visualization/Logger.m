function Logger(Environment,...
                Mission,...
                Radar,...
                TrackData)

%=========================================================
% SARRS STUDIO
% Simulation Logger
%
% Saves Simulation Results
%=========================================================

%% Log Folder

LogFolder = fullfile(fileparts(mfilename('fullpath')),...
    '..','Logs');

if ~exist(LogFolder,'dir')
    mkdir(LogFolder);
end

%% File Name

TimeStamp = datestr(now,'yyyy_mm_dd_HH_MM_SS');

LogFile = fullfile(LogFolder,...
    ['Simulation_',TimeStamp,'.txt']);

fid = fopen(LogFile,'w');

if fid==-1

    warning('Unable to create log file.');

    return

end

%% ======================================================
% Header
%======================================================

fprintf(fid,'=========================================\n');
fprintf(fid,'         SARRS STUDIO LOG FILE\n');
fprintf(fid,'=========================================\n\n');

fprintf(fid,'Simulation Time : %s\n\n',datestr(now));

%% ======================================================
% Mission
%======================================================

fprintf(fid,'MISSION\n');
fprintf(fid,'-----------------------------------------\n');

fprintf(fid,'Mode        : %s\n',char(Mission.Mode));
fprintf(fid,'Type        : %s\n',char(Mission.Type));
fprintf(fid,'Priority    : %s\n',char(Mission.Priority));
fprintf(fid,'Max Range   : %.0f m\n',Mission.MaxRange);

fprintf(fid,'\n');

%% ======================================================
% Environment
%======================================================

fprintf(fid,'ENVIRONMENT\n');
fprintf(fid,'-----------------------------------------\n');

fprintf(fid,'Temperature : %.1f C\n',Environment.Temperature);
fprintf(fid,'Humidity    : %.1f %%\n',Environment.Humidity);
fprintf(fid,'Pressure    : %.0f hPa\n',Environment.Pressure);
fprintf(fid,'Wind        : %.1f\n',Environment.Wind);
fprintf(fid,'Terrain     : %s\n',char(Environment.Terrain));
fprintf(fid,'Jamming     : %s\n',char(Environment.Jamming));

fprintf(fid,'\n');

%% ======================================================
% Radar
%======================================================

fprintf(fid,'RADAR\n');
fprintf(fid,'-----------------------------------------\n');

fprintf(fid,'Frequency   : %.2f GHz\n',Radar.Frequency/1e9);
fprintf(fid,'Power       : %.0f W\n',Radar.Power);
fprintf(fid,'Gain        : %.1f dB\n',Radar.Gain);
fprintf(fid,'Bandwidth   : %.2f MHz\n',Radar.Bandwidth/1e6);
fprintf(fid,'PRF         : %.0f Hz\n',Radar.PRF);

fprintf(fid,'\n');

%% ======================================================
% Tracks
%======================================================

fprintf(fid,'TRACKS\n');
fprintf(fid,'-----------------------------------------\n');

fprintf(fid,'Number of Tracks : %d\n\n',length(TrackData));

for k = 1:length(TrackData)

    fprintf(fid,'Track %d\n',TrackData(k).TrackID);

    fprintf(fid,'Range      : %.2f m\n',TrackData(k).Range);

    fprintf(fid,'Amplitude  : %.4f\n',TrackData(k).Amplitude);

    fprintf(fid,'Status     : %s\n',char(TrackData(k).Status));

    fprintf(fid,'Age        : %d\n',TrackData(k).Age);

    fprintf(fid,'\n');

end

%% Footer

fprintf(fid,'=========================================\n');
fprintf(fid,'End of Simulation Log\n');
fprintf(fid,'=========================================\n');

fclose(fid);

disp(' ');
disp('=========================================');
disp('Simulation Log Saved');
disp(LogFile);
disp('=========================================');
disp(' ');

end