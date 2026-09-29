function Scan = ScanManager(ScanNumber, PreviousTracks)

%=========================================================
% SARRS STUDIO
% Multi-Scan Manager
%
% Controls radar scan timing and scan state.
%
%=========================================================

Scan.Number = ScanNumber;

Scan.Time = (ScanNumber - 1);

Scan.PreviousTracks = PreviousTracks;

if ScanNumber == 1

    Scan.Type = "Initial Search";

else

    Scan.Type = "Track Update";

end

Scan.Status = "Running";

disp(' ');
disp('=========================================');
disp('Radar Scan');
disp('=========================================');

fprintf('Scan Number : %d\n',Scan.Number);
fprintf('Scan Time   : %.1f s\n',Scan.Time);
fprintf('Scan Type   : %s\n',Scan.Type);

end