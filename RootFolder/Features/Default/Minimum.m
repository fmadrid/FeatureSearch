function [OUTPUT] = Minimum(data)

OUTPUT = min(data,[], 2, 'omitnan');
OUTPUT = transpose(OUTPUT);

end

