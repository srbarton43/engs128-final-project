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

----------------------------------------------------------------------------
-- Entity definition
entity axis_fft_bins_interface is
    Generic (
        DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 64);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tuser    : in unsigned(5 downto 0);
		s00_axis_tvalid   : in std_logic;

		vsync_i           : in std_logic;

		ram_read_index_i  : in unsigned(5 downto 0);
		rgb_value_o       : out std_logic_vector(DATA_WIDTH-1 downto 0);

		dbg_magnitude_o   : out unsigned(DATA_WIDTH-1 downto 0)
		);

end axis_fft_bins_interface;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_bins_interface is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------
-- First, declare the type
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

type ram_t is array(0 to FFT_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
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

----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------
write_logic : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        if s00_axis_tvalid = '1' then
            if ram_select = '1' then
                rgb_ram_1(to_integer(s00_axis_tuser)) <= RGB_LUT(to_integer(magnitude_sig(DATA_WIDTH-1 downto DATA_WIDTH-7)));
            else
                rgb_ram_0(to_integer(s00_axis_tuser)) <= RGB_LUT(to_integer(magnitude_sig(DATA_WIDTH-1 downto DATA_WIDTH-7)));
            end if;
        end if;
    end if;
end process write_logic;

ram_select_logic : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        if vsync_i = '1' then
            ram_select <= not ram_select;
        end if;
    end if;
end process ram_select_logic;

get_rgb_value : process(ram_select, ram_read_index_i)
begin
    rgb_value_o <= rgb_ram_0(to_integer(ram_read_index_i));
    if ram_select = '1' then
        rgb_value_o <= rgb_ram_1(to_integer(ram_read_index_i));
    end if;
end process get_rgb_value;

magnitude_calc_proc: process(s00_axis_tdata)
    variable re_signed : signed(23 downto 0);
    variable im_signed : signed(23 downto 0);
    variable re_abs : unsigned(23 downto 0);
    variable im_abs : unsigned(23 downto 0);
    variable magnitude_temp : unsigned(24 downto 0);
begin
            -- Extract real and imaginary parts (signed format)
            re_signed := signed(s00_axis_tdata(23 downto 0));
            im_signed := signed(s00_axis_tdata(47 downto 24));

            -- Get absolute values for magnitude calculation
            if re_signed >= 0 then
                re_abs := unsigned(re_signed);
            else
                re_abs := unsigned(-re_signed);
            end if;

            if im_signed >= 0 then
                im_abs := unsigned(im_signed);
            else
                im_abs := unsigned(-im_signed);
            end if;

            -- approximation for sqrt(re^2 + im^2)
            if re_abs >= im_abs then
                magnitude_temp := ('0' & re_abs) + ('0' & im_abs(23 downto 1)); -- re + im/2
            else
                magnitude_temp := ('0' & im_abs) + ('0' & re_abs(23 downto 1)); -- im + re/2
            end if;

            magnitude_sig <= magnitude_temp(23 downto 0);
end process magnitude_calc_proc;

dbg_magnitude_o <= magnitude_sig;

end Behavioral;
