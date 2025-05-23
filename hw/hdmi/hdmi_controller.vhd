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
use work.rgb_package.all;

----------------------------------------------------------------------------
-- Entity definition
entity hdmi_controller is
    Generic (
        NUMBER_BINS : integer := 64;
        BIN_INDEX_WIDTH : integer := 6
    );
    Port (
        pixel_clk_i     : in std_logic;
        hsync_i         : in std_logic;
        video_active_i  : in std_logic;

        bin_index_o     : out unsigned(BIN_INDEX_WIDTH-1 downto 0)
    );
end hdmi_controller;

architecture Behavioral of hdmi_controller is
    constant TOTAL_PIXEL_WIDTH : integer := 1280;
    constant BIN_PIXEL_WIDTH : integer := TOTAL_PIXEL_WIDTH / NUMBER_BINS;

    signal pixel_counter : integer range 0 to BIN_PIXEL_WIDTH := 0;
    signal pixel_counter_tc : std_logic := '0';
    signal bin_counter : integer range 0 to NUMBER_BINS := 0;
begin

    bin_counter_logic : process(pixel_clk_i)
    begin
        if rising_edge(pixel_clk_i) then
            if hsync_i = '1' or bin_counter = NUMBER_BINS-1 then
                bin_counter <= 0;
            elsif pixel_counter_tc = '1' then
                bin_counter <= bin_counter + 1;
            end if;
        end if;
    end process bin_counter_logic;

    pixel_counter_logic : process(pixel_clk_i)
    begin
        if rising_edge(pixel_clk_i) then
            if hsync_i = '1' or pixel_counter = BIN_PIXEL_WIDTH-1 then
                pixel_counter <= 0;
            elsif video_active_i = '1' then
                pixel_counter <= pixel_counter + 1;
            end if;
        end if;
    end process pixel_counter_logic;

    pixel_counter_tc_logic : process(pixel_counter)
    begin
        pixel_counter_tc <= '0';
        if pixel_counter = BIN_PIXEL_WIDTH-1 then
            pixel_counter_tc <= '1';
        end if;
    end process pixel_counter_tc_logic;

    bin_index_o <= to_unsigned(bin_counter, BIN_INDEX_WIDTH);

end Behavioral;
