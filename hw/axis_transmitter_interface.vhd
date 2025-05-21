----------------------------------------------------------------------------
--  Lab 2: AXI Stream Transmitter Interface
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: FSM for the AXI transmitter iface
----------------------------------------------------------------------------
-- Library Declarations
library ieee;
use ieee.std_logic_1164.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_transmitter_interface is
    generic (
        AXIS_DATA_WIDTH	: integer	:= 32;
        I2S_DATA_WIDTH : integer    := 24
    );
    port (
        -- inputs
        left_audio_data_i : in std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        right_audio_data_i : in std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        lrclk_i           : in std_logic;
        m00_axis_aclk     : in std_logic;
        m00_axis_aresetn  : in std_logic;
        m00_axis_tready   : in std_logic;

        -- outputs
        m00_axis_tvalid_o   : out std_logic;
        m00_axis_tdata_o    : out std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
        m00_axis_tstrb_o    : out std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
        m00_axis_tlast_o    : out std_logic
    );
end axis_transmitter_interface;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_transmitter_interface is
    ----------------------------------------------------------------------------
    -- Signals
    ----------------------------------------------------------------------------

    type state_t is (lrclkHIGH, latchInputs, lrclkLOW, loadLEFT, loadRIGHT);
    signal cur_state, next_state : state_t := lrclkHIGH;

    signal left_audio_reg, right_audio_reg : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
    signal data_reg_enable_sig : std_logic := '0';
    signal LR_mux_sel_sig : std_logic := '0';
    ----------------------------------------------------------------------------
begin

    ----------------------------------------------------------------------------
    -- Component Instantiations
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- Logic
    ----------------------------------------------------------------------------
    state_update : process(m00_axis_aclk)
    begin
        if rising_edge(m00_axis_aclk) then
            cur_state <= next_state;
        end if;
    end process state_update;

    next_state_logic : process(cur_state, lrclk_i, m00_axis_tready)
    begin
        next_state <= cur_state;
        case cur_state is
            when lrclkHIGH =>
                if lrclk_i = '0' then
                    next_state <= latchInputs;
                end if;
            when latchInputs =>
                next_state <= lrclkLOW;
            when lrclkLOW =>
                if lrclk_i = '1' then
                    next_state <= loadLEFT;
                end if;
            when loadLEFT =>
                if m00_axis_tready = '1' then
                    next_state <= loadRIGHT;
                end if;
            when loadRIGHT =>
                if m00_axis_tready = '1' then
                    next_state <= lrclkHIGH;
                end if;
        end case;
    end process next_state_logic;

    output_logic : process(cur_state)
    begin
        m00_axis_tvalid_o <= '0';
        data_reg_enable_sig <= '0';
        LR_mux_sel_sig <= '0';
        case cur_state is
            when lrclkHIGH =>
                LR_mux_sel_sig <= '1';
            when latchInputs =>
                data_reg_enable_sig <= '1';
            when loadLEFT =>
                m00_axis_tvalid_o <= '1';
            when loadRIGHT =>
                m00_axis_tvalid_o <= '1';
                LR_mux_sel_sig <= '1';
            when others =>
        end case;
    end process output_logic;

    load_audio_data_reg : process(m00_axis_aclk)
    begin
        if rising_edge(m00_axis_aclk) then
            if data_reg_enable_sig = '1' then
                -- left
                left_audio_reg <= (others => '0');
                left_audio_reg(I2S_DATA_WIDTH - 1 downto 0) <= left_audio_data_i;

                --right
                right_audio_reg <= (others => '0');
                right_audio_reg(AXIS_DATA_WIDTH-1) <= '1';
                right_audio_reg(I2S_DATA_WIDTH - 1 downto 0) <= right_audio_data_i;
            end if;
        end if;
    end process load_audio_data_reg;
    
    lr_mux_logic : process(LR_mux_sel_sig)
    begin
        if LR_mux_sel_sig = '1' then
            m00_axis_tdata_o <= right_audio_reg;
        else
            m00_axis_tdata_o <= left_audio_reg;
        end if;
    end process lr_mux_logic;

    m00_axis_tstrb_o <= "1111";
    m00_axis_tlast_o <= '0';

end Behavioral;