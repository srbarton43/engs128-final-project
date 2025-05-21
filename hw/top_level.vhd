----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
--  Week 3 - AXI Lite Demo
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Top-level file for audio codec I2S
--  Target device: Zybo
--
--  SSM2603 audio codec datasheet:
--      https://www.analog.com/media/en/technical-documentation/data-sheets/ssm2603.pdf
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;
----------------------------------------------------------------------------
-- Entity definition
entity top_level is
    Port (
		mclk_i : in  std_logic;
		ac_mute_en_i      : in STD_LOGIC;

		-- AXI DDS
		dds_clk_o         : out std_logic;
		left_dds_data_i   : in std_logic_vector(23 downto 0);
		right_dds_data_i  : in std_logic_vector(23 downto 0);

		-- Debug ports -- hook up to ILA
		dbg_lrclk_o       : out std_logic;
		dbg_bclk_o        : out std_logic;
		dbg_left_audio_o  : out std_logic_vector(23 downto 0);
		dbg_right_audio_o : out std_logic_vector(23 downto 0);

		-- Audio Codec I2S controls
        ac_bclk_o         : out STD_LOGIC;
        ac_mclk_o         : out STD_LOGIC;
        ac_mute_n_o       : out STD_LOGIC;	-- Active Low

        -- Audio Codec DAC (audio out)
        ac_dac_data_o     : out STD_LOGIC;
        dbg_ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o    : out STD_LOGIC;

        -- Audio Codec ADC (audio in)
        ac_adc_data_i     : in STD_LOGIC;
        ac_adc_lrclk_o    : out STD_LOGIC);

end top_level;
----------------------------------------------------------------------------
architecture Behavioral of top_level is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant AC_DATA_WIDTH : integer := 24;

----------------------------------------------------------------------------
-- Audio codec I2S signals
signal mclk 			    : std_logic := '0';
signal bclk 			    : std_logic := '0';
signal lrclk   			    : std_logic := '0';
signal lrclk_bufg		    : std_logic := '0';
signal left_audio_data_rx	: std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_rx 	: std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_audio_data_tx	: std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_tx  : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

signal ac_data_sig          : std_logic := '0';

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Clock generation
component i2s_clock_gen is
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
        lrclk_unbuf_o     : out std_logic;
        lrclk_o           : out std_logic);
end component;

----------------------------------------------------------------------------------
-- I2S receiver
component i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;
		bclk_i    : in std_logic;
		lrclk_i   : in std_logic;

		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		adc_serial_data_i     : in std_logic);
end component;

----------------------------------------------------------------------------------
-- I2S transmitter
component i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;
		bclk_i    : in std_logic;
		lrclk_i   : in std_logic;

		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);
end component;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------
-- Clock generation
clock_generation: i2s_clock_gen
port map(
    mclk_12_288MHz_i => mclk_i,
    mclk_fwd_o      => ac_mclk_o,
    bclk_fwd_o      => ac_bclk_o,
    adc_lrclk_fwd_o => ac_adc_lrclk_o,
    dac_lrclk_fwd_o => ac_dac_lrclk_o,
    mclk_o          => mclk,
    bclk_o			=> bclk,
    lrclk_o   => lrclk_bufg,
	lrclk_unbuf_o   => lrclk);

----------------------------------------------------------------------------
dds_clk_o <= lrclk_bufg;

----------------------------------------------------------------------------
-- I2S receiver
audio_receiver: i2s_receiver
port map(
    mclk_i              => mclk,
    bclk_i              => bclk,
    lrclk_i             => lrclk,
    left_audio_data_o   => left_audio_data_rx,
    right_audio_data_o  => right_audio_data_rx,
    adc_serial_data_i   => ac_adc_data_i);

----------------------------------------------------------------------------
-- I2S transmitter
audio_transmitter: i2s_transmitter
port map(
    mclk_i              => mclk,
    bclk_i              => bclk,
    lrclk_i             => lrclk,
    left_audio_data_i   => left_audio_data_tx,
    right_audio_data_i  => right_audio_data_tx,
    dac_serial_data_o   => ac_data_sig);
    
    ac_dac_data_o <= ac_data_sig;
    dbg_ac_dac_data_o <= ac_data_sig;

----------------------------------------------------------------------------
-- Audio data logic
----------------------------------------------------------------------------
audio_data_switch : process(lrclk_bufg)
begin
if rising_edge(lrclk_bufg) then
    left_audio_data_tx <= left_dds_data_i;
    right_audio_data_tx <= right_dds_data_i;
end if;
end process audio_data_switch;

----------------------------------------------------------------------------
-- Mute enable switch -- MUTE IS ACTIVE LOW
ac_mute_n_o <= not(ac_mute_en_i);

----------------------------------------------------------------------------
-- Wire up Debug ports
dbg_lrclk_o <= lrclk;
dbg_bclk_o <= bclk;
dbg_left_audio_o <= left_audio_data_tx;
dbg_right_audio_o <= right_audio_data_tx;


----------------------------------------------------------------------------
end Behavioral;
