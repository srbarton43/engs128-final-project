----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: AXI stream wrapper for controlling I2S audio data flow
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity axis_i2s_wrapper is
    generic (
        -- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
        C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
        I2S_DATA_WIDTH : integer := 24
    );
    Port (
        ----------------------------------------------------------------------------
        -- Fabric clock from Zynq PS
        mclk_i : in std_logic;

        ----------------------------------------------------------------------------
        -- I2S audio codec ports
        -- User controls
        ac_mute_en_i : in STD_LOGIC;

        -- Audio Codec I2S controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low

        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;


        -- dds or line in??
        dds_enable_i : in std_logic;

        -- DDS audio in
        dds_audio_left_i : in STD_LOGIC_VECTOR(I2S_DATA_WIDTH-1 downto 0);
        dds_audio_right_i : in STD_LOGIC_VECTOR(I2S_DATA_WIDTH-1 downto 0);

        -- dds clock
        dds_clock_o : out STD_LOGIC;

        -- lrclk_o unbuffered
        lrclk_unbuf_o : out STD_LOGIC;

        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC;

        ----------------------------------------------------------------------------
        -- AXI Stream Interface (Receiver/Responder)
        -- Ports of Axi Responder Bus Interface S00_AXIS
        s00_axis_aclk     : in std_logic;
        s00_axis_aresetn  : in std_logic;
        s00_axis_tready   : out std_logic;
        s00_axis_tdata	  : in std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        s00_axis_tstrb    : in std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
        s00_axis_tlast    : in std_logic;
        s00_axis_tvalid   : in std_logic;

        -- AXI Stream Interface (Tranmitter/Controller)
        -- Ports of Axi Controller Bus Interface M00_AXIS
        m00_axis_aclk     : in std_logic;
        m00_axis_aresetn  : in std_logic;
        m00_axis_tvalid   : out std_logic;
        m00_axis_tdata    : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        m00_axis_tstrb    : out std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
        m00_axis_tlast    : out std_logic;
        m00_axis_tready   : in std_logic;

        -- ILA Debug Ports
        dbg_left_audio_rx_o : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        dbg_right_audio_rx_o : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        dbg_left_audio_tx_o : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
        dbg_right_audio_tx_o : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0));
end axis_i2s_wrapper;
----------------------------------------------------------------------------
architecture Behavioral of axis_i2s_wrapper is
    ----------------------------------------------------------------------------
    -- Define Constants and Signals
    ----------------------------------------------------------------------------
    signal bclk_sig, lrclk_sig : std_logic := '0';
    signal left_audio_rx_sig, right_audio_rx_sig : std_logic_vector(I2S_DATA_WIDTH-1 downto 0) := (others => '0');
    signal muxed_left_audio_rx_sig, muxed_right_audio_rx_sig : std_logic_vector(I2S_DATA_WIDTH-1 downto 0) := (others => '0');
    signal left_audio_tx_sig, right_audio_tx_sig : std_logic_vector(I2S_DATA_WIDTH-1 downto 0) := (others => '0');
    signal mute_reg : std_logic := '1';

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
            lrclk_o           : out std_logic;
            lrclk_unbuf_o     : out std_logic);
    end component;

    ----------------------------------------------------------------------------
    -- I2S receiver
    component i2s_receiver is
        Port (

            -- Timing
            mclk_i    : in std_logic;
            bclk_i    : in std_logic;
            lrclk_i   : in std_logic;

            -- Data
            left_audio_data_o     : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
            right_audio_data_o    : out std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
            adc_serial_data_i     : in std_logic);
    end component;

    ----------------------------------------------------------------------------
    -- I2S transmitter
    component i2s_transmitter is
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
    end component;

    ----------------------------------------------------------------------------
    -- AXI stream transmitter
    component axis_transmitter_interface is
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

    ----------------------------------------------------------------------------
    -- AXI stream receiver
    component axis_receiver_interface is
        generic (
            I2S_DATA_WIDTH : integer := 24;
            C_AXI_STREAM_DATA_WIDTH	: integer	:= 32
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
            s00_axis_tready_o : out std_logic
        );
    end component;

    ----------------------------------------------------------------------------
