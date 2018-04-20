function [OUTPUT] = MeanArithmetic(data)

OUTPUT = mean(data, 2, 'omitnan');
OUTPUT = transpose(OUTPUT);

end

