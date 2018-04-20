function analyzer(datasets, featureList, defaultFeaturesDirectory, customFeaturesDirectory)
%==================================================================================================
% Function:    analyzer
% Description: This function performs a feature search on time series data and outputs the results
%              to a user-specified text document.
%
% Inputs:      datasets : struct(id, name, data, labels, samplesize, length, NaNCount) cell array
%              A cell array containing the time series data. Each element corresponds to a time
%              series data file in the datasets folder specified by the user during program
%              execution as read and validated in 'validateTimeSeries.m'.
%                - id : integer
%                  A unique identification number (unused)
%
%                - name : string
%                  Time series data name which corresponds to the name of the file the time
%                  series data was found in.
%
%                - data : float[sampleSize][length]
%                  Tabular time series data where each row represents a specific time series
%                  measurement with a corresponding classification in 'labels'.
%
%                - labels : float[sampleSize]
%                  A column vector containing the classification for each time series within
%                  'data'.
%
%                - NaNCount : integer
%                  Number of NaNs within the data.
%
%              featureList: string[]
%              A 1 x n vector containing the name of the features used to perform the feature 
%              search as specified by the user during program execution. Each element should 
%              correspond with a feature found either within the 'defaultFeaturesDirectory' or 
%              'customFeaturesDirectory'.
%
%              defaultFeaturesDirectory : string
%              A system-specified directory containing function definitions for each feature as
%              already specified by the programmer (the authors)
%
%              customFeaturesDirectory : string
%              A system-specified directory containing function definitions for each feature as
%              specified by the user
%==================================================================================================

    % Create a temporary file to store program output and output simple header file information to 
    % this file(user will specify a final file name for this data at the end of the function
    fileID = initializeOutputFile();
    
    % Writes data set and feature list information to the output file
    printSpecifications(fileID, datasets, featureList);
    
    % Makes the *.m source code available for discovery
    addpath(defaultFeaturesDirectory, customFeaturesDirectory);

    % DEBUG: print "Running feature search on n data sets with m features"
    if getpref('TSANALYZER', 'DEBUG')
        DATASET_COUNT = size(datasets,2);
        msg = sprintf("Running feature search on [%d] dataset(s) with [%d] features: ", DATASET_COUNT, size(featureList,1));
        fprintf("================================================================================\n");
        fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
    end
    
    datasetSize = size(datasets, 2);
    featureSize = size(featureList,1);
    
    % Preallocate memory for cell array which will hold the following information:
    %   - (1) name : string
    %   - (2) feature : string
    %   - (3) optimumAccuracy : float
    optimumResults = cell(datasetSize * featureSize, 3);
    
    % For each dataset within the data (i.e. each time series data file)
    for i = 1:datasetSize
        
        dataset = datasets{i};
         
        % Print "Analyzing dataset: [dataset] to console
        if getpref('TSANALYZER', 'DEBUG')
            msg = sprintf("Analyzing dataset: %s", dataset.name);
            fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
        end
        
        % For each feature within the feature list
        for j = 1:featureSize
            
            feature = featureList{j};
            
            % Print "Running feature: [featureName]
            if getpref('TSANALYZER', 'DEBUG')
                msg = sprintf("Running feature: %s", feature);
                fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
            end

            % Run the feature on the dataset's data
            results = runFeature(feature, dataset.data, dataset.labels);
            
            % Run the scoring function on the results of the feature
            optimumScore = calculateScore(dataset.sampleSize, results);
            
            if getpref('TSANALYZER', 'DEBUG')
                msg = sprintf("Storing row: %d", (i-1) * featureSize + j);
                fprintf("[%s] [%s]: %s\n", mfilename, datestr(now, 'HH:MM:SS'), msg);
            end
            % Append results to the optimal results data structure.
            optimumResults((i-1) * featureSize + j, 1) = {dataset.name};
            optimumResults((i-1) * featureSize + j, 2) = {feature};
            optimumResults((i-1) * featureSize + j, 3) = {optimumScore};

        end
    
    
    end
    
    % Calculating and print default accuracy to output file
    defaultAccuracy = calculateDefaultAccuracy(dataset.sampleSize, results(1,:));
    fprintf(fileID, "Default Accuracy: %0.6f\n", defaultAccuracy);
    fprintf(fileID, "----------------------------------------------------------------------\n");
    
    % Filter results to those at least as good as the default accuracy
    [~,I] = find([optimumResults{:,3}] > defaultAccuracy);
    optimumResults= optimumResults(I,:);
    
    % Sort the remaining results in descending order
    [~,I] = sort([optimumResults{:,3}], 'descend');
    optimumResults = optimumResults(I, :);
    
    % Output Results to file
    rowCount = min(size(optimumResults,1), 100);
    
    if(rowCount == 0)
        fprintf("No feature outperformed the default accuracy.");
    else
        for row = 1:rowCount
            fprintf(fileID,"DataSet: %-25s Feature: %-15s Accuracy: %0.6f\n", optimumResults{row,1}, optimumResults{row,2}, optimumResults{row,3});
        end
    end
    
    fclose(fileID);
    
    [file, path] = uiputfile('Results.txt', 'Save file name')
    copyfile('temp.txt', strcat(path, file), 'f');
    delete 'temp.txt';
    
end

function [fileID] = initializeOutputFile()
%==================================================================================================
% Function:    initializeOutputFile
% Description: Helper function to 'analyzer.m'. Creates a temporary writable text document and 
%              writes a simple header which will to store program output which will be renamed by 
%              the user.
%
% Outputs:     fID : integer
%              File id reference used by MATLAB to uniquely identify the output file.
%   
%==================================================================================================

    fileID = fopen('temp.txt', 'w');

    fprintf(fileID, "==================================================\n");
    fprintf(fileID, "         UCR Time Series Analyzer (v 1.0)         \n");
    fprintf(fileID, "==================================================\n");
    
end

function printSpecifications(fileID, dataset, featureList)
%==================================================================================================
% Function:    printDataSpecifications
% Description: Helper function to 'analyzer.m'. Outputs useful data set and feature list information
%              to an output file
%
% Input:       fID : integer
%              File id reference used by MATLAB to uniquely identify the output file. Instantiated
%              in 'initializeOutputFile'
%   
%              dataset: struct(id, name, data, labels, samplesize, length, NaNCount)
%              See 'analyzer.m' for specifications
%
%              featureList: string[]
%              See 'analyzer.m' for specifications
%==================================================================================================

    dataSize = size(dataset,2);
    
    fprintf(fileID, "Datasets: %d\n", dataSize);

    fprintf(fileID, '%-4s%-30s%-9s%-8s%-4s\n', "ID", 'Name', 'Samples', 'Length', 'NaNs');
    fprintf(fileID, "----------------------------------------------------------------------\n");
    for i = 1:dataSize
        msg = sprintf('%-4d%-30s %-9d%-8d%-4d', ...
            dataset{i}.ID, dataset{i}.name, dataset{i}.sampleSize, dataset{i}.length, dataset{i}.nanCount);
        fprintf(fileID, "%s\n", msg);
    end

    fprintf(fileID, "\n");
    
    featureSize = size(featureList,1);
    fprintf(fileID, "Features: %d\n", featureSize);
    
    for i = 1:featureSize
        msg = sprintf("%s ", featureList{i});
        fprintf(fileID, "\t%s\n", msg);
    end

   fprintf(fileID, "==================================================\n");

end
    
function [OUTPUT] = runFeature(feature, dataset, classifications )
%==================================================================================================
% Function:    runFeature
% Description: Helper function to 'analyzer.m'. Runs the specified feature on the dataset and
%              returns vertically concatenated list of the classification labels and dataset sorted
%              by the dataset in ascendening order.
%              
%              Example:
%                   |1 2 2 1 1 2|
%                   |1 2 3 4 5 6|
%
% Input:       fID : integer
%              File id reference used by MATLAB to uniquely identify the output file. Instantiated
%              in 'initializeOutputFile'
%
%              dataset: struct(id, name, data, labels, samplesize, length, NaNCount)
%              (See 'analyzer.m' for specifications)
%
%              feature : string
%              Name of the feature. MUST be defined within the the default features or custom
%              features directory. (See 'analyzer.m' for specifications)
%   
%              dataset: struct(id, name, data, labels, samplesize, length, NaNCount)
%              See 'analyzer.m' for specifications
%
%              classifications: string[]
%              A column vector containing the classifications of the time series data represented by
%              the dataset. (See 'analyzer.m' for specifications)
%==================================================================================================

    if getpref('TSANALYZER', 'DEBUG')
        msg = sprintf("Running feature: %s", feature);
        fprintf("[%s] [%s]: %s\n", "runFeature", datestr(now, 'HH:MM:SS'), msg);
    end
    % Run feature on data set
    output = feval(feature, dataset);

    
    
    % Prepend classification labels
    output = [classifications'; output];

    % Sort by data in ascending order
    [~,I] = sort(output(2,:));

    OUTPUT = output(:,I);

end

function [OPTIMUM_SCORE] = calculateScore(sampleSize, dataset)
%==================================================================================================
% Function:    calculateScore
% Description: This function calculates the maximum accuracy of the dataset by iterating over the
%              elements of the dataset and assuming all elements to the left of the specified
%              element belong to one classification (one) and the remaining elements belonging to
%              the other.
%
% Inputs:      sampleSize : integer
%              The number of classifications for the specified data set. (See 'analyzer.m' for 
%              specification details)
%
%              dataset : float[2][sampleSize]
%              A 2 x sampleSize matrix of numerical classifications (1 or 2) and sorted data set
%              values (See helpfuner function 'runFeature' for specifications)
%
% Outputs:     OPTIMUM_SCORE : float
%              A floating-point number between 0 and 1. Represents the maximum attainable accuracy
%==================================================================================================

    if getpref('TSANALYZER', 'DEBUG')
        msg = sprintf("Cacluating Scores");
        fprintf("[%s] [%s]: %s\n", "calculateScore", datestr(now, 'HH:MM:SS'), msg);
    end
    
    % Preallocate a 1 x samplesize row vector to store the predicted accuracies
    scores = zeros(1, sampleSize);

    for i = 1:sampleSize

        %Create predicted classifications
        predictedClassification = [ones(1,i) ones(1,sampleSize - i) * 2];
        actualClassification = dataset(1,:);
        
        % See Confusion Matrix - https://www.mathworks.com/help/stats/confusionmat.html
        [C,~] = confusionmat(actualClassification, predictedClassification);
        
        % Cell(1,1)                -> True Positivites
        % Cell (2,2)               -> True Negatives
        % sum(sum(C)) = sampleSize -> Sum of all elements within C
        scores(i) = (C(1,1) + C(2,2)) / sampleSize;

    end

    % Return the maximum accuracy
    OPTIMUM_SCORE = max(scores);

end

function [DEFAULT_ACCURACY] = calculateDefaultAccuracy(sampleSize, classifications)
%==================================================================================================
% Function:    calculateDefaultScore
% Description: This function calculates the default accuracy (the attainable accuracy by assuming
%              all experiments are of one classification (or the other) whichever is greater.
% Inputs:      sampleSize : integer
%              The number of classifications for the specified data set. (See 'analyzer.m' for 
%              specification details)
%
%              classifications : float[sampleSize]
%              A [1 x sampleSize] matrix of numerical classifications (1 or 2)
%
% Outputs:     DEFAULT_ACCURACY : float
%              A floating-point number between 0 and 1.
%==================================================================================================
    
    if getpref('TSANALYZER', 'DEBUG')
        msg = sprintf("Cacluating default accuracy");
        fprintf("[%s] [%s]: %s\n", "calculateDefaultAccuracy", datestr(now, 'HH:MM:SS'), msg);
    end
    
    % Count the number of elements which are classified as 1
    aClassCount = sum(classifications(:) == 1);
    
    % Count teh number of elements which are classified as 2
    bClassCount = sampleSize - aClassCount;
    
    % Return the greater of the two ratios
    if(aClassCount > bClassCount)
        DEFAULT_ACCURACY = aClassCount / sampleSize;
    else
        DEFAULT_ACCURACY = bClassCount / sampleSize;
    end
    
end
