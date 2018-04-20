%==================================================================================================
% Function:    validateTimeSeries(dataFileNames, labelFileNames, propertyFile)
% Description: This function ensures that the specified time series is valid
%                  (1) Time series data sample size and corresponding classification count must be
%                      equal
%                  (2) Assumes is readable by MatLab's load function (ASCII XYZ or .mat files)

% Inputs:      dataFileNames : cell array string
%              A row vector of time series data file names.
%
%              labelFileNames : cell array string
%              A row vector of time series data classification file names.
%
%              propertyFile : cell array string
%              A row vector of time series property file names.
%
% Outputs:     VALID_PATH : boolean
%              true (logical) if the time series is valid; otherwise, false.
%              
%              MESSAGE : string
%              Message indicating why the time series data is invalid; otherwise, empty.
%
%              DATA : struct(name, data, labels, samplesize, length, NaNCount) cell array
%              Time series struct [i] can be accessed using DATA{i}.
%==================================================================================================
function [VALID_DATA, MESSAGE, DATA] = validateTimeSeries(folderPath, dataFileNames, labelFileName)

  if getpref('TSANALYZER', 'DEBUG')
    msg = sprintf("Validating time series data.");
    fprintf("\n[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
  end

  % Preallocate cellarray to hold data structures. Each data file will have its own structure
  timeSeriesCount = size(dataFileNames,2);
  DATA = cell(1,timeSeriesCount);
  labelFileName = strcat('\', string(labelFileName));
  
  labelIn = load(strcat(folderPath, labelFileName)); % Read classification data from the label file
  rowCountLabel = size(labelIn, 1);
  
  % Iterate through each data file (and label file)
  for i = 1:timeSeriesCount
      
      if getpref('TSANALYZER', 'DEBUG')
        msg = sprintf("Reading time series data and label data [%s] ", dataFileNames{i});
        fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
      end
      
      folderPath = strcat(folderPath, '\');
      dataIn  = load(strcat(folderPath, dataFileNames{i}));  % Read time series data from the data file
      
      
      % Get the time series sample size and classification count
      rowCountData = size(dataIn, 1);
      
      % If there are a different amount of time series samples and classifications, invalidate data
      % and return
      if(rowCountData ~= rowCountLabel)
          
          VALID_DATA = false;
          MESSAGE    = sprintf("Time series [%s] (%d entries) and labels [%s] (%d entries) must have the same number of entries.", dataFileNames{i}, rowCountData, labelFileName, rowCountLabel);
          DATA = {};
          
          if getpref('TSANALYZER', 'DEBUG')
              msg = MESSAGE;
              fprintf("[%s] [%s]: %s.\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
          end
          
          return
          
      end

      % Fill data structure with appropriate data
      d.ID   = i;                               % Unique identification number
      d.name = dataFileNames{i};                % Time series data file name
      d.data = dataIn;                          % Time series data
      d.labels = labelIn;                       % Classification data
      d.sampleSize = size(dataIn,1);            % Time series data sample size
      d.length = size(dataIn,2);                % Time series data length
      d.nanCount = sum(sum(isnan(dataIn),2));   % Number of NaNs within the data set
      
      DATA{i} = d; % Store the structure

      if getpref('TSANALYZER', 'DEBUG')
        msg = sprintf("Creating data structure:\n\tID:          %d\n\tName:        %s \n\tSample Size: %d\n\tLength:      %d\n\tNaN Count:   %d",...
            d.ID, d.name, d.sampleSize, d.length, d.nanCount);
        fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
      end
      
  end

  VALID_DATA = true;
  MESSAGE = "";
  
end

