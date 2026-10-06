function init_AVOLITE_Golden_Reference()
%INIT_AVOLITE_GOLDEN_REFERENCE Initialize repository paths.

projectRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(projectRoot);
addpath(genpath(fullfile(projectRoot,"matlab")));
addpath(fullfile(projectRoot,"config"));

savepath;

fprintf('\nAVOLITE Golden Reference initialized.\n');
fprintf('Root: %s\n', projectRoot);
end
