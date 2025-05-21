----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S receiver for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
        mclk_i    : in std_logic;
        bclk_i    : in std_logic;
        lrclk_i   : in std_logic;

        -- Data
        left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        adc_serial_data_i     : in std_logic);
end i2s_receiver;
----------------------------------------------------------------------------
architecture Behavioral of i2s_receiver is
    ----------------------------------------------------------------------------
    -- Define constants, signals, and declare sub-components
    ----------------------------------------------------------------------------
    -- FSM
    type state_type is (IdleL, IdleR, LoadL, ShiftL, ShiftR, LoadR);
    signal curr_state, next_state: state_type := IdleL;

    -- Controller specific signal
    signal load_Lreg, load_Rreg : std_logic := '0';
    signal counter_tc, counter_reset : std_logic := '0';

    -- Shift regiser signals
    signal shift_en : std_logic := '1';
    signal shift_data_out : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

    -- shift register
    component shift_register_receiver is
        Generic ( DATA_WIDTH : integer := AC_DATA_WIDTH);  -- tie to entity DATA_WIDTH
        Port (
            clk_i         : in std_logic;
            data_i        : in std_logic;
            shift_en_i    : in std_logic;

            data_o        : out std_logic_vector(AC_DATA_WIDTH-1 downto 0));
    end component;

    -- bit Counter
    component counter is
        Generic ( MAX_COUNT : integer := AC_DATA_WIDTH);  -- set max to entity DATA_WIDTH
        Port (  clk_i       : in STD_LOGIC;
             reset_i     : in STD_LOGIC;
             enable_i    : in STD_LOGIC;
             tc_o        : out STD_LOGIC);
    end component;

    ----------------------------------------------------------------------------
begin
    ----------------------------------------------------------------------------
    -- Port-map sub-components, and describe the entity behavior
    ----------------------------------------------------------------------------
    -- ++++ Port map your shift register component ++++
    shift_reg_inst : shift_register_receiver
        port map (
            clk_i => bclk_i,
            data_i => adc_serial_data_i,           -- hook directly up to port
            shift_en_i => shift_en,
            data_o => shift_data_out);

    -- Counter instance
    shift_counter : counter
        generic map (
            MAX_COUNT => AC_DATA_WIDTH+1
        )
        port map (
            clk_i => bclk_i,
            reset_i => counter_reset,
            enable_i => '1',            -- always enabled
            tc_o => counter_tc);

    -- FSM
    next_state_logic : process(curr_state, lrclk_i, counter_tc)
    begin
        next_state <= curr_state; 	-- default is to stay in the same state

        case curr_state is

            when IdleL  =>
                if lrclk_i = '0' then
                    next_state <= ShiftL;
                end if;
            when ShiftL =>
                if counter_tc = '1' then
                    next_state <= LoadL;
                end if;

            when LoadL =>
                next_state <= IdleR;

            when IdleR =>
                if lrclk_i = '1' then
                    next_state <= ShiftR;
                end if;


            when ShiftR =>
                if counter_tc = '1' then
                    next_state <= LoadR;
                end if;

            when LoadR =>
                next_state <= IdleL;
            when others =>

        end case;
    end process next_state_logic;

    fsm_output_logic : process(curr_state)
    begin
        shift_en <= '0';
        load_Rreg <= '0';
        load_Lreg <= '0';
        counter_reset <= '1';

        case curr_state is
            when IdleL  =>

            when ShiftL  =>
                counter_reset <= '0';
                shift_en <= '1';

            when LoadL =>
                load_Lreg <= '1';

            when IdleR  =>

            when ShiftR =>
                counter_reset <= '0';
                shift_en <= '1';
            when LoadR =>
                load_Rreg <= '1';
            when others =>
        end case;

    end process fsm_output_logic;

    state_update : process (bclk_i)
    begin
        if (falling_edge (bclk_i)) then
            curr_state  <= next_state;
        end if;
    end process state_update;

    data_update : process (lrclk_i, bclk_i, load_Lreg, load_Rreg)
    begin
        if(falling_edge (bclk_i)) then
            if load_Lreg = '1' then
                left_audio_data_o <= shift_data_out;
            elsif load_Rreg = '1' then
                right_audio_data_o <= shift_data_out;
            end if;
        end if;
    end process data_update;

    ----------------------------------------------------------------------------
end Behavioral;
