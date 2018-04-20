function [OUTPUT] = Maximum(data)

OUTPUT = max(data,[], 2, 'omitnan');
OUTPUT = transpose(OUTPUT);

end

