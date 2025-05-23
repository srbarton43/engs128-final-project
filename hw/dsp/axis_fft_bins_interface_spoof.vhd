----------------------------------------------------------------------------
--  Final Project
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: interface for Bins RAM from FFT
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.rgb_package.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fft_bins_interface_spoof is
    Generic (
        DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 64);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
--		s00_axis_aclk     : in std_logic;
--		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
--		s00_axis_tlast    : in std_logic;
--		s00_axis_tuser    : in unsigned(5 downto 0);
--		s00_axis_tvalid   : in std_logic;

		vsync_i           : in std_logic;

		bin_read_index_i  : in unsigned(5 downto 0);
		rgb_value_o       : out std_logic_vector(RGB_WIDTH-1 downto 0);

		dbg_magnitude_o   : out unsigned(DATA_WIDTH-1 downto 0)
		);

end axis_fft_bins_interface_spoof;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_bins_interface_spoof is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------
type rgb_lut_array is array (0 to 63) of std_logic_vector(23 downto 0);

-- Now declare the constant
constant RGB_LUT: rgb_lut_array := (
    x"00007f",
    x"020381",
    x"040683",
    x"070985",
    x"090c87",
    x"0c1089",
    x"0e138b",
    x"11168d",
    x"13198f",
    x"151d91",
    x"182093",
    x"1a2395",
    x"1d2697",
    x"1f2a99",
    x"222d9b",
    x"24309d",
    x"26339f",
    x"2937a1",
    x"2b3aa3",
    x"2e3da5",
    x"3040a7",
    x"3244aa",
    x"3547ac",
    x"374aae",
    x"3a4db0",
    x"3c50b2",
    x"3f54b4",
    x"4157b6",
    x"445ab8",
    x"465dba",
    x"4861bc",
    x"4b64be",
    x"4d67c0",
    x"506ac2",
    x"526ec4",
    x"5571c6",
    x"5774c8",
    x"5977ca",
    x"5c7bcc",
    x"5e7ece",
    x"6181d0",
    x"6384d2",
    x"6588d4",
    x"688bd6",
    x"6a8ed8",
    x"6d91da",
    x"6f94dc",
    x"7298de",
    x"749be0",
    x"769ee2",
    x"79a1e4",
    x"7ba5e6",
    x"7ea8e8",
    x"80abea",
    x"83aeec",
    x"85b2ee",
    x"88b5f0",
    x"8ab8f2",
    x"8cbbf4",
    x"8fbff6",
    x"91c2f8",
    x"94c5fa",
    x"96c8fc",
    x"99ccff"
);

type index_arr is array(0 to 63) of integer;
constant FFT_COLOR_INDEXES: index_arr := (
    2,  3,  5,  7, 10, 13, 15, 16, -- low freq build-up
   18, 20, 23, 25, 28, 30, 31, 30, -- mid-range peak
   28, 25, 22, 20, 18, 16, 15, 13, -- falling off
   11, 10,  9,  8,  7,  7,  6,  6, -- quiet zone
    5,  5,  6,  7,  9, 12, 15, 18, -- mid-high swell
   22, 25, 28, 31, 35, 38, 42, 45, -- high freq build-up
   48, 50, 53, 56, 58, 60, 62, 63, -- high freq peak
   60, 58, 56, 53, 50, 48, 45, 43  -- fading tail
);

type ram_t is array(0 to FFT_DEPTH-1) of std_logic_vector(RGB_WIDTH-1 downto 0);
signal spoof_bins : ram_t;


signal rgb_ram_0, rgb_ram_1 : ram_t := (others => (others => '0'));
signal write_pointer : integer range 0 to FFT_DEPTH-1 := 0;
signal ram_select : std_logic := '0';

signal magnitude_sig : unsigned(DATA_WIDTH-1 downto 0);


----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------

-- create the spoof fft readout
process
begin
    for i in 0 to 63 loop
        spoof_bins(i) <= RGB_LUT(FFT_COLOR_INDEXES(i));
    end loop;
end process;
----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------
get_rgb_value : process(bin_read_index_i)
begin
    rgb_value_o <= spoof_bins(to_integer(bin_read_index_i));
end process get_rgb_value;

end Behavioral;
