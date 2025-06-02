%--------------------------------------------------------------------------
% ENGS 128 - 25S
% Author: Kendall Farnham 
%--------------------------------------------------------------------------
% Lab 3 - FIR Filters
% Generate FIR filter coefficients and save as COE file for FIR IP core
%--------------------------------------------------------------------------
% First, run 'filterDesigner' from the Command Window
% Enter the FIR filter specifications for the BPF, BSF, LPF, and HPF
% Generate the filter coefficients
% Export the coefficients to the workspace (File > Export > set variable names)
% --> Script assumes variable names are: lpf_coe, hpf_coe, bpf_coe, bsf_coe
%--------------------------------------------------------------------------
% Save variables to workspace
save('lab3_fir_filter_coefficients.mat','lpf_coe','hpf_coe','bpf_coe','bsf_coe')
%--------------------------------------------------------------------------
% Or, load workspace
load('lab3_fir_filter_coefficients.mat','lpf_coe','hpf_coe','bpf_coe','bsf_coe')

%--------------------------------------------------------------------------
% Hardware parameters
nbits = 16;
max_signed = 2^(nbits-1)-1;

%--------------------------------------------------------------------------
% Convert to integers, scale to max signed value
int_coe_lpf = round(lpf_coe*max_signed/max(abs(lpf_coe)))';
int_coe_hpf = round(hpf_coe*max_signed/max(abs(hpf_coe)))';
int_coe_bpf = round(bpf_coe*max_signed/max(abs(bpf_coe)))';
int_coe_bsf = round(bsf_coe*max_signed/max(abs(bsf_coe)))';

%--------------------------------------------------------------------------
% Generate COE files for Vivado
generate_fir_coe('lpf_fir.coe',int_coe_lpf)
generate_fir_coe('hpf_fir.coe',int_coe_hpf)
generate_fir_coe('bpf_fir.coe',int_coe_bpf)
generate_fir_coe('bsf_fir.coe',int_coe_bsf)