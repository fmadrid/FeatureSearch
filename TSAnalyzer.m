%%==================================================================================================
% Title:      UC Riverise - Time Series Analyzer
% Author: Frank Madrid 
% Purpose:    This tool implements 'Feature Search' on a set of time series data.
% Date:       July 26th, 2017
%==================================================================================================
% Description:  
%    This application serves as the main entry-point into the feature search tool. Using
%    a graphical user interface, it requests a folderpath containg time series data information and
%    allows the user to select from many predefined features to perform a 'feature search' on the
%    time series data.
%
% Usage:
%    This application uses preferences for debugging purposes and must be defined.
%    addpref('TSANALYZER', 'DEBUG', false) -> Disables print debugging
%    addpref('TSANALYZER', 'DEBUG', true)  -> Enables print debugging
%==================================================================================================

% Matlab auto-generated function
function varargout = TSAnalyzer(varargin)
% TSANALYZER MATLAB code for TSAnalyzer.fig
%      TSANALYZER, by itself, creates a new TSANALYZER or raises the existing
%      singleton*.
%
%      H = TSANALYZER returns the handle to a new TSANALYZER or the handle to
%      the existing singleton*.
%
%      TSANALYZER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TSANALYZER.M with the given input arguments.
%
%      TSANALYZER('Property','Value',...) creates a new TSANALYZER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TSAnalyzer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TSAnalyzer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Edit the above text to modify the response to help TSAnalyzer
% Last Modified by GUIDE v2.5 25-Jul-2017 13:06:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TSAnalyzer_OpeningFcn, ...
                   'gui_OutputFcn',  @TSAnalyzer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before TSAnalyzer is made visible.
function TSAnalyzer_OpeningFcn(hObject, eventdata, handles, varargin)

    handles.output = hObject;
    guidata(hObject, handles);

    masterList = initializeFeatureSelection();

    if(isempty(masterList))

        if getpref('TSANALYZER', 'DEBUG')
            msg = sprintf("Error. Master feature list is empty.");
            fprintf("[%s] [%s]: %s\n", "TSAnalyzer_OpeningFcn", datestr(now, 'HH:MM:SS'), msg);
        end
        
        handles.availableList = {};
        handles.selectedList  = {};

        return;

    end

    % Initialize global master list, 'available features' list, and 'selected features' list
    handles.masterList    = masterList;
    handles.availableList = 1:size(masterList,1);
    handles.selectedList  = [];

    updateList('Available', handles);
    fprintf("=======================================================================================\n");
    guidata(hObject, handles);

function updateList(listName, handles)
    switch(listName)
        case 'Available'
            
            list = handles.masterList(handles.availableList, :);
            set(handles.availableFeatures,'String',list(:,2),'Value',max(handles.availableFeatures.Value - 1, 1));
        case 'Selected'
            list = handles.masterList(handles.selectedList, :);
            set(handles.selectedFeatures,'String',list(:,2),'Value',max(handles.selectedFeatures.Value - 1, 1));
    end
        
% --- Outputs from this function are returned to the command line.
function varargout = TSAnalyzer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
% UNUSED

function menuDatasets_Callback(hObject, eventdata, handles)
% UNUSED

% Menu: [Datasets] -> [Import]
function menuDatasetsImport_Callback(hObject, eventdata, handles)

    if getpref('TSANALYZER', 'DEBUG')
        msg = "Event - getting directory from user.";
        fprintf('[%s] - %s: %s\n', 'menuDatasetsImport', datestr(now, 'HH:MM:SS'), msg);
    end
    
    folderPath = getDatasetFolderPath();
    
    % If no folder path was specified, then break out of the function; otherwise, validate the folder
    % path
    if(strcmp(folderPath, ""))
        return;
    end
    
    % Ensures the specified folder path is a valid dataset folder source
    [isValidFolder, ~, dataFiles, labelFile] = validateFolderpath(folderPath);
    
    % If the folder path is not valid, output an error and return.
    if(~isValidFolder)
        msg = sprintf('Path [%s] is an invalid folder path.', folderPath);
        set(handles.textAreaDataStatistics, 'string', msg);
        return;
    end

    % Ensures the time series and classification data within the folder path is valid
    [isValidData, errMessage, data] = validateTimeSeries(folderPath, dataFiles, labelFile);

    % If the folder path is not valid, output an error and return.
    if(~isValidData)
        msg = sprintf('Folder path contains invalid data.');
        set(handles.textAreaDataStatistics, 'string', msg);
        return;
    end
    
    % Store time series data globally
    handles.data = data;
    
    % Formats time series data into a tabular format to be displayed in the main data text area
    [output] = formatTimeSeriesData(data);
    set(handles.textAreaDataStatistics, 'String', strjoin(output, '\n'));
    
    % Updates global variables
    guidata(hObject, handles);
    
    fprintf("=======================================================================================\n");

