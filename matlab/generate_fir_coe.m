%--------------------------------------------------------------------------
% ENGS 128 - 25S
% Author: Kendall Farnham
%--------------------------------------------------------------------------
% Lab 3 - FIR Filters
% Function to generate a COE file for Vivado from an array of integers
%--------------------------------------------------------------------------
function generate_fir_coe(filename, int_array)

% Open file for writing
fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file for writing.');
end

% Write COE header
fprintf(fid, 'radix=10;\n');
fprintf(fid, 'coefdata=\n');

% Write data values
for i = 1:length(int_array)   
    if i < length(int_array)
        fprintf(fid, '%d,\n', int_array(i)); % Add a comma except for the last entry
    else
        fprintf(fid, '%d;', int_array(i)); % End with a semicolon
    end
end

% Close file
fclose(fid);

fprintf('COE file "%s" generated successfully.\n', filename);
end
