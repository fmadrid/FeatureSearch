function [OUTPUT] = MeanHarmonic(data)

data2 = abs(data);
OUTPUT = harmmean(data2, 2);
OUTPUT = transpose(OUTPUT);

end