function [FOLDER_PATH] = getDatasetFolderPath()
    % Helper function to menuDatasetsImport_Callback. Returns a folder path as specified by the
    %user-interface get directory system explorer window native to the operating system.
    
    folderPath = uigetdir;  % Returns 0 if 'Cancel' or window is closed
    
      % If no folder path was specified
    if(folderPath == 0)
    	folderPath = "";
    end

    FOLDER_PATH = folderPath;
  
function [OUTPUT] = formatTimeSeriesData(data)
    % Helper function to menuDatasetsImport_Callback. Formats 'data' into a tabular displaying
    % information including the time series internal identification number, name, number of samples
    % (measurements), the length of each measurement (columns), and the number of NaNs in the data
    
    % Preallocate cell array
    output = cell(1, 2 + size(data,2));
    
    % Table Header
    output{1} = sprintf('%-4s%-54s%-9s%-8s%-4s', "ID", 'Name', 'Samples', 'Length', 'NaNs');
    output{2} = sprintf('--------------------------------------------------------------------------------');
    
    % Format table data
    n = size(data,2);
    for i = 1:n
        output{i+2} = sprintf('%-4d%-54s %-9d%-8d%-4d', ...
            data{i}.ID, data{i}.name, data{i}.sampleSize, data{i}.length, data{i}.nanCount);
    end
    
    OUTPUT = output;
    
function textAreaDataStatistics_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% UNUSED

function textAreaDataStatistics_Callback(hObject, eventdata, handles)
% UNUSED

function search(query, hObject, handles)
% Helper function to searchFeatures_Callback. Filters the list of available features to those
% containing the substring in the search query field (if any) and those features not already in the
% selected features list

    % Get the list of all feature names
    featureNames = handles.masterList(:, 2);
    
    % Preallocate the 'hits' array
    hits = zeros(1,size(featureNames,2));
    
    % Iterate through each feature name
    for i = 1:size(featureNames)
        
        % Get the index of the element which contains the feature name
        index = findstr(query, featureNames{i});
        
        % If the index is non-zero or the query field is empty
        if(any(index ~= 0) || strcmp(query, ""))
            
            % If the index is not already in the selected features list
            if(~any(handles.selectedList == i))
                hits(i) = i;    % Add the element to our array of hits
            end
        end
    end

    % Remove all zero elements from the list
    hits = hits(hits ~= 0);
    
    % If no hits were found, 
    if(isempty(hits))
        return;
    end

    handles.availableList = hits;
    guidata(hObject, handles);
    
    updateList('Available', handles);
       
function searchFeatures_Callback(hObject, eventdata, handles)
% Called when the user hits [ENTER] in the 'Search for a Feature" text field. Runs a search of the
% set of available features for those that contain the substring specified in the text field.
% Searching for the empty string will instead display all available features.

    % Gets the query string from the input field
    query = get(hObject, 'String');
    
    % Runs a search on the list of available features which match the query string
    search(query, hObject, handles);

function searchFeatures_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% UNUSED

function buttonSearchFeatures_Callback(hObject, eventdata, handles)
% Called when the user hits [ENTER] in the 'Search for a Feature" text field. Runs a search of the
% set of available features for those that contain the substring specified in the text field.
% Searching for the empty string will instead display all available features.

    % Gets the query string from the input field
    query = get(hObject, 'String');
    
    % Runs a search on the list of available features which match the query string
    search(query, hObject, handles);
    
function categoryFeatures_Callback(hObject, eventdata, handles)
% UNUSED

function categoryFeatures_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% UNUSED

function selectedFeatures_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectedFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% UNUSED

function availableFeatures_Callback(hObject, eventdata, handles)

    if(isempty(handles.availableList))
        return;
    end

    get(handles.figure1,'SelectionType');

    indexSelected = handles.availableFeatures.Value;
    masterCell = handles.masterList(handles.availableList(indexSelected),1);
    masterIndex = masterCell{1};

    if strcmp(get(handles.figure1,'SelectionType'),'open')

        msg = sprintf("Adding [%s] to the selected features.", handles.masterList{masterIndex,2});
        fprintf("[%s] [%s]: %s\n", "availableFeatures_Callback", datestr(now, 'HH:MM:SS'), msg);

        [~,index] = find(handles.availableList == masterIndex);
        handles.availableList(index) = [];
        list = handles.masterList(handles.availableList, :);
        set(handles.availableFeatures,'String',list(:,2),'Value', max(indexSelected - 1, 1));
        
        handles.selectedList = [handles.selectedList masterIndex];
        handles.selectedList = sort(handles.selectedList);
        list = handles.masterList(handles.selectedList, :);
        set(handles.selectedFeatures,'String',list(:,2),'Value',size(handles.selectedList,2));

    end

    guidata(hObject, handles);

