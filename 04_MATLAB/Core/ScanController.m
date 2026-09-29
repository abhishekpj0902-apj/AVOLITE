function Scan = ScanController(ScanNumber, TotalScans, PreviousTracks)

%=========================================================
% SARRS STUDIO
% Scan Controller
%
% Controls multi-scan radar operation.
%
%=========================================================

%% ========================================================
% Validate Inputs
%=========================================================

if nargin < 1 || isempty(ScanNumber)

    ScanNumber = 1;

end

if nargin < 2 || isempty(TotalScans)

    TotalScans = 1;

end

if nargin < 3

    PreviousTracks = struct([]);

end

%% ========================================================
% Scan Information
%=========================================================

Scan.Number = ScanNumber;

Scan.TotalScans = TotalScans;

Scan.Time = ScanNumber - 1;

Scan.PulseNumber = ScanNumber;

%% ========================================================
% Scan Type
%=========================================================

if ScanNumber == 1

    Scan.Type = "Initial Search";

else

    Scan.Type = "Track Update";

end

%% ========================================================
% Previous Track Information
%=========================================================

Scan.PreviousTracks = PreviousTracks;

%% ========================================================
% Status
%=========================================================

Scan.Status = "Running";

%% ========================================================
% Display
%=========================================================

disp(' ');
disp('=========================================');
disp('RADAR SCAN CONTROLLER');
disp('=========================================');

fprintf('Scan Number : %d / %d\n', ...
    ScanNumber,TotalScans);

fprintf('Scan Time   : %.1f s\n', ...
    Scan.Time);

fprintf('Scan Type   : %s\n', ...
    Scan.Type);

fprintf('Status      : %s\n', ...
    Scan.Status);

end