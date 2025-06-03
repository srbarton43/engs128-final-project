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

    type rgb_lut_array is array (0 to 255) of std_logic_vector(RGB_WIDTH-1 downto 0);
    constant RGB_LUT : rgb_lut_array := (
        X"000000", X"010101", X"020202", X"030303", X"040404", X"050505", X"060606", X"070707",
        X"080808", X"090909", X"0A0A0A", X"0B0B0B", X"0C0C0C", X"0D0D0D", X"0E0E0E", X"0F0F0F",
        X"101010", X"111111", X"121212", X"131313", X"141414", X"151515", X"161616", X"171717",
        X"181818", X"191919", X"1A1A1A", X"1B1B1B", X"1C1C1C", X"1D1D1D", X"1E1E1E", X"1F1F1F",
        X"202020", X"202020", X"222222", X"232323", X"242424", X"242424", X"262626", X"272727",
        X"282828", X"282828", X"2A2A2A", X"2B2B2B", X"2C2C2C", X"2C2C2C", X"2E2E2E", X"2F2F2F",
        X"303030", X"303030", X"323232", X"333333", X"343434", X"343434", X"363636", X"373737",
        X"383838", X"383838", X"3A3A3A", X"3B3B3B", X"3C3C3C", X"3C3C3C", X"3E3E3E", X"3F3F3F",
        X"404040", X"414141", X"414141", X"434343", X"444444", X"454545", X"464646", X"474747",
        X"484848", X"494949", X"494949", X"4B4B4B", X"4C4C4C", X"4D4D4D", X"4E4E4E", X"4F4F4F",
        X"505050", X"515151", X"515151", X"535353", X"545454", X"555555", X"565656", X"575757",
        X"585858", X"595959", X"595959", X"5B5B5B", X"5C5C5C", X"5D5D5D", X"5E5E5E", X"5F5F5F",
        X"606060", X"616161", X"616161", X"636363", X"646464", X"656565", X"666666", X"676767",
        X"686868", X"696969", X"696969", X"6B6B6B", X"6C6C6C", X"6D6D6D", X"6E6E6E", X"6F6F6F",
        X"707070", X"717171", X"717171", X"737373", X"747474", X"757575", X"767676", X"777777",
        X"787878", X"797979", X"797979", X"7B7B7B", X"7C7C7C", X"7D7D7D", X"7E7E7E", X"7F7F7F",
        X"808080", X"818181", X"828282", X"838383", X"838383", X"858585", X"868686", X"878787",
        X"888888", X"898989", X"8A8A8A", X"8B8B8B", X"8C8C8C", X"8D8D8D", X"8E8E8E", X"8F8F8F",
        X"909090", X"919191", X"929292", X"939393", X"939393", X"959595", X"969696", X"979797",
        X"989898", X"999999", X"9A9A9A", X"9B9B9B", X"9C9C9C", X"9D9D9D", X"9E9E9E", X"9F9F9F",
        X"A0A0A0", X"A1A1A1", X"A2A2A2", X"A3A3A3", X"A3A3A3", X"A5A5A5", X"A6A6A6", X"A7A7A7",
        X"A8A8A8", X"A9A9A9", X"AAAAAA", X"ABABAB", X"ACACAC", X"ADADAD", X"AEAEAE", X"AFAFAF",
        X"B0B0B0", X"B1B1B1", X"B2B2B2", X"B3B3B3", X"B3B3B3", X"B5B5B5", X"B6B6B6", X"B7B7B7",
        X"B8B8B8", X"B9B9B9", X"BABABA", X"BBBBBB", X"BCBCBC", X"BDBDBD", X"BEBEBE", X"BFBFBF",
        X"C0C0C0", X"C1C1C1", X"C2C2C2", X"C3C3C3", X"C3C3C3", X"C5C5C5", X"C6C6C6", X"C7C7C7",
        X"C8C8C8", X"C9C9C9", X"CACACA", X"CBCBCB", X"CCCCCC", X"CDCDCD", X"CECECE", X"CFCFCF",
        X"D0D0D0", X"D1D1D1", X"D2D2D2", X"D3D3D3", X"D3D3D3", X"D5D5D5", X"D6D6D6", X"D7D7D7",
        X"D8D8D8", X"D9D9D9", X"DADADA", X"DBDBDB", X"DCDCDC", X"DDDDDD", X"DEDEDE", X"DFDFDF",
        X"E0E0E0", X"E1E1E1", X"E2E2E2", X"E3E3E3", X"E3E3E3", X"E5E5E5", X"E6E6E6", X"E7E7E7",
        X"E8E8E8", X"E9E9E9", X"EAEAEA", X"EBEBEB", X"ECECEC", X"EDEDED", X"EEEEEE", X"EFEFEF",
        X"F0F0F0", X"F1F1F1", X"F2F2F2", X"F3F3F3", X"F3F3F3", X"F5F5F5", X"F6F6F6", X"F7F7F7",
        X"F8F8F8", X"F9F9F9", X"FAFAFA", X"FBFBFB", X"FCFCFC", X"FDFDFD", X"FEFEFE", X"FFFFFF"
    );
    
    constant COLORFUL_RGB_LUT : rgb_lut_array := (
    -- Red to Orange (0-42)
    X"FF0000", X"FF0600", X"FF0C00", X"FF1200", X"FF1800", X"FF1E00", X"FF2400", X"FF2A00",
    X"FF3000", X"FF3600", X"FF3C00", X"FF4200", X"FF4800", X"FF4E00", X"FF5400", X"FF5A00",
    X"FF6000", X"FF6600", X"FF6C00", X"FF7200", X"FF7800", X"FF7E00", X"FF8400", X"FF8A00",
    X"FF9000", X"FF9600", X"FF9C00", X"FFA200", X"FFA800", X"FFAE00", X"FFB400", X"FFBA00",
    X"FFC000", X"FFC600", X"FFCC00", X"FFD200", X"FFD800", X"FFDE00", X"FFE400", X"FFEA00",
    X"FFF000", X"FFF600", X"FFFC00",
    
    -- Orange to Yellow (43-85)
    X"FFFF00", X"FCFF00", X"F9FF00", X"F6FF00", X"F3FF00", X"F0FF00", X"EDFF00", X"EAFF00",
    X"E7FF00", X"E4FF00", X"E1FF00", X"DEFF00", X"DBFF00", X"D8FF00", X"D5FF00", X"D2FF00",
    X"CFFF00", X"CCFF00", X"C9FF00", X"C6FF00", X"C3FF00", X"C0FF00", X"BDFF00", X"BAFF00",
    X"B7FF00", X"B4FF00", X"B1FF00", X"AEFF00", X"ABFF00", X"A8FF00", X"A5FF00", X"A2FF00",
    X"9FFF00", X"9CFF00", X"99FF00", X"96FF00", X"93FF00", X"90FF00", X"8DFF00", X"8AFF00",
    X"87FF00", X"84FF00", X"81FF00",
    
    -- Yellow to Green (86-128)
    X"7EFF00", X"7BFF00", X"78FF00", X"75FF00", X"72FF00", X"6FFF00", X"6CFF00", X"69FF00",
    X"66FF00", X"63FF00", X"60FF00", X"5DFF00", X"5AFF00", X"57FF00", X"54FF00", X"51FF00",
    X"4EFF00", X"4BFF00", X"48FF00", X"45FF00", X"42FF00", X"3FFF00", X"3CFF00", X"39FF00",
    X"36FF00", X"33FF00", X"30FF00", X"2DFF00", X"2AFF00", X"27FF00", X"24FF00", X"21FF00",
    X"1EFF00", X"1BFF00", X"18FF00", X"15FF00", X"12FF00", X"0FFF00", X"0CFF00", X"09FF00",
    X"06FF00", X"03FF00", X"00FF00",
    
    -- Green to Cyan (129-171)
    X"00FF03", X"00FF06", X"00FF09", X"00FF0C", X"00FF0F", X"00FF12", X"00FF15", X"00FF18",
    X"00FF1B", X"00FF1E", X"00FF21", X"00FF24", X"00FF27", X"00FF2A", X"00FF2D", X"00FF30",
    X"00FF33", X"00FF36", X"00FF39", X"00FF3C", X"00FF3F", X"00FF42", X"00FF45", X"00FF48",
    X"00FF4B", X"00FF4E", X"00FF51", X"00FF54", X"00FF57", X"00FF5A", X"00FF5D", X"00FF60",
    X"00FF63", X"00FF66", X"00FF69", X"00FF6C", X"00FF6F", X"00FF72", X"00FF75", X"00FF78",
    X"00FF7B", X"00FF7E", X"00FF81",
    
    -- Cyan to Blue (172-214)
    X"00FF84", X"00FF87", X"00FF8A", X"00FF8D", X"00FF90", X"00FF93", X"00FF96", X"00FF99",
    X"00FF9C", X"00FF9F", X"00FFA2", X"00FFA5", X"00FFA8", X"00FFAB", X"00FFAE", X"00FFB1",
    X"00FFB4", X"00FFB7", X"00FFBA", X"00FFBD", X"00FFC0", X"00FFC3", X"00FFC6", X"00FFC9",
    X"00FFCC", X"00FFCF", X"00FFD2", X"00FFD5", X"00FFD8", X"00FFDB", X"00FFDE", X"00FFE1",
    X"00FFE4", X"00FFE7", X"00FFEA", X"00FFED", X"00FFF0", X"00FFF3", X"00FFF6", X"00FFF9",
    X"00FFFC", X"00FFFF", X"00FCFF",
    
    -- Blue to Magenta (215-255)
    X"00F9FF", X"00F6FF", X"00F3FF", X"00F0FF", X"00EDFF", X"00EAFF", X"00E7FF", X"00E4FF",
    X"00E1FF", X"00DEFF", X"00DBFF", X"00D8FF", X"00D5FF", X"00D2FF", X"00CFFF", X"00CCFF",
    X"00C9FF", X"00C6FF", X"00C3FF", X"00C0FF", X"00BDFF", X"00BAFF", X"00B7FF", X"00B4FF",
    X"00B1FF", X"00AEFF", X"00ABFF", X"00A8FF", X"00A5FF", X"00A2FF", X"009FFF", X"009CFF",
    X"0099FF", X"0096FF", X"0093FF", X"0090FF", X"008DFF", X"008AFF", X"0087FF", X"0084FF",
    X"0081FF"
);
    -- Now declare the constant
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
        RGB_LUT_INDEX_WIDTH : integer := 8;
        BIN_INDEX_DEPTH : integer := 6);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tuser    : in unsigned(BIN_INDEX_DEPTH-1 downto 0);
		s00_axis_tvalid   : in std_logic;
		
		color_select_i    : in std_logic;

		vsync_i           : in std_logic;

		bin_read_index_i  : in unsigned(BIN_INDEX_DEPTH-1 downto 0);
		rgb_value_o       : out std_logic_vector(RGB_WIDTH-1 downto 0);

		dbg_tuser_o       : out unsigned(BIN_INDEX_DEPTH-1 downto 0);
		dbg_magnitude_o   : out unsigned(DATA_WIDTH-1 downto 0);
		dbg_rgb_lut_index : out unsigned(RGB_LUT_INDEX_WIDTH-1 downto 0);
		dbg_rgb_write_val : out std_logic_vector(RGB_WIDTH-1 downto 0)
		);

