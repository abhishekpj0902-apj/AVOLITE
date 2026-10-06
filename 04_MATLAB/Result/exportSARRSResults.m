function exportSARRSResults(results, outputDir)
% ==============================================================
% SARRS - FINAL RESULT EXPORTER
%
% Generates:
%   1. Excel engineering results workbook
%   2. Receiver IC adaptive tuning report
%   3. Result figures
%   4. MAT dataset
%   5. CSV master dataset
%
% Output:
%   D:\SARRS_STUDIO\Result_doc
% ==============================================================

clc;

fprintf('\n');
fprintf('============================================================\n');
fprintf('       SARRS FINAL RESULT EXPORT\n');
fprintf('============================================================\n');

%% -------------------------------------------------------------
% Output directories
% --------------------------------------------------------------

if nargin < 2 || isempty(outputDir)

    outputDir = 'D:\SARRS_STUDIO\Result_doc';

end

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

figureDir = fullfile(outputDir, 'Figures');

if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end

fprintf('Output directory:\n%s\n\n', outputDir);


%% -------------------------------------------------------------
% 1. Save complete MATLAB dataset
% --------------------------------------------------------------

matFile = fullfile(outputDir, ...
    'SARRS_Radar_Dataset.mat');

save(matFile, 'results', '-v7.3');

fprintf('[1/5] MAT dataset saved.\n');


%% -------------------------------------------------------------
% 2. Build engineering tables
% --------------------------------------------------------------

targetTable = buildTargetTable(results);

receiverTable = buildReceiverTable(results);

dopplerTable = buildDopplerTable(results);

matchedFilterTable = buildMatchedFilterTable(results);

adaptiveTable = buildAdaptiveTable(results);

performanceTable = buildPerformanceTable(results);


%% -------------------------------------------------------------
% 3. Excel workbook
% --------------------------------------------------------------

excelFile = fullfile(outputDir, ...
    'SARRS_Radar_Results.xlsx');

% Delete old file so stale sheets do not remain
if exist(excelFile, 'file')
    delete(excelFile);
end

writetable(targetTable, ...
    excelFile, ...
    'Sheet', 'Target_Track');

writetable(receiverTable, ...
    excelFile, ...
    'Sheet', 'Radar_Sensing');

writetable(dopplerTable, ...
    excelFile, ...
    'Sheet', 'Doppler_Analysis');

writetable(matchedFilterTable, ...
    excelFile, ...
    'Sheet', 'Matched_Filter');

writetable(adaptiveTable, ...
    excelFile, ...
    'Sheet', 'Adaptive_Receiver');

writetable(performanceTable, ...
    excelFile, ...
    'Sheet', 'Performance');

fprintf('[2/5] Excel workbook generated.\n');


%% -------------------------------------------------------------
% 4. Generate figures
% --------------------------------------------------------------

generateFigures(results, figureDir);

fprintf('[3/5] Figures generated.\n');


%% -------------------------------------------------------------
% 5. Master CSV
% --------------------------------------------------------------

csvFile = fullfile(outputDir, ...
    'SARRS_Radar_Dataset.csv');

try

    masterTable = combineTables( ...
        targetTable, ...
        receiverTable, ...
        adaptiveTable);

    writetable(masterTable, csvFile);

catch ME

    warning('Master CSV could not be generated: %s', ME.message);

end

fprintf('[4/5] CSV dataset generated.\n');


%% -------------------------------------------------------------
% 6. Receiver IC report
% --------------------------------------------------------------

reportFile = fullfile(outputDir, ...
    'SARRS_Receiver_IC_Adaptive_Report.docx');

generateReceiverReport(results, ...
                       reportFile, ...
                       figureDir);

fprintf('[5/5] Receiver IC report generated.\n');


%% -------------------------------------------------------------
% Finished
% --------------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('SARRS EXPORT COMPLETE\n');
fprintf('============================================================\n');

fprintf('\nExcel:\n%s\n', excelFile);

fprintf('\nReceiver IC Report:\n%s\n', reportFile);

fprintf('\nFigures:\n%s\n', figureDir);

fprintf('\nMAT Dataset:\n%s\n', matFile);

fprintf('\nCSV Dataset:\n%s\n', csvFile);

fprintf('\n============================================================\n');


end