begin
    ----------------------------------------------------------------------------
    -- Component instantiations
    ----------------------------------------------------------------------------
    -- Clock generation
    clock_generation : i2s_clock_gen
        port map(
            mclk_12_288MHz_i => mclk_i,

            mclk_fwd_o => ac_mclk_o,
            bclk_fwd_o => ac_bclk_o,
            adc_lrclk_fwd_o => ac_adc_lrclk_o,
            dac_lrclk_fwd_o => ac_dac_lrclk_o,

            mclk_o => open,
            bclk_o => bclk_sig,
            lrclk_o => dds_clock_o,
            lrclk_unbuf_o => lrclk_sig
        );

    ----------------------------------------------------------------------------
    -- I2S transmitter
    audio_transmitter : i2s_transmitter
        port map(
            mclk_i => mclk_i,
            bclk_i => bclk_sig,
            lrclk_i => lrclk_sig,
            left_audio_data_i => left_audio_tx_sig,
            right_audio_data_i => right_audio_tx_sig,
            dac_serial_data_o => ac_dac_data_o
        );
    ----------------------------------------------------------------------------
    -- i2s receiver
    audio_receiver : i2s_receiver
        port map(
            mclk_i => mclk_i,
            bclk_i => bclk_sig,
            lrclk_i => lrclk_sig,
            adc_serial_data_i => ac_adc_data_i,
            left_audio_data_o => left_audio_rx_sig,
            right_audio_data_o => right_audio_rx_sig
        );

    ----------------------------------------------------------------------------
    -- AXI stream transmitter
    axis_transmitter : axis_transmitter_interface
        port map (
            -- inputs
            left_audio_data_i => muxed_left_audio_rx_sig,
            right_audio_data_i => muxed_right_audio_rx_sig,
            lrclk_i           => lrclk_sig,
            m00_axis_aclk     => m00_axis_aclk,
            m00_axis_aresetn  => m00_axis_aresetn,
            m00_axis_tready   => m00_axis_tready,

            -- outputs
            m00_axis_tvalid_o => m00_axis_tvalid,
            m00_axis_tdata_o    => m00_axis_tdata,
            m00_axis_tstrb_o    => m00_axis_tstrb,
            m00_axis_tlast_o    => m00_axis_tlast
        );

    ----------------------------------------------------------------------------
    -- AXI stream receiver
    axis_receiver : axis_receiver_interface
        Port map (
            -- inputs
            lrclk_i => lrclk_sig,
            s00_axis_aclk_i => s00_axis_aclk,
            s00_axis_resetn_i => s00_axis_aresetn,
            s00_axis_tdata_i => s00_axis_tdata,
            s00_axis_tlast_i => s00_axis_tlast,
            s00_axis_tstrb_i => s00_axis_tstrb,
            s00_axis_tvalid_i => s00_axis_tvalid,

            --outputs
            left_audio_data_o => left_audio_tx_sig,
            right_audio_data_o => right_audio_tx_sig,
            s00_axis_tready_o => s00_axis_tready
        );
    ----------------------------------------------------------------------------
    -- Logic
    ----------------------------------------------------------------------------
    mute_logic : process(mclk_i)
    begin
        if rising_edge(mclk_i) then
            mute_reg <= not ac_mute_en_i;
        end if;
    end process mute_logic;

    ac_mute_n_o <= mute_reg;

    dds_logic : process(dds_enable_i)
    begin
        muxed_left_audio_rx_sig <= left_audio_rx_sig;
        muxed_right_audio_rx_sig <= right_audio_rx_sig;
        if dds_enable_i = '1' then
            muxed_left_audio_rx_sig <= dds_audio_left_i;
            muxed_right_audio_rx_sig <= dds_audio_right_i;
        end if;
    end process dds_logic;

    -- tie lrclk out
    lrclk_unbuf_o <= lrclk_sig;

    ----------------------------------------------------------------------------
    -- Debug signals
    ----------------------------------------------------------------------------
    dbg_left_audio_rx_o <= muxed_left_audio_rx_sig;
    dbg_right_audio_rx_o <= muxed_right_audio_rx_sig;
    dbg_left_audio_tx_o <= left_audio_tx_sig;
    dbg_right_audio_tx_o <= right_audio_tx_sig;
end Behavioral;
