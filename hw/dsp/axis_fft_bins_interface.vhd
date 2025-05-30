----------------------------------------------------------------------------
--  Final Project
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: interface for Bins RAM from FFT
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

package rgb_package is
    constant RGB_WIDTH : integer := 24;

    type rgb_lut_array is array (0 to 63) of std_logic_vector(RGB_WIDTH-1 downto 0);

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
end package rgb_package;

-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.rgb_package.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fft_bins_interface is
    Generic (
        DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 64;
        BIN_INDEX_DEPTH : integer := 6);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tuser    : in unsigned(BIN_INDEX_DEPTH-1 downto 0);
		s00_axis_tvalid   : in std_logic;

		vsync_i           : in std_logic;

		bin_read_index_i  : in unsigned(BIN_INDEX_DEPTH-1 downto 0);
		rgb_value_o       : out std_logic_vector(RGB_WIDTH-1 downto 0);

		dbg_tuser_o       : out unsigned(BIN_INDEX_DEPTH-1 downto 0);
		dbg_magnitude_o   : out unsigned(DATA_WIDTH-1 downto 0);
		dbg_rgb_lut_index : out unsigned(BIN_INDEX_DEPTH-1 downto 0);
		dbg_rgb_write_val : out std_logic_vector(RGB_WIDTH-1 downto 0)
		);

end axis_fft_bins_interface;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_bins_interface is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------
constant MAG_MSB_OFFSET : integer := 4; -- could change....was seeing that MAG(18) was the highest bit high

type ram_t is array(0 to FFT_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal rgb_ram_0, rgb_ram_1 : ram_t := (others => (others => '0'));
--signal write_pointer : integer range 0 to FFT_DEPTH-1 := 0;

-- ram_select for RAM to write to
-- read from the other RAM
signal ram_select : std_logic := '0';

-- pipeline the axi signals
signal pipelined_tvalid_0, pipelined_tvalid_1 : std_logic := '0';
signal pipelined_tdata_re, pipelined_tdata_im : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal pipelined_tuser_0, pipelined_tuser_1 : unsigned(BIN_INDEX_DEPTH-1 downto 0) := (others => '0');
signal pipelined_magnitude : unsigned(DATA_WIDTH-1 downto 0);

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

pipeline_logic : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        pipelined_tdata_im <= s00_axis_tdata(2*DATA_WIDTH-1 downto DATA_WIDTH);
        pipelined_tdata_re <= s00_axis_tdata(DATA_WIDTH-1 downto 0);
        pipelined_tuser_0 <= s00_axis_tuser;
        pipelined_tvalid_0 <= s00_axis_tvalid;
        pipelined_tuser_1 <= pipelined_tuser_0;
        pipelined_tvalid_1 <= pipelined_tvalid_0;
    end if;
end process pipeline_logic;

write_logic : process(s00_axis_aclk)
    variable rgb_write_val : std_logic_vector(RGB_WIDTH-1 downto 0);
    variable rgb_lut_index : unsigned(BIN_INDEX_DEPTH-1 downto 0);
begin
    if rising_edge(s00_axis_aclk) then
        rgb_lut_index := pipelined_magnitude(DATA_WIDTH-MAG_MSB_OFFSET downto DATA_WIDTH-MAG_MSB_OFFSET-BIN_INDEX_DEPTH+1);
        rgb_write_val := RGB_LUT(to_integer(rgb_lut_index));
        dbg_rgb_lut_index <= rgb_lut_index;
        dbg_rgb_write_val <= rgb_write_val;
        if pipelined_tvalid_1 = '1' then
            if ram_select = '1' then
                rgb_ram_1(to_integer(pipelined_tuser_1)) <= rgb_write_val;
            else
                rgb_ram_0(to_integer(pipelined_tuser_1)) <= rgb_write_val;
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

get_rgb_value : process(ram_select, bin_read_index_i, rgb_ram_0, rgb_ram_1)
begin
    rgb_value_o <= rgb_ram_1(to_integer(bin_read_index_i(BIN_INDEX_DEPTH-1 downto 0)));
    if ram_select = '1' then
        rgb_value_o <= rgb_ram_0(to_integer(bin_read_index_i(BIN_INDEX_DEPTH-1 downto 0)));
    end if;
end process get_rgb_value;

magnitude_calc_proc: process(s00_axis_aclk)
    variable re_signed : signed(23 downto 0);
    variable im_signed : signed(23 downto 0);
    variable re_abs : unsigned(23 downto 0);
    variable im_abs : unsigned(23 downto 0);
    variable magnitude_temp : unsigned(24 downto 0);
begin
    if rising_edge(s00_axis_aclk) then
        -- Extract real and imaginary parts (signed format)
        re_signed := signed(pipelined_tdata_re);
        im_signed := signed(pipelined_tdata_im);

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

        pipelined_magnitude <= magnitude_temp(23 downto 0);
    end if;
end process magnitude_calc_proc;

-- debug signals
dbg_magnitude_o <= pipelined_magnitude;
dbg_tuser_o <= pipelined_tuser_1;

end Behavioral;
