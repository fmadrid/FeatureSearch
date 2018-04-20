function [OUTPUT] = Mode(data)

OUTPUT = mode(data, 2);
OUTPUT = transpose(OUTPUT);

end