function selectedFeatures_Callback(hObject, eventdata, handles)

    if(~(size(handles.selectedList,2) > 0))
        return;
    end

    get(handles.figure1,'SelectionType');

    indexSelected = handles.selectedFeatures.Value;
    masterCell = handles.masterList(handles.selectedList(indexSelected),1);
    masterIndex = masterCell{1};

    if strcmp(get(handles.figure1,'SelectionType'),'open')

        msg = sprintf("Removing [%s] from selected features.", handles.masterList{masterIndex,2});
        fprintf("[%s] [%s]: %s\n", "selectedFeatures_Callback", datestr(now, 'HH:MM:SS'), msg);

        [~,index] = find(handles.selectedList == masterIndex);
        handles.selectedList(index) = [];
        list = handles.masterList(handles.selectedList, :);
        set(handles.selectedFeatures,'String',list(:,2),'Value', max(indexSelected, 1));

        handles.availableList = [handles.availableList masterIndex];
        handles.availableList = sort(handles.availableList);
        list = handles.masterList(handles.availableList, :);
        set(handles.availableFeatures,'String',list(:,2),'Value',size(handles.availableList,2));

    end

    guidata(hObject, handles);

function availableFeatures_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');   
end
%UNUSED
function buttonAddFeature_Callback(hObject, eventdata, handles)
    addSelectedFeature(hObject, handles);
    
function buttonRemoveFeature_Callback(hObject, eventdata, handles)
    addAvailableFeature(hObject, handles)

function buttonAddAll_Callback(hObject, eventdata, handles)

    msg = sprintf("Adding all available features.");
    fprintf("[%s] [%s]: %s\n", "availableFeatures_Callback", datestr(now, 'HH:MM:SS'), msg);
    
    for i = 1:size(handles.availableList,2)
        handles.selectedList = [handles.selectedList handles.availableList(i)];
    end
    
    handles.availableList = [];
    list = handles.masterList(handles.availableList, :);
    set(handles.availableFeatures,'String',list(:,2),'Value', 1);
    
    handles.selectedList = sort(handles.selectedList);
    list = handles.masterList(handles.selectedList, :);
    set(handles.selectedFeatures,'String',list(:,2),'Value',size(handles.selectedList,2));

    guidata(hObject, handles);
    
function buttonRemoveAll_Callback(hObject, eventdata, handles)

    msg = sprintf("Removing all selected features.");
    fprintf("[%s] [%s]: %s\n", "availableFeatures_Callback", datestr(now, 'HH:MM:SS'), msg);
    
    for i = 1:size(handles.selectedList,2)
        handles.availableList = [handles.availableList handles.selectedList(i)];
    end
    
    handles.selectedList = [];
    list = handles.masterList(handles.selectedList, :);
    set(handles.selectedFeatures,'String',list(:,2),'Value', 1);
    
    handles.availableList = sort(handles.availableList);
    list = handles.masterList(handles.availableList, :);
    set(handles.availableFeatures,'String',list(:,2),'Value',size(handles.availableList,2));

    guidata(hObject, handles);

function cboxGenerateLogfile_Callback(hObject, eventdata, handles)

function cboxCloseOnCompletion_Callback(hObject, eventdata, handles)

