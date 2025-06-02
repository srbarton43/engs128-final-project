%--------------------------------------------------------------------------
% ENGS 128 - 25S
% Author: Kendall Farnham 
%--------------------------------------------------------------------------
%   Create a COE file containing DDS samples
%   Determine the phase codes for specified frequencies
%--------------------------------------------------------------------------
clear all
close all
%--------------------------------------------------------------------------
% Specify parameters
%--------------------------------------------------------------------------
% DDS parameters
dds_data_width = 24;    % audio data width
dds_clk_freq = 48000;   % sampling frequency
dds_phase_width = 12;   % data width of dds phase increment signal
is_unsigned = false;    % signed (false) or unsigned (true) data


% COE file parameters
save_coe = true;        % true/false save the COE file
coe_filename = 'lab3_audio_sine.coe';    % where to save the COE file

% Specify frequencies for phase increment calculation
freqs = [65.4, 131, 262, 523.25, 1046.5, 2093];
%--------------------------------------------------------------------------
% DDS calculations
%--------------------------------------------------------------------------
nsamples = 2^dds_phase_width;          % nsamples to fill memory block
dds_amplitude = 2^(dds_data_width-1);  % amplitude of the sine wave
%--------------------------------------------------------------------------
% Calculate the DDS samples to store in BRAM -- UNSIGNED
%--------------------------------------------------------------------------
if is_unsigned
    half_amplitude = 2^(dds_data_width-1);  % amplitude/2 = midpoint
    max_sine_val = 2^dds_data_width - 1;    % max value for this data width
    for n = 1:nsamples
        sine_wave(n) = round(half_amplitude + dds_amplitude*sin(2*pi*n/nsamples));
        if sine_wave(n) > max_sine_val
            sine_wave(n) = max_sine_val;    % ensure integer is in range
        end
    end
%--------------------------------------------------------------------------
% Calculate the DDS samples to store in BRAM -- SIGNED
%--------------------------------------------------------------------------
else
    max_sine_val = 2^(dds_data_width-1)-1; % max signed value for this data width
    for n = 1:nsamples
        sine_wave(n) = round(dds_amplitude*sin(2*pi*n/nsamples));
        if sine_wave(n) > max_sine_val
            sine_wave(n) = max_sine_val;    % ensure integer is in range
        end
    end
end

%--------------------------------------------------------------------------
% Plot the samples stored in BRAM (fundamental frequency)
t = 0:1/dds_clk_freq:(nsamples-1)/dds_clk_freq; % time vector
figure;
plot(t,sine_wave)
title('Fundamental DDS Frequency')
xlabel('Time (s)'), ylabel('Amplitude')
grid on

%--------------------------------------------------------------------------
% Calculate DDS frequencies generated 
%   First, calculate phase increment from desired freqs -- round to integer
%   Then, calculate generated DDS freqs from the integer phase increment
dds_df = dds_clk_freq/(2^dds_phase_width);  % df (phase resolution)
dds_phase_inc = round(freqs/dds_clk_freq * nsamples);  % calculate phase increment
dds_freqs = dds_phase_inc*dds_df;   % calculate signal freq from phase increment

%--------------------------------------------------------------------------
% Design files/parameters
%--------------------------------------------------------------------------
% Generate COE file for BRAM IP core
if save_coe
    generate_bram_coe(coe_filename,sine_wave,dds_data_width,16);
    disp(['COE file saved to  ' coe_filename])
end

