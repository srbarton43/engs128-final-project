library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Bring in your RGB LUT package so the TB sees both the LUT and the bins-interface entity
use work.rgb_package.all;

entity tb_fft_bin is
end entity;

architecture behavioral of tb_fft_bin is

  ------------------------------------------------------------------------
  -- Constants
  constant CLOCK_PERIOD : time := 10 ns;    -- 100 MHz
  constant FFT_SIZE     : integer := 64;    -- FFT length

  ------------------------------------------------------------------------
  -- FFT core component
  component xfft_0
    port (
      aclk                         : in  std_logic;
      s_axis_config_tdata          : in  std_logic_vector(15 downto 0);
      s_axis_config_tvalid         : in  std_logic;
      s_axis_config_tready         : out std_logic;
      s_axis_data_tdata            : in  std_logic_vector(47 downto 0);
      s_axis_data_tvalid           : in  std_logic;
      s_axis_data_tready           : out std_logic;
      s_axis_data_tlast            : in  std_logic;
      m_axis_data_tdata            : out std_logic_vector(47 downto 0);
      m_axis_data_tuser            : out std_logic_vector(7  downto 0);
      m_axis_data_tvalid           : out std_logic;
      m_axis_data_tready           : in  std_logic;
      m_axis_data_tlast            : out std_logic;
      event_frame_started          : out std_logic;
      event_tlast_unexpected       : out std_logic;
      event_tlast_missing          : out std_logic;
      event_status_channel_halt    : out std_logic;
      event_data_in_channel_halt   : out std_logic;
      event_data_out_channel_halt  : out std_logic
    );
  end component;

  ------------------------------------------------------------------------
  -- Testbench signals for FFT
  signal aclk                 : std_logic := '0';
  signal reset                : std_logic := '0';

  -- AXI-Stream config
  signal s_axis_config_tdata  : std_logic_vector(15 downto 0) := (others => '0');
  signal s_axis_config_tvalid : std_logic := '0';
  signal s_axis_config_tready : std_logic;

  -- AXI-Stream data in
  signal s_axis_data_tdata    : std_logic_vector(47 downto 0) := (others => '0');
  signal s_axis_data_tvalid   : std_logic := '0';
  signal s_axis_data_tready   : std_logic;
  signal s_axis_data_tlast    : std_logic := '0';

  -- AXI-Stream data out
  signal m_axis_data_tdata    : std_logic_vector(47 downto 0);
  signal m_axis_data_tuser    : std_logic_vector(7 downto 0);
  signal m_axis_data_tvalid   : std_logic;
  signal m_axis_data_tready   : std_logic := '1';
  signal m_axis_data_tlast    : std_logic;

  -- event signals (unused)
  signal event_frame_started        : std_logic;
  signal event_tlast_unexpected     : std_logic;
  signal event_tlast_missing        : std_logic;
  signal event_status_channel_halt  : std_logic;
  signal event_data_in_channel_halt : std_logic;
  signal event_data_out_channel_halt: std_logic;

  ------------------------------------------------------------------------
  -- Added: Bins-RAM interface signals
  signal color_select_i    : std_logic            := '0';
  signal bin_read_index_i  : unsigned(5 downto 0) := (others => '0');
  signal rgb_value_o       : std_logic_vector(23 downto 0);
  signal dbg_tuser_o       : unsigned(5 downto 0);
  signal dbg_magnitude_o   : unsigned(23 downto 0);
  signal dbg_rgb_lut_index : unsigned(7 downto 0);

