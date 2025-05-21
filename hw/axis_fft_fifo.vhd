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
entity axis_fft_fifo is
    Generic (
        FIFO_DEPTH : integer := 1024;
        DATA_WIDTH : integer := 32;
        FFT_DEPTH : integer := 256);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic
end axis_fft_fifo;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_fifo is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------


signal fifo_reset_sig   : std_logic := '0';
signal fifo_full_sig    : std_logic := '0';
signal fifo_empty_sig   : std_logic := '0';
signal fifo_wr_en_sig   : std_logic := '0';
signal fifo_rd_en_sig   : std_logic := '0';
signal fifo_rd_data_sig : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal counter_reg : integer := '0';

----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------
component fifo is
    Generic (
		FIFO_DEPTH : integer := FIFO_DEPTH;
        DATA_WIDTH : integer := DATA_WIDTH);
    Port (
        clk_i       : in std_logic;
        reset_i     : in std_logic;

        -- Write channel
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Read channel
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Status flags
        empty_o         : out std_logic;
        full_o          : out std_logic);
end component fifo;

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
fifo_buffer : fifo
	port map(
		clk_i       => s00_axis_aclk, -- clocks should be same between s_axis and m_axis so it doesn't matter what you use
		reset_i     => fifo_reset_sig, --active low reset

		-- Write channel
		wr_en_i     => fifo_wr_en_sig,
		wr_data_i   => s00_axis_tdata,

		-- Read channel
		rd_en_i     => fifo_rd_en_sig,
		rd_data_o   => fifo_rd_data_sig,

		-- Status flags
		empty_o     => fifo_empty_sig,
		full_o      => fifo_full_sig

	);

	frame_counter : counter
    generic map (
        MAX_COUNT => 256
    );
    port map(
        clk_i => s00_axis_aclk,
        reset_i => fifo_reset_sig,
        enable_i => fifo_rd_en_sig,
        tc_o => m00_axis_tlast
    );

----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------

-- reset
fifo_reset_sig <= (not s00_axis_aresetn) or (not m00_axis_aresetn);

-- FIFO full and empty signals logic
s00_axis_tready <= not fifo_full_sig; --and s00_axis_aresetn; -- added reset logic
m00_axis_tvalid <= not fifo_empty_sig;

-- write enable
fifo_wr_en_sig <= s00_axis_tvalid;

-- read enable
fifo_rd_en_sig <=  m00_axis_tready;

-- data just passing thourgh
m00_axis_tdata <= fifo_rd_data_sig;

-- set strb signal to 1
m00_axis_tstrb <= (others => '1');


end Behavioral;
