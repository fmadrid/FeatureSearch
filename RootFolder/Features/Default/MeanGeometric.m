function [OUTPUT] = MeanGeometric(data)

data = data + abs(min(min(data)));
OUTPUT = geomean(data, 2);
OUTPUT = transpose(OUTPUT);

end