function buttonExecute_Callback(hObject, eventdata, handles)

    currentFolder = pwd;
    DEFAULT_FEATURES = strcat(currentFolder, '\RootFolder\Features\Default\');
    CUSTOM_FEATURES  = strcat(currentFolder, '\RootFolder\Features\Custom\');
    
    list = handles.masterList(handles.selectedList, :);
    analyzer(handles.data, list(:,2), DEFAULT_FEATURES, CUSTOM_FEATURES);
    
function menuDatasetsExport_Callback(hObject, eventdata, handles)

function menuFeatures_Callback(hObject, eventdata, handles)

function menuFeaturesSave_Callback(hObject, eventdata, handles)

function menuFeaturesLoad_Callback(hObject, eventdata, handles)

function [MASTER_LIST] = initializeFeatureSelection()
% This function compiles and returns a list of available features.
%
% Output
%     MASTER_LIST : cell array
%       id : int
%       Internal identification number
%
%       name : string
%       Visible name within the 'Available Features' list
%
%       sourceFile : string
%       The matlab source file the feature is defined in

    currentFolder = pwd;
    DEFAULT_FEATURES = strcat(currentFolder, '\RootFolder\Features\Default\');
    CUSTOM_FEATURES  = strcat(currentFolder, '\RootFolder\Features\Custom\');
    
    if getpref('TSANALYZER', 'DEBUG')
        msg = sprintf("Compiling master feature list: %s", DEFAULT_FEATURES);
        fprintf("[%s] [%s]: %s\n", "initializeFeatureSelection", datestr(now, 'HH:MM:SS'), msg);
    end
    
    % Preallocate a SIZE x 3 cell array to hold feature information
    sz = size( dir(strcat(DEFAULT_FEATURES,'*.m')) , 1) + size( dir(strcat(CUSTOM_FEATURES,'*.m')) , 1);
    MASTER_LIST = cell(sz,3);
    
    % Assign a unique integer ID to each feature
    for i = 1:sz
        MASTER_LIST(i,1) = {i};
    end
    
    % If DEFAULT_FEATURES is a valid directory
    if(isdir(DEFAULT_FEATURES))
        
        % Get and store the file names of each *.m file within the DEFAULT_FEATURES folder
        filenames = dir(strcat(DEFAULT_FEATURES,'*.m'));
        filenames = {filenames.name};

        % Populate the first 'n' rows of the MASTER_LIST
        n = size(filenames,2);
        for i = 1 : n
            [~, fname, ~] = fileparts(filenames{i});
            MASTER_LIST(i,2) = {fname};
            MASTER_LIST(i,3) = {strcat(DEFAULT_FEATURES, filenames{i})};
        end
        
    else
        
        msg = sprintf("Invalid default features folder");
        fprintf("[%s] [%s]: %s\n", "initializeFeatureSelection", datestr(now, 'HH:MM:SS'), msg);
        
        MASTER_LIST = {};
        
        return
        
    end
    
    % If CUSTOM_FEATURES is a valid directory
    if(isdir(CUSTOM_FEATURES))
        
        % Get and store the file names of each *.m file within the CUSTOM_FEATURES folder
        filenames = dir(strcat(CUSTOM_FEATURES,'*.m'));
        filenames = {filenames.name};

        % Populate the reamining m = SIZE - 'n' rows of the MASTER_LIST
        m = size(filenames,2);
        for i = 1 : m
            [~, fname, ~] = fileparts(filenames{i});
            MASTER_LIST(i + n, 2) = {fname};
            MASTER_LIST(i + n, 3) = {strcat(CUSTOM_FEATURES, filenames{i})};
        end
        
    else
        
        msg = sprintf("Invalid custom features folder");
        fprintf("[%s] [%s]: %s\n", "initializeFeatureSelection", datestr(now, 'HH:MM:SS'), msg);
        
        MASTER_LIST = {};
        
        return
        
    end
    
function addAvailableFeature(hObject, handles)

    if(~(size(handles.selectedList,2) > 0))
        return;
    end

    indexSelected = handles.selectedFeatures.Value;

    masterCell = handles.masterList(handles.selectedList(indexSelected),1);
    masterIndex = masterCell{1};

    msg = sprintf("Removing [%s] to the selected features.", handles.masterList{masterIndex,2});
    fprintf("[%s] [%s]: %s\n", "availableFeatures_Callback", datestr(now, 'HH:MM:SS'), msg);
    
    [~,index] = find(handles.selectedList == masterIndex);

    handles.selectedList(index) = [];
    list = handles.masterList(handles.selectedList, :);
    set(handles.selectedFeatures,'String',list(:,2),'Value', max(indexSelected - 1, 1));

    handles.availableList = [handles.availableList masterIndex];
    handles.availableList = sort(handles.availableList);
    list = handles.masterList(handles.availableList, :);
    set(handles.availableFeatures,'String',list(:,2),'Value',size(handles.availableList,2));

    guidata(hObject, handles);

function addSelectedFeature(hObject, handles)

    if(~size(handles.availableList,2) > 0)
        return;
    end
    
    indexSelected = handles.availableFeatures.Value;
    masterCell = handles.masterList(handles.availableList(indexSelected),1);
    masterIndex = masterCell{1};

    if(size(handles.selectedList,1) > 0)
        if(find(handles.selectedList == masterIndex))
            return;
        end
    end
    
    msg = sprintf("Adding [%s] to the selected features.", handles.masterList{masterIndex,2});
    fprintf("[%s] [%s]: %s\n", "availableFeatures_Callback", datestr(now, 'HH:MM:SS'), msg);

    [~,index] = find(handles.availableList == masterIndex);
    
    handles.availableList(index) = [];
    list = handles.masterList(handles.availableList, :);
    set(handles.availableFeatures,'String',list(:,2),'Value', max(indexSelected - 1, 1));
    
    handles.selectedList = [handles.selectedList masterIndex];
    handles.selectedList = sort(handles.selectedList);
    list = handles.masterList(handles.selectedList, :);
    set(handles.selectedFeatures,'String',list(:,2),'Value',size(handles.selectedList,2));
    
    guidata(hObject, handles);