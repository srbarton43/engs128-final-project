library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_fft_wrapper is
end entity;

architecture behavioral of tb_fft_wrapper is

constant CLOCK_PERIOD : time := 10 ns;
constant LRCLK_PERIOD : time := 20.83 us;
constant FFT_DEPTH : integer := 64;
constant FFT_INDEX_WIDTH : integer := 6;
constant AXIS_WIDTH : integer := 32;
constant RGB_WIDTH : integer := 24;

-- Constants for 720p timing (1280x720 @ 60Hz)
constant H_ACTIVE      : integer := 1280;
constant H_FRONT_PORCH : integer := 110;
constant H_SYNC_PULSE  : integer := 40;
constant H_BACK_PORCH  : integer := 220;
constant H_TOTAL       : integer := 1650;

constant V_ACTIVE      : integer := 720;
constant V_FRONT_PORCH : integer := 5;
constant V_SYNC_PULSE  : integer := 5;
constant V_BACK_PORCH  : integer := 20;
constant V_TOTAL       : integer := 750;

-- Pixel clock period for 74.5 MHz
constant PIXEL_CLK_PERIOD : time := 13.423 ns;  -- 1/(74.5 MHz)

COMPONENT xfft_0
    PORT (
        aclk : IN STD_LOGIC;
        s_axis_config_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axis_config_tvalid : IN STD_LOGIC;
        s_axis_config_tready : OUT STD_LOGIC;
        s_axis_data_tdata : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
        s_axis_data_tvalid : IN STD_LOGIC;
        s_axis_data_tready : OUT STD_LOGIC;
        s_axis_data_tlast : IN STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
        m_axis_data_tuser : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tready : IN STD_LOGIC;
        m_axis_data_tlast : OUT STD_LOGIC;
        event_frame_started : OUT STD_LOGIC;
        event_tlast_unexpected : OUT STD_LOGIC;
        event_tlast_missing : OUT STD_LOGIC;
        event_status_channel_halt : OUT STD_LOGIC;
        event_data_in_channel_halt : OUT STD_LOGIC;
        event_data_out_channel_halt : OUT STD_LOGIC
    );
END COMPONENT;

component axis_fft_chunking_interface is
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
end component;

component axis_fft_bins_interface is
    Generic (
        DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 64;
        BIN_INDEX_DEPTH : integer := 6);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tuser    : in unsigned(BIN_INDEX_DEPTH-1 downto 0);
		s00_axis_tvalid   : in std_logic;

		vsync_i           : in std_logic;

		bin_read_index_i  : in unsigned(BIN_INDEX_DEPTH-1 downto 0);
		rgb_value_o       : out std_logic_vector(RGB_WIDTH-1 downto 0);

		dbg_tuser_o       : out unsigned(BIN_INDEX_DEPTH-1 downto 0);
		dbg_magnitude_o   : out unsigned(DATA_WIDTH-1 downto 0)
		);

end component;

-- Clock and reset signals
signal aclk           : std_logic := '0';
signal lrclk          : std_logic := '0';
signal pixel_clk      : std_logic := '0';
signal aresetn        : std_logic := '1';

-- chunking iface input signals
signal chunking_s_tdata : STD_LOGIC_VECTOR(AXIS_WIDTH-1 downto 0) := (others => '0');
signal chunking_s_tready, chunking_s_tvalid : STD_LOGIC := '0';

-- Signals connecting chunking_interface to FFT
signal s_axis_data_tdata   : std_logic_vector(47 downto 0) := (others => '0');
signal s_axis_data_tvalid  : std_logic := '0';
signal s_axis_data_tready  : std_logic := '0';
signal s_axis_data_tlast   : std_logic := '0';

-- FFT configuration signals
signal s_axis_config_tdata  : std_logic_vector(7 downto 0) := (others => '0');
signal s_axis_config_tvalid : std_logic := '0';
signal s_axis_config_tready : std_logic := '0';

-- Signals connecting FFT to bins_interface
signal m_axis_data_tdata   : std_logic_vector(47 downto 0) := (others => '0');
signal m_axis_data_tuser   : std_logic_vector(8-1 downto 0) := (others => '0');
signal m_axis_data_tvalid  : std_logic := '0';
signal m_axis_data_tready  : std_logic := '0';
signal m_axis_data_tlast   : std_logic := '0';

-- FFT event signals
signal event_frame_started       : std_logic := '0';
signal event_tlast_unexpected    : std_logic := '0';
signal event_tlast_missing       : std_logic := '0';
signal event_status_channel_halt : std_logic := '0';
signal event_data_in_channel_halt : std_logic := '0';
signal event_data_out_channel_halt : std_logic := '0';

-- bins iface signals
signal vsync_i : std_logic := '0';
signal bin_read_index_i : unsigned(FFT_INDEX_WIDTH-1 downto 0) := (others => '0');
signal rgb_value_o : STD_LOGIC_VECTOR(RGB_WIDTH-1 downto 0);

begin

