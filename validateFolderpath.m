
function [VALID_PATH, MESSAGE, DATA_FILES, LABEL_FILE] = validateFolderpath(folderPath)
%==================================================================================================
% Function:    validateFolder(folderPath)
% Description: This function ensures that the specified folder only contains the following files:
%                  (1) *.data or *.mat
%                  (2) A single *.labels file
%
% Inputs:      folderPath : string
%              The folder path to be validated
%
% Outputs:     VALID_PATH : boolean
%              true (logical) if the path is valid; otherwise, false.
%              
%              MESSAGE : string
%              Message indicating why the folderpath is invalid; otherwise, empty.
%
%              DATA_FILES : string cell array
%              A row vector of files with the .data or .m extension containing time series data
%
%              LABEL_FILE    : string
%              A single filename with the .labels extension containing classification labels for
%              time series data in the corresponding data files.
%
%==================================================================================================
if getpref('TSANALYZER', 'DEBUG')
    msg = sprintf("Validing folderpath [%s]", folderPath);
    fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
end

% Flag: Enabled if an invalid file or directory is found
invalidFileFound = false;

% Get the list of file and folder names within the specified folderpath
directoryFiles = dir(strcat(folderPath));
directoryFilenames = {directoryFiles.name};

% Iterate through each element (column) of the filenames cell array, validating file extensions
n = size(directoryFilenames,2);
for i = 1:n

    % Extract the filename and extension (including the .) for each filename
    [~, filename, fileExt] = fileparts(directoryFilenames{i});

    % A switch on the filename extension '.extension'
    switch(fileExt)
        
        case '.data'    % Ignore valid .data files
        case '.mat'     % Ignore valid .mat files
        case '.labels'  % Ifnore valid .labels files
            
        % Catch extensionless files (and directories)
        case '.'

            % Catch extensionless file
            if(~isdir([folderPath '\' filename]))
                
                invalidFileFound = true;
                
                if getpref('TSANALYZER', 'DEBUG')
                    msg = sprintf("File/Folder [%s] is invalid.", [filename fileExt]);
                    fprintf("\t%s\n", msg);
                end
                
            end
            
            % Ignore directory
            if getpref('TSANALYZER', 'DEBUG')
                msg = sprintf("Ignoring directory [%s]", [filename fileExt]);
                fprintf("\t%s\n", msg);
            end

        otherwise

            invalidFileFound = true;

            if getpref('TSANALYZER', 'DEBUG')
                msg = sprintf("File/Folder [%s] is invalid.", [filename fileExt]);
                fprintf("\t%s\n", msg);
            end
    end

end

% If an invalid file (or directory) was found, empty function outputs and return
if(invalidFileFound)

    VALID_PATH = false;
    MESSAGE = "Folder path contains invalid files. Select a new folder path.";
    DATA_FILES = [];
    LABEL_FILE = "";

    if getpref('TSANALYZER', 'DEBUG')
        msg = MESSAGE;
        fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
    end

    return

end

% The folder path should contain a single labels file. If it does not, empty function output
% variables and return.
labelFiles = dir(strcat(folderPath, '\*.labels'));
labelFilenames = {labelFiles.name};

if(size(labelFilenames,1) ~= 1)

    VALID_PATH = false;
    MESSAGE    = "Folderpath must contain exactly one labels file"
    DATA_FILES = [];
    LABEL_FILE = "";

    if getpref('TSANALYZER', 'DEBUG')
        msg = MESSAGE
        fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
    end

    return

end

VALID_PATH = true;
MESSAGE = "";

dataFiles = dir(strcat(folderPath, '\*.data'));
dataFilenames = {dataFiles.name};
matFiles = dir(strcat(folderPath, '\*.mat'));
matFilenames = {matFiles.name};
DATA_FILES = [dataFilenames matFilenames];

LABEL_FILE = {labelFiles.name};