end axis_fft_bins_interface;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_bins_interface is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------
constant MAG_MSB_OFFSET : integer := 5; -- could change....was seeing that MAG(22) was the highest bit high

type ram_t is array(0 to FFT_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal rgb_ram_0 : ram_t := (others => (others => '0'));

type state_t is (WAIT_VSYNC_LOW, WAIT_VSYNC_HIGH, WAIT_VALID, WAIT_INVALID);
signal next_state, cur_state : state_t := WAIT_VSYNC_HIGH;

signal loading_signal : std_logic := '0';

-- ram_select for RAM to write to
-- read from the other RAM

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

next_state_logic : process(cur_state, vsync_i, s00_axis_tvalid, pipelined_tvalid_1)
begin
    next_state <= cur_state;
    case cur_state is
        when WAIT_VSYNC_HIGH =>
            if vsync_i = '0' then
                next_state <= WAIT_VSYNC_LOW;
            end if;
        when WAIT_VSYNC_LOW =>
            if vsync_i = '1' then
                next_state <= WAIT_VALID;
            end if;
        when WAIT_VALID =>
            if s00_axis_tvalid = '1' then
                next_state <= WAIT_INVALID;
            end if;
        when WAIT_INVALID =>
            if pipelined_tvalid_1 = '0' and s00_axis_tvalid = '0' then
                next_state <= WAIT_VSYNC_HIGH;
            end if;
    end case;
end process next_state_logic;

update_state : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        cur_state <= next_state;
    end if;
end process update_state;

state_signal_logic : process(cur_state)
begin
    loading_signal <= '0';
    if cur_state = WAIT_INVALID then
        loading_signal <= '1';
    end if;
end process state_signal_logic;

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
    variable rgb_lut_index : unsigned(RGB_LUT_INDEX_WIDTH-1 downto 0);
begin
    if rising_edge(s00_axis_aclk) then
        rgb_lut_index := pipelined_magnitude(DATA_WIDTH-MAG_MSB_OFFSET-1 downto DATA_WIDTH-MAG_MSB_OFFSET-RGB_LUT_INDEX_WIDTH);
        if color_select_i = '0' then
            rgb_write_val := RGB_LUT(to_integer(rgb_lut_index));
        else
            rgb_write_val := COLORFUL_RGB_LUT(to_integer(rgb_lut_index));
        end if;
        dbg_rgb_lut_index <= rgb_lut_index;
        dbg_rgb_write_val <= rgb_write_val;
        if pipelined_tvalid_1 = '1' and loading_signal = '1' then
            rgb_ram_0(to_integer(pipelined_tuser_1)) <= rgb_write_val;
        end if;
    end if;
end process write_logic;


get_rgb_value : process(bin_read_index_i, rgb_ram_0)
begin
    rgb_value_o <= rgb_ram_0(to_integer(bin_read_index_i));
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