FFT : xfft_0
port map(
    aclk => aclk,
    s_axis_config_tdata => s_axis_config_tdata,
    s_axis_config_tvalid => s_axis_config_tvalid,
    s_axis_config_tready => s_axis_config_tready,
    s_axis_data_tdata => s_axis_data_tdata,
    s_axis_data_tvalid => s_axis_data_tvalid,
    s_axis_data_tready => s_axis_data_tready,
    s_axis_data_tlast => s_axis_data_tlast,
    m_axis_data_tdata => m_axis_data_tdata,
    m_axis_data_tuser => m_axis_data_tuser,
    m_axis_data_tvalid => m_axis_data_tvalid,
    m_axis_data_tready => m_axis_data_tready,
    m_axis_data_tlast => m_axis_data_tlast,
    event_frame_started => event_frame_started,
    event_tlast_unexpected => event_tlast_unexpected,
    event_tlast_missing => event_tlast_missing,
    event_status_channel_halt => event_status_channel_halt,
    event_data_in_channel_halt => event_data_in_channel_halt,
    event_data_out_channel_halt => event_data_out_channel_halt
);

chunking_iface: axis_fft_chunking_interface
port map(
    s00_axis_aclk => aclk,
    s00_axis_aresetn => aresetn,
    s00_axis_tready => chunking_s_tready,
    s00_axis_tdata => chunking_s_tdata,
    s00_axis_tstrb => (others => '1'),
    s00_axis_tlast => '0',
    s00_axis_tvalid => chunking_s_tvalid,
    m00_axis_aclk => aclk,
    m00_axis_aresetn => aresetn,
    m00_axis_tvalid => s_axis_data_tvalid,
    m00_axis_tdata => s_axis_data_tdata,
    m00_axis_tstrb => open,
    m00_axis_tlast => s_axis_data_tlast,
    m00_axis_tready => s_axis_data_tready
);

bins_iface: axis_fft_bins_interface
port map(
    s00_axis_aclk => aclk,
    s00_axis_tdata => m_axis_data_tdata,
    s00_axis_tlast => m_axis_data_tlast,
    s00_axis_tuser => unsigned(m_axis_data_tuser(6-1 downto 0)),
    s00_axis_tvalid => m_axis_data_tvalid,
    vsync_i => vsync_i,
    bin_read_index_i => bin_read_index_i,
    rgb_value_o => rgb_value_o,
    dbg_tuser_o => open,
    dbg_magnitude_o => open
);


-- Clock generation process
clock_proc: process
begin
    aclk <= '0';
    wait for CLOCK_PERIOD/2;
    aclk <= '1';
    wait for CLOCK_PERIOD/2;
end process;

lrclk_gen : process
begin
    lrclk <= '0';
    wait for LRCLK_PERIOD/2;
    lrclk <= '1';
    wait for LRCLK_PERIOD/2;
end process;

pixel_clk_gen : process
begin
    pixel_clk <= '0';
    wait for PIXEL_CLK_PERIOD/2;
    pixel_clk <= '1';
    wait for PIXEL_CLK_PERIOD/2;
end process;

-- Vsync generation process
process
    variable h_count : integer := 0;
    variable v_count : integer := 0;
begin
    wait for PIXEL_CLK_PERIOD;
    loop
        for v_count in 0 to V_TOTAL-1 loop
            for h_count in 0 to H_TOTAL-1 loop
                if (v_count >= V_ACTIVE + V_FRONT_PORCH) and
                   (v_count < V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE) then
                    vsync_i <= '1';  -- Active vsync
                else
                    vsync_i <= '0';  -- Inactive vsync
                end if;
                wait until rising_edge(pixel_clk);
            end loop;
        end loop;
    end loop;

    wait;
end process;

stim_proc: process
    constant SAMPLE_RATE : real := 48.0e3; -- 48 kHz
    constant SIGNAL_FREQ : real := 10000.0;   -- 440 Hz sine wave
    variable current_sample : integer := 0;
    variable sine_value : integer := 0;
begin
    loop
            -- Feed input data: 440 Hz sine wave
            chunking_s_tvalid <= '1';
            sine_value := integer(8388607.0 * sin(2.0 * MATH_PI * SIGNAL_FREQ * real(current_sample) / SAMPLE_RATE));

            chunking_s_tdata <= (others => '0');
            chunking_s_tdata(23 downto 0) <= std_logic_vector(to_signed(sine_value, 24));
            -- Wait for handshaking if needed
            if chunking_s_tready = '0' then
                wait until chunking_s_tready = '1' and rising_edge(aclk);
            end if;

            wait until rising_edge(aclk);
            chunking_s_tvalid <= '0';

            wait until rising_edge(aclk);
            chunking_s_tvalid <= '1';

            -- Wait for handshaking if needed
            if chunking_s_tready = '0' then
                wait until chunking_s_tready = '1' and rising_edge(aclk);
            end if;
            wait until rising_edge(aclk);
            chunking_s_tvalid <= '0';
            current_sample := current_sample + 1;
            wait until falling_edge(lrclk);

        wait until rising_edge(aclk);
    end loop;
end process;



end behavioral;
