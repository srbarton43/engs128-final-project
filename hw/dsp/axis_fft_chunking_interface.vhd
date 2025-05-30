----------------------------------------------------------------------------
--  Final Project
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: chunking controller for FFT interface input
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fft_chunking_interface is
    Generic (
        AXIS_DATA_WIDTH : integer := 32;
        FFT_DATA_WIDTH : integer := 48;
        I2S_DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 64);
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
end axis_fft_chunking_interface;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_chunking_interface is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------
type state_t is (LOADING, FLUSHING);
signal cur_state, next_state : state_t := LOADING;

signal loading_sig : std_logic := '1';
signal flushing_sig : std_logic := '0';

signal fifo_reset_sig, fifo_write_en_sig, fifo_rd_en_sig, fifo_empty_sig, fifo_full_sig : STD_LOGIC := '0';
signal fifo_data_i : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);

signal tlast_counter : integer range 0 to FFT_DATA_WIDTH-1 := 0;
signal tlast_tc : std_logic := '0';

----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------
component fifo is
    Generic (
        FIFO_DEPTH : integer := 1024;
        DATA_WIDTH : integer := 32);
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
end component;
----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------
chunk_fifo: fifo
generic map(
    FIFO_DEPTH => FFT_DEPTH,
    DATA_WIDTH => FFT_DATA_WIDTH
)
port map(
    clk_i => s00_axis_aclk,
    reset_i => fifo_reset_sig,
    wr_en_i => fifo_write_en_sig,
    wr_data_i => fifo_data_i,
    rd_en_i => fifo_rd_en_sig,
    rd_data_o => m00_axis_tdata,
    empty_o => fifo_empty_sig,
    full_o => fifo_full_sig
);

----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------

next_state_logic : process(cur_state, fifo_reset_sig, fifo_empty_sig, fifo_full_sig)
begin
    next_state <= cur_state;
    if fifo_reset_sig = '1' then
        next_state <= LOADING;
    else
        case cur_state is
            when LOADING =>
                if fifo_full_sig = '1' then
                    next_state <= FLUSHING;
                end if;
            when FLUSHING =>
                if fifo_empty_sig = '1' then
                    next_state <= LOADING;
                end if;
        end case;
    end if;
end process next_state_logic;

process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        cur_state <= next_state;
    end if;
end process;

state_output_logic : process(cur_state)
begin
    loading_sig <= '0';
    flushing_sig <= '0';
    case cur_state is
        when LOADING =>
            loading_sig <= '1';
        when FLUSHING =>
            flushing_sig <= '1';
    end case;
end process state_output_logic;

tlast_counter_logic : process(s00_axis_aclk) 
begin
    if rising_edge(s00_axis_aclk) then
        if loading_sig = '1' or tlast_tc = '1' then
            tlast_counter <= 0;
        else
            tlast_counter <= tlast_counter + 1;
        end if;
    end if;
end process;

tlast_tc_logic : process(tlast_counter)
begin
    tlast_tc <= '0';
    if tlast_counter = FFT_DEPTH - 1 then
        tlast_tc <= '1';
    end if;
end process;

m00_axis_tlast <= tlast_tc;

-- reset
fifo_reset_sig <= (not s00_axis_aresetn) or (not m00_axis_aresetn);

-- m_valid
m00_axis_tvalid <= flushing_sig and not fifo_empty_sig;

-- s_ready
s00_axis_tready <= loading_sig and not fifo_full_sig;

-- writing
fifo_write_en_sig <= loading_sig and s00_axis_tvalid;

-- reading
fifo_rd_en_sig <= flushing_sig and m00_axis_tready;

-- data in
process(s00_axis_tdata)
begin
    fifo_data_i <= (others => '0');
    fifo_data_i(I2S_DATA_WIDTH-1 downto 0) <= s00_axis_tdata(I2S_DATA_WIDTH-1 downto 0);
end process;

-- set strb signal to 1
m00_axis_tstrb <= (others => '1');


end Behavioral;
