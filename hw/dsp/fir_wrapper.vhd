----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: Wrapper for all four FIR filters with mux'ing logic
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity fir_wrapper is
    Generic (AUDIO_DATA_WIDTH : integer := 24;
            AXIS_DATA_WIDTH : integer := 32;
            LR_SELECT_BIT_IDX : integer := 23
           );
    Port (

        sysclk_i    : in STD_LOGIC;
        lrclk_i     : in STD_LOGIC;

        s_axis_data_i : in STD_LOGIC_VECTOR(AXIS_DATA_WIDTH-1 downto 0);

        enable_sw_i : in STD_LOGIC;
        filter_sel_i : STD_LOGIC_VECTOR(1 downto 0);

        m_axis_data_o : out STD_LOGIC_VECTOR(AXIS_DATA_WIDTH-1 downto 0);

        -- AXI SIGNALS
        s_axis_aclk     : in STD_LOGIC;
        s_axis_tvalid_i : in STD_LOGIC;
        s_axis_tready_o : out STD_LOGIC;
        s_axis_resetn  : in STD_LOGIC;

        m_axis_aclk     : in STD_LOGIC;
        m_axis_tvalid_o : out STD_LOGIC;
        m_axis_tready_i : in STD_LOGIC;
        m_axis_resetn : in STD_LOGIC
    );
