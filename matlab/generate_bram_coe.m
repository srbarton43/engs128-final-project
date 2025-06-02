%--------------------------------------------------------------------------
% ENGS 128 - 25S
% Author: Kendall Farnham 
%--------------------------------------------------------------------------
% Function to generate a COE file for Vivado from an array of integers
% Specify the radix: 2 (binary, default), 16 (hex), 10 (decimal)
%--------------------------------------------------------------------------
function generate_bram_coe(filename, int_array, nbits, radix)

% Open file for writing
fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file for writing.');
end

% Write COE header
fprintf(fid, 'memory_initialization_radix=%d;\n',radix);
fprintf(fid, 'memory_initialization_vector=\n');

% Write data values
for i = 1:length(int_array)
    if radix == 2
        value = dec2bin(int_array(i),nbits);    % Binary format
        value = value(1:nbits);
    elseif radix == 16
        value = dec2hex(int_array(i),nbits/4);  % Hexadecimal format
        value = value(1:nbits/4);
    elseif radix == 10
        value = num2str(int_array(i));          % Decimal format
    else
        fprintf('Invalid radix specified. Set to 2 (binary), 16 (hex), or 10 (dec).\n');
        return
    end
    
    if i < length(int_array)
        fprintf(fid, '%s,\n', value); % Add a comma except for the last entry
    else
        fprintf(fid, '%s;', value); % End with a semicolon
    end
end

% Close file
fclose(fid);

fprintf('COE file "%s" generated successfully.\n', filename);
end
