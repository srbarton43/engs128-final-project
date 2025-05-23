----------------------------------------------------------------------------
--  Final Project
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: Simple hdmi test with vertical bands
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity hdmi_test_vertical_bars is
    Port (
        pixel_clk       : in std_logic;
        hsync_i         : in std_logic;
        video_active_i  : in std_logic;

        rgb_o       : out std_logic_vector(23 downto 0)
    );
end hdmi_test_vertical_bars;

architecture Behavioral of hdmi_test_vertical_bars is

type rgb_array_t is array (0 to 31) of std_logic_vector(23 downto 0);

constant GRADIENT : rgb_array_t := (
    X"0000FF", --  1: Blue
    X"1200F4", --  2
    X"2400E9", --  3
    X"3600DE", --  4
    X"4800D3", --  5
    X"5A00C8", --  6
    X"6C00BD", --  7
    X"7E00B2", --  8
    X"9000A7", --  9
    X"A2009C", -- 10
    X"B40091", -- 11
    X"C60086", -- 12
    X"D8007B", -- 13
    X"EA0070", -- 14
    X"FC0065", -- 15
    X"FF005A", -- 16
    X"FF124E", -- 17
    X"FF243E", -- 18
    X"FF3632", -- 19
    X"FF4827", -- 20
    X"FF5A1C", -- 21
    X"FF6C10", -- 22
    X"FF7E05", -- 23
    X"FF9000", -- 24: Orange
    X"FF9E00", -- 25
    X"FFAC00", -- 26
    X"FFBA00", -- 27
    X"FFC800", -- 28
    X"FFD600", -- 29
    X"FFE400", -- 30
    X"FFF200", -- 31
    X"FF0000"  -- 32: Red
);

constant BAND_PIXEL_WIDTH : integer := 40;

signal gradient_index : integer range 0 to 31 := 0;
signal counter : integer range 0 to BAND_PIXEL_WIDTH := 0;
signal tc_sig : std_logic := '0';
signal white : std_logic := '1';

begin

    process (pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if tc_sig = '1' then
                white <= not white;
            end if;

            if hsync_i = '1' then
                white <= '1';
            --elsif tc_sig = '1' then
            --    gradient_index <= gradient_index + 1;
            --    if gradient_index > 31 then
            --    gradient_index <= 0;
            --    end if;
            --end if;
            elsif white = '0' then
                rgb_o <= (others => '0');
            else
                rgb_o <= (others => '1');
            end if;

        end if;
    end process;

    band_counting : process (pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if hsync_i = '1' then
                counter <= 0;
            elsif video_active_i = '1' then
                counter <= counter + 1;
                if counter > BAND_PIXEL_WIDTH-1 then
                    counter <= 0;
                end if;
            end if;
        end if;
    end process band_counting;

    terminal_count : process(counter)
    begin
        tc_sig <= '0';
        if counter = BAND_PIXEL_WIDTH-1 then
            tc_sig <= '1';
        end if;
    end process terminal_count;

    --rgb_o <= GRADIENT(gradient_index);

end Behavioral;
