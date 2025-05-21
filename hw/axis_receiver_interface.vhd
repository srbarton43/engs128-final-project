----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: AXI stream wrapper for the receiver i2s data
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity axis_receiver_interface is
    generic (
        I2S_DATA_WIDTH : integer := 24;
        C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
        LR_BIT_INDEX : integer := 31
    );
    Port (
        -- inputs
        lrclk_i : in std_logic;
        s00_axis_aclk_i : in std_logic;
        s00_axis_resetn_i : in std_logic;
        s00_axis_tdata_i : in std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        s00_axis_tlast_i : in std_logic;
        s00_axis_tstrb_i : in std_logic_vector(3 downto 0);
        s00_axis_tvalid_i : in std_logic;

        --outputs
        left_audio_data_o : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        right_audio_data_o : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        audio_valid_o : out std_logic;
        s00_axis_tready_o : out std_logic
    );
end axis_receiver_interface;

architecture Behavioral of axis_receiver_interface is

    ----------------------------------------------------------------------------
    -- Define Constants and Signals
    ----------------------------------------------------------------------------
    type state_t is (lrclkHIGH, latchOutputs, lrclkLOW, load1, load2);
    signal cur_state, next_state : state_t := lrclkHIGH;

    signal axis_data_0, axis_data_1 : std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0) := (others => '0');

    signal data_reg_en_sig, axis_tready_sig : std_logic := '0';

    signal left_audio_reg, right_audio_reg : std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
    ----------------------------------------------------------------------------
    -- Component declarations
    ----------------------------------------------------------------------------

begin
    ----------------------------------------------------------------------------
    -- Component instantiations
    ----------------------------------------------------------------------------
    next_state_logic : process(cur_state, lrclk_i, s00_axis_tvalid_i)
    begin
        next_state <= cur_state;
        case cur_state is
            when lrclkHIGH =>
                if lrclk_i = '0' then
                    next_state <= latchOutputs;
                end if;
            when latchOutputs =>
                next_state <= lrclkLOW;
            when lrclkLOW =>
                if lrclk_i = '1' then
                    next_state <= load1;
                end if;
            when load1 =>
                if s00_axis_tvalid_i = '1'  then
                    next_state <= load2;
                end if;
            when load2 =>
                if s00_axis_tvalid_i = '1' then
                    next_state <= lrclkHIGH;
                end if;
        end case;
    end process next_state_logic;

    fsm_control_logic : process(cur_state)
    begin
        axis_tready_sig <= '0';
        data_reg_en_sig <= '0';
        audio_valid_o <= '0';
        case cur_state is 
            when latchOutputs =>
                data_reg_en_sig <= '1';
                audio_valid_o <= '1';
            when load1 =>
                axis_tready_sig <= '1';
            when load2 =>
                axis_tready_sig <= '1';
            when others =>
        end case;
    end process fsm_control_logic;
    
    latch_audio_data : process(s00_axis_aclk_i)
    begin
        if rising_edge(s00_axis_aclk_i) then
            if s00_axis_tvalid_i = '1' and axis_tready_sig = '1' then
                axis_data_0 <= s00_axis_tdata_i;
                axis_data_1 <= axis_data_0;
            end if;
        end if;
    end process latch_audio_data;

    data_out_logic : process(s00_axis_aclk_i)
        variable lr_data_bit : std_logic;
    begin
        if rising_edge(s00_axis_aclk_i) then
            if data_reg_en_sig = '1' then
            lr_data_bit := axis_data_1(LR_BIT_INDEX);
            if lr_data_bit = '1' then
                    right_audio_reg <= axis_data_1(I2S_DATA_WIDTH-1 downto 0);
                    left_audio_reg <= axis_data_0(I2S_DATA_WIDTH-1 downto 0);
                else
                    right_audio_reg <= axis_data_0(I2S_DATA_WIDTH-1 downto 0);
                    left_audio_reg <= axis_data_1(I2S_DATA_WIDTH-1 downto 0);
                end if;
            end if;
        end if;
    end process data_out_logic;

    state_update : process(s00_axis_aclk_i)
    begin
        if rising_edge(s00_axis_aclk_i) then
            cur_state <= next_state;
        end if;
    end process state_update;

    left_audio_data_o <= left_audio_reg;
    right_audio_data_o <= right_audio_reg;
    s00_axis_tready_o <= axis_tready_sig;

end Behavioral;