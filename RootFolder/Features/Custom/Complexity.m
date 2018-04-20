function [OUTPUT] = Complexity(data)

data = data';
if sum(isnan(data)) / length(data) < 0.1
    data(isnan(data)) = [];
    data = zscore(data);
    resultsMatrix = sqrt(sum(diff(data).^2));
else
    msg = sprintf("Optimum: [0.00000]");
    fprintf("%s\n", msg);
    OUTPUT = zeros(1, size(data,1));
    return;
end

OUTPUT = max(data);

end

