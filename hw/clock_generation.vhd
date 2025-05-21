----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S transmitter for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_clock_gen is
    Port (
        mclk_12_288MHz_i : in std_logic;

        -- Forwarded clocks
        mclk_fwd_o		  : out std_logic;
        bclk_fwd_o        : out std_logic;
        adc_lrclk_fwd_o   : out std_logic;
        dac_lrclk_fwd_o   : out std_logic;

        -- Clocks for I2S components
        mclk_o		      : out std_logic;
        bclk_o            : out std_logic;
        lrclk_o           : out std_logic;
        lrclk_unbuf_o     : out std_logic);
end entity;
----------------------------------------------------------------------------
architecture Behavioral of i2s_clock_gen is
    ----------------------------------------------------------------------------
    -- Define constants, signals, and declare sub-components
    ----------------------------------------------------------------------------

    component clock_divider is
        Generic (CLK_DIV_RATIO : integer := 25_000_000);
        Port (  fast_clk_i : in STD_LOGIC;
             slow_clk_o : out STD_LOGIC);
    end component;

    component clock_divider_unbuffered is
        Generic (CLK_DIV_RATIO : integer := 25_000_000);
        Port (  fast_clk_i : in STD_LOGIC;
             slow_clk_o: out STD_LOGIC);
    end component;

    signal bclk_sig, lrclk_sig : std_logic;
    ----------------------------------------------------------------------------
begin

    ----------------------------------------------------------------------------
    -- Port Mapping
    ----------------------------------------------------------------------------
    BCLK : clock_divider
        Generic Map (
            CLK_DIV_RATIO => 4
        )
        Port Map (
            fast_clk_i => mclk_12_288MHz_i,
            slow_clk_o => bclk_sig
        );

    LRCLK : clock_divider_unbuffered
        Generic Map (
            CLK_DIV_RATIO => 64
        )
        Port Map (
            fast_clk_i => bclk_sig,
            slow_clk_o => lrclk_sig
        );

    mclk_forward_oddr : ODDR
        generic map(
            DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
            INIT => '0', -- Initial value for Q port ('1' or '0')
            SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
        port map (
            Q => mclk_fwd_o,     -- 1-bit DDR output
            C => mclk_12_288MHz_i,     -- 1-bit clock input
            CE => '1', -- 1-bit clock enable input
            D1 => '1', -- 1-bit data input (positive edge)
            D2 => '0', -- 1-bit data input (negative edge)
            R => '0', -- 1-bit reset input
            S => '0' -- 1-bit set input
        );

    bclk_forward_oddr : ODDR
        generic map(
            DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
            INIT => '0', -- Initial value for Q port ('1' or '0')
            SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
        port map (
            Q => bclk_fwd_o,     -- 1-bit DDR output
            C => bclk_sig,     -- 1-bit clock input
            CE => '1', -- 1-bit clock enable input
            D1 => '1', -- 1-bit data input (positive edge)
            D2 => '0', -- 1-bit data input (negative edge)
            R => '0', -- 1-bit reset input
            S => '0' -- 1-bit set input
        );

    adc_lrclk_forward_oddrlrclk_forward_oddr : ODDR
        generic map(
            DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
            INIT => '0', -- Initial value for Q port ('1' or '0')
            SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
        port map (
            Q => adc_lrclk_fwd_o,     -- 1-bit DDR output
            C => lrclk_sig,     -- 1-bit clock input
            CE => '1', -- 1-bit clock enable input
            D1 => '1', -- 1-bit data input (positive edge)
            D2 => '0', -- 1-bit data input (negative edge)
            R => '0', -- 1-bit reset input
            S => '0' -- 1-bit set input
        );

    dac_lrclk_forward_oddr : ODDR
        generic map(
            DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
            INIT => '0', -- Initial value for Q port ('1' or '0')
            SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
        port map (
            Q => dac_lrclk_fwd_o,     -- 1-bit DDR output
            C => lrclk_sig,     -- 1-bit clock input
            CE => '1', -- 1-bit clock enable input
            D1 => '1', -- 1-bit data input (positive edge)
            D2 => '0', -- 1-bit data input (negative edge)
            R => '0', -- 1-bit reset input
            S => '0' -- 1-bit set input
        );

    buffered_lrclk : BUFG
        port map(
            O => lrclk_o,
            I => lrclk_sig
        );

    mclk_o <= mclk_12_288MHz_i;
    bclk_o <= bclk_sig;
    lrclk_unbuf_o <= lrclk_sig;
    ----------------------------------------------------------------------------
end Behavioral;
