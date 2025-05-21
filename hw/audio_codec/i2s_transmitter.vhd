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
----------------------------------------------------------------------------
-- Entity definition
entity i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end i2s_transmitter;
----------------------------------------------------------------------------
architecture Behavioral of i2s_transmitter is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
component counter is
    Generic ( MAX_COUNT : integer := 100);   
    Port (  clk_i       : in STD_LOGIC;			
            reset_i     : in STD_LOGIC;		
            enable_i    : in STD_LOGIC;				
            tc_o        : out STD_LOGIC);
end component counter;

component shift_register is
    Generic ( DATA_WIDTH : integer := 16);
    Port (
        clk_i         : in std_logic;
        data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        load_en_i     : in std_logic;
        shift_en_i    : in std_logic;

        data_o        : out std_logic);
end component shift_register;

type state_t is (IDLE1, LOADL, SHIFTL, IDLE2, LOADR, SHIFTR);
signal curr_state, next_state : state_t := IDLE1;

-- counter signals
signal counter_tc_sig : std_logic;
signal reset_counter_sig : std_logic;

-- shift register signals
signal data_in_sig : std_logic_vector(23 downto 0);
signal shift_en_sig : std_logic;
signal load_en_sig : std_logic;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
counter_entity : counter
    Generic map (MAX_COUNT => 24)
    Port map (
        clk_i => bclk_i,
        reset_i => reset_counter_sig,
        enable_i => '1',
        tc_o => counter_tc_sig
    );
    
shift_reg : shift_register
    Generic map (DATA_WIDTH => 24)
    Port map (
        clk_i => bclk_i, --falling edge shifted
        data_i => data_in_sig,
        load_en_i => load_en_sig,
        shift_en_i => shift_en_sig,
        data_o => dac_serial_data_o
    );
    
state_update: process(bclk_i)
begin
    if rising_edge(bclk_i) then
        curr_state <= next_state;
    end if;
end process;

next_state_logic : process(curr_state, lrclk_i, counter_tc_sig)
begin
    -- default
    next_state <= curr_state;
    case curr_state is
        when IDLE1 => 
            if lrclk_i = '0' then
                next_state <= LOADL;
            end if;
        when LOADL =>
            next_state <= SHIFTL;
        when SHIFTL =>
            if counter_tc_sig = '1' then
                next_state <= IDLE2;
            end if;
        when IDLE2 =>
            if lrclk_i = '1' then
                next_state <= LOADR;
            end if;
        when LOADR =>
            next_state <= SHIFTR;
        when SHIFTR =>
            if counter_tc_sig = '1' then
                next_state <= IDLE1;
            end if;
    end case;
end process;

fsm_signal_logic : process(curr_state)
begin
    load_en_sig <= '0';
    shift_en_sig <= '0';
    reset_counter_sig  <= '0';
    case curr_state is
        when LOADL =>
            load_en_sig <= '1';
            reset_counter_sig <= '1';
        when SHIFTL =>
            shift_en_sig <= '1';
        when LOADR =>
            load_en_sig <= '1';
            reset_counter_sig  <= '1';
        when SHIFTR =>
            shift_en_sig <= '1';
        when others =>
    end case;
end process;

data_in_logic : process(lrclk_i, left_audio_data_i, right_audio_data_i)
begin
    
    if lrclk_i = '1' then
        data_in_sig <= right_audio_data_i;
    else
        data_in_sig <= left_audio_data_i;
    end if;
end process;

---------------------------------------------------------------------------- 
end Behavioral;
