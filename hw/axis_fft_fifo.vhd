----------------------------------------------------------------------------
--  Final Project
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: FIFO buffer for FFT interface
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fft_controller is
    Generic (
        FIFO_DEPTH : integer := 1024;
        AXIS_DATA_WIDTH : integer := 32;
        FFT_DATA_WIDTH : integer := 48;
        I2S_DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 256);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((FFT_DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic);
end axis_fft_controller;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_controller is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------

signal counter_reset_sig : std_logic := '0';
signal count_enable_sig : std_logic := '0';

----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------
component counter is
    Generic ( MAX_COUNT : integer := 256);
    Port (  clk_i       : in STD_LOGIC;
            reset_i     : in STD_LOGIC;
            enable_i    : in STD_LOGIC;
            tc_o        : out STD_LOGIC);
end component;
----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------
	frame_counter : counter
    generic map (
        MAX_COUNT => 256
    )
    port map(
        clk_i => s00_axis_aclk,
        reset_i => counter_reset_sig,
        enable_i => count_enable_sig,
        tc_o => m00_axis_tlast
    );

----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------

-- reset
counter_reset_sig <= (not s00_axis_aresetn) or (not m00_axis_aresetn);

-- write enable
count_enable_sig <= s00_axis_tvalid and m00_axis_tready;

-- pass through ready signals
s00_axis_tready <= m00_axis_tready;

-- pass through valid signals
m00_axis_tvalid <= s00_axis_tvalid;

-- data just passing thourgh
data_padding : process(s00_axis_tdata)
begin
    m00_axis_tdata <= (others => '0');
    m00_axis_tdata <= s00_axis_tdata(I2S_DATA_WIDTH-1 downto 0);
end process data_padding;

-- set strb signal to 1
m00_axis_tstrb <= (others => '1');


end Behavioral;