begin

  ----------------------------------------------------------------------------
  -- Instantiate FFT core
  uut: xfft_0
    port map (
      aclk                         => aclk,
      s_axis_config_tdata          => s_axis_config_tdata,
      s_axis_config_tvalid         => s_axis_config_tvalid,
      s_axis_config_tready         => s_axis_config_tready,
      s_axis_data_tdata            => s_axis_data_tdata,
      s_axis_data_tvalid           => s_axis_data_tvalid,
      s_axis_data_tready           => s_axis_data_tready,
      s_axis_data_tlast            => s_axis_data_tlast,
      m_axis_data_tdata            => m_axis_data_tdata,
      m_axis_data_tuser            => m_axis_data_tuser,
      m_axis_data_tvalid           => m_axis_data_tvalid,
      m_axis_data_tready           => m_axis_data_tready,
      m_axis_data_tlast            => m_axis_data_tlast,
      event_frame_started          => event_frame_started,
      event_tlast_unexpected       => event_tlast_unexpected,
      event_tlast_missing          => event_tlast_missing,
      event_status_channel_halt    => event_status_channel_halt,
      event_data_in_channel_halt   => event_data_in_channel_halt,
      event_data_out_channel_halt  => event_data_out_channel_halt
    );

  ----------------------------------------------------------------------------
  -- Instantiate bins-RAM interface
  bins_inst : entity work.axis_fft_bins_interface
    generic map (
      DATA_WIDTH           => 24,
      FFT_DEPTH            => FFT_SIZE,
      RGB_LUT_INDEX_WIDTH  => 8,
      BIN_INDEX_DEPTH      => 6
    )
    port map (
      s00_axis_aclk    => aclk,
      s00_axis_tdata   => m_axis_data_tdata,
      s00_axis_tlast   => m_axis_data_tlast,
      s00_axis_tuser   => unsigned(m_axis_data_tuser(5 downto 0)),
      s00_axis_tvalid  => m_axis_data_tvalid,
      color_select_i   => color_select_i,
      vsync_i          => m_axis_data_tlast,
      bin_read_index_i => bin_read_index_i,
      rgb_value_o       => rgb_value_o,
      dbg_tuser_o       => dbg_tuser_o,
      dbg_magnitude_o   => dbg_magnitude_o,
      dbg_rgb_lut_index => dbg_rgb_lut_index,
      dbg_rgb_write_val => open
    );

  ----------------------------------------------------------------------------
  -- Clock generation
  clock_proc: process
  begin
    while true loop
      aclk <= '0';
      wait for CLOCK_PERIOD/2;
      aclk <= '1';
      wait for CLOCK_PERIOD/2;
    end loop;
  end process;

  ----------------------------------------------------------------------------
  -- Stimulus process: sends a forward-FFT config once, then
  -- repeatedly feeds a 10 kHz sine-wave of length FFT_SIZE
  stim_proc: process
    constant SAMPLE_RATE : real := 100.0e6;
    constant SIGNAL_FREQ : real := 10000.0;
    variable current_sample : integer := 0;
    variable sine_value     : integer;
  begin
    -- one-time config
    s_axis_config_tdata  <= x"0001";
    s_axis_config_tvalid <= '1';
    wait for 5 * CLOCK_PERIOD;
    s_axis_config_tvalid <= '0';
    wait for 100 * CLOCK_PERIOD;

    -- main loop
    loop
      s_axis_data_tvalid <= '1';
      for i in 0 to FFT_SIZE-1 loop
        wait until rising_edge(aclk);

        -- compute 24-bit signed sine
        sine_value :=
          integer(8388607.0 * sin(2.0 * math_pi * real(current_sample)/SAMPLE_RATE));

        s_axis_data_tdata(23 downto 0)  <= std_logic_vector(to_signed(sine_value,24));
        s_axis_data_tdata(47 downto 24) <= (others=>'0');

        -- VALID VHDL if-expression for tlast
        if i = FFT_SIZE-1 then
          s_axis_data_tlast <= '1';
        else
          s_axis_data_tlast <= '0';
        end if;

        -- back-pressure handling
        if s_axis_data_tready = '0' then
          wait until s_axis_data_tready = '1' and rising_edge(aclk);
        end if;

        current_sample := current_sample + 1;
      end loop;

      s_axis_data_tvalid <= '0';
      s_axis_data_tlast  <= '0';
      wait until rising_edge(aclk);
    end loop;
  end process;

  ----------------------------------------------------------------------------
  -- Simple magnitude-calc for debug
  magnitude_calc_proc: process(m_axis_data_tvalid, m_axis_data_tready, m_axis_data_tdata)
    variable re_signed, im_signed : signed(23 downto 0);
    variable re_abs,    im_abs    : unsigned(23 downto 0);
    variable mag_temp               : unsigned(24 downto 0);
  begin
    if m_axis_data_tvalid='1' and m_axis_data_tready='1' then
      re_signed := signed(m_axis_data_tdata(23 downto 0));
      im_signed := signed(m_axis_data_tdata(47 downto 24));
      -- abs
      if re_signed >= 0 then re_abs := unsigned(re_signed);
      else               re_abs := unsigned(-re_signed); end if;
      if im_signed >= 0 then im_abs := unsigned(im_signed);
      else               im_abs := unsigned(-im_signed); end if;
      -- approx mag
      if re_abs >= im_abs then
        mag_temp := ("0"&re_abs) + ("0"&im_abs(23 downto 1));
      else
        mag_temp := ("0"&im_abs) + ("0"&re_abs(23 downto 1));
      end if;
      dbg_magnitude_o <= mag_temp(23 downto 0);
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Read-out process: cycle through all FFT bins each frame
  read_bins_proc: process(aclk)
  begin
    if rising_edge(aclk) then
      if m_axis_data_tvalid = '1' then
        if m_axis_data_tlast = '1' then
          bin_read_index_i <= (others => '0');
        else
          bin_read_index_i <= bin_read_index_i + 1;
        end if;
      end if;
    end if;
  end process;

end architecture behavioral;