end fir_wrapper;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of fir_wrapper is

    ----------------------------------------------------------------------------
    -- Define Constants and Signals
    ----------------------------------------------------------------------------
    signal audio_sig : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

    signal lpf_left_sready, lpf_right_sready : STD_LOGIC := '0';
    signal lpf_left_mvalid, lpf_right_mvalid : STD_LOGIC := '0';
    signal lpf_left_mdata, lpf_right_mdata : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

    signal hpf_left_sready, hpf_right_sready : STD_LOGIC := '0';
    signal hpf_left_mvalid, hpf_right_mvalid : STD_LOGIC := '0';
    signal hpf_left_mdata, hpf_right_mdata : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

    signal bpf_left_sready, bpf_right_sready : STD_LOGIC := '0';
    signal bpf_left_mvalid, bpf_right_mvalid : STD_LOGIC := '0';
    signal bpf_left_mdata, bpf_right_mdata : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

    signal bsf_left_sready, bsf_right_sready : STD_LOGIC := '0';
    signal bsf_left_mvalid, bsf_right_mvalid : STD_LOGIC := '0';
    signal bsf_left_mdata, bsf_right_mdata : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

    -- axis_receiver output signals
    signal left_audio_data_rx, right_audio_data_rx : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');
    signal audio_data_valid_o : STD_LOGIC := '1';

    -- axis_transmitter input signals
    signal left_audio_data_tx, right_audio_data_tx : STD_LOGIC_VECTOR(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');


    ----------------------------------------------------------------------------
    -- Define Subcomponents
    ----------------------------------------------------------------------------
    COMPONENT fir_lpf
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_data_tvalid : IN STD_LOGIC;
            s_axis_data_tready : OUT STD_LOGIC;
            s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC;
            m_axis_data_tready : IN STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT fir_hpf
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_data_tvalid : IN STD_LOGIC;
            s_axis_data_tready : OUT STD_LOGIC;
            s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC;
            m_axis_data_tready : IN STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT fir_bpf
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_data_tvalid : IN STD_LOGIC;
            s_axis_data_tready : OUT STD_LOGIC;
            s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC;
            m_axis_data_tready : IN STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT fir_bsf
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_data_tvalid : IN STD_LOGIC;
            s_axis_data_tready : OUT STD_LOGIC;
            s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC;
            m_axis_data_tready : IN STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    component axis_receiver_interface
        Generic (
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
    end component;

    component axis_transmitter_interface
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
    end component;

begin

    ---------------------------------------------------------------------
    -- port mappings
    ---------------------------------------------------------------------
    axis_receiver: axis_receiver_interface
        port map(
            lrclk_i => lrclk_i,
            s00_axis_aclk_i => s_axis_aclk,
            s00_axis_resetn_i => s_axis_resetn,
            s00_axis_tdata_i => s_axis_data_i,
            s00_axis_tlast_i => '0',
            s00_axis_tstrb_i => "0000",
            s00_axis_tvalid_i => s_axis_tvalid_i,
            left_audio_data_o => left_audio_data_rx,
            right_audio_data_o => right_audio_data_rx,
            audio_valid_o => audio_data_valid_o,
            s00_axis_tready_o => s_axis_tready_o
        );

    axis_transmitter: axis_transmitter_interface
        port map(
            left_audio_data_i => left_audio_data_tx,
            right_audio_data_i => right_audio_data_tx,
            lrclk_i => lrclk_i,
            m00_axis_aclk => m_axis_aclk,
            m00_axis_aresetn => m_axis_resetn,
            m00_axis_tready => m_axis_tready_i,
            m00_axis_tvalid_o => m_axis_tvalid_o,
            m00_axis_tdata_o => m_axis_data_o
        );

    left_lpf : fir_lpf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => lpf_left_sready,
            s_axis_data_tdata => left_audio_data_rx,
            m_axis_data_tvalid => lpf_left_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => lpf_left_mdata
        );

    right_lpf : fir_lpf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => lpf_right_sready,
            s_axis_data_tdata => right_audio_data_rx,
            m_axis_data_tvalid => lpf_right_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => lpf_right_mdata
        );

    left_hpf : fir_hpf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => hpf_left_sready,
            s_axis_data_tdata => left_audio_data_rx,
            m_axis_data_tvalid => hpf_left_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => hpf_left_mdata
        );

    right_hpf : fir_hpf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => hpf_right_sready,
            s_axis_data_tdata => right_audio_data_rx,
            m_axis_data_tvalid => hpf_right_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => hpf_right_mdata
        );

    left_bpf : fir_bpf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => bpf_left_sready,
            s_axis_data_tdata => left_audio_data_rx,
            m_axis_data_tvalid => bpf_left_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => bpf_left_mdata
        );

    right_bpf : fir_bpf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => bpf_right_sready,
            s_axis_data_tdata => right_audio_data_rx,
            m_axis_data_tvalid => bpf_right_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => bpf_right_mdata
        );

    left_bsf : fir_bsf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => bsf_left_sready,
            s_axis_data_tdata => left_audio_data_rx,
            m_axis_data_tvalid => bsf_left_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => bsf_left_mdata
        );

    right_bsf : fir_bsf
        PORT MAP (
            aclk => sysclk_i,
            s_axis_data_tvalid => audio_data_valid_o,
            s_axis_data_tready => bsf_right_sready,
            s_axis_data_tdata => right_audio_data_rx,
            m_axis_data_tvalid => bsf_right_mvalid,
            m_axis_data_tready => m_axis_tready_i,
            m_axis_data_tdata => bsf_right_mdata
        );

    select_filter : process(m_axis_aclk)
        variable lr_select : STD_LOGIC;
    begin
        if rising_edge(m_axis_aclk) then
            if enable_sw_i = '1' then
                case (filter_sel_i) is
                    when "00" => -- lpf
                        if lpf_right_mvalid = '1' then
                            right_audio_data_tx <= lpf_right_mdata;
                        end if;
                        if lpf_left_mvalid = '1' then
                            left_audio_data_tx <= lpf_left_mdata;
                        end if;
                    when "01" => -- hpf
                        if hpf_right_mvalid = '1' then
                            right_audio_data_tx <= hpf_right_mdata;
                        end if;
                        if hpf_left_mvalid = '1' then
                            left_audio_data_tx <= hpf_left_mdata;
                        end if;
                    when "10" => -- bpf
                        if bpf_right_mvalid = '1' then
                            right_audio_data_tx <= bpf_right_mdata;
                        end if;
                        if bpf_left_mvalid = '1' then
                            left_audio_data_tx <= bpf_left_mdata;
                        end if;
                    when "11" => -- bsf
                        if bsf_right_mvalid = '1' then
                            right_audio_data_tx <= bsf_right_mdata;
                        end if;
                        if bsf_left_mvalid = '1' then
                            left_audio_data_tx <= bsf_left_mdata;
                        end if;
                    when others =>
                        if audio_data_valid_o = '1' then
                            left_audio_data_tx <= left_audio_data_rx;
                            right_audio_data_tx <= right_audio_data_rx;
                        end if;
                end case;
            else
                if audio_data_valid_o = '1' then
                    left_audio_data_tx <= left_audio_data_rx;
                    right_audio_data_tx <= right_audio_data_rx;
                end if;
            end if;
        end if;
    end process select_filter;

end Behavioral;
