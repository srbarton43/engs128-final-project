library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- FFT testbench with signal generator

-- FFT testbench
entity tb_fft_sin is
end entity tb_fft_sin;

architecture behavioral of tb_fft_sin is
    -- Constants
    constant CLOCK_PERIOD : time := 7.14 ns; -- 140 MHz clock
    constant FFT_SIZE : integer := 256; -- FFT size

    -- Component declarations

    COMPONENT xfft_0
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
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

    -- Clock and reset signals
    signal aclk : std_logic := '0';

    -- AXI-Stream config interface
    signal s_axis_config_tdata : std_logic_vector(15 downto 0) := (others => '0');
    signal s_axis_config_tvalid : std_logic := '0';
    signal s_axis_config_tready : std_logic;

    -- AXI-Stream data input interface
    signal s_axis_data_tdata : std_logic_vector(47 downto 0) := (others => '0');
    signal s_axis_data_tvalid : std_logic := '0';
    signal s_axis_data_tready : std_logic;
    signal s_axis_data_tlast : std_logic := '0';

    -- Reset signal
    signal reset : std_logic := '0';

    -- AXI-Stream data output interface
    signal m_axis_data_tdata : std_logic_vector(47 downto 0);
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tready : std_logic := '1'; -- Always ready to receive output
    signal m_axis_data_tuser : std_logic_vector(7 downto 0);
    signal m_axis_data_tlast : std_logic;

    -- Event signals (not used in this testbench)
    signal event_frame_started : std_logic;
    signal event_tlast_unexpected : std_logic;
    signal event_tlast_missing : std_logic;
    signal event_status_channel_halt : std_logic;
    signal event_data_in_channel_halt : std_logic;
    signal event_data_out_channel_halt : std_logic;

    signal real_out, real_in : std_logic_vector(23 downto 0) := (others => '0');

    signal magnitude : unsigned(23 downto 0) := (others => '0');

    signal sample_counter : integer range 0 to FFT_SIZE-1 := 0;
    signal sample_valid : std_logic := '0';
    signal sample_data : integer := 0;
   
    -- Add these signals to your testbench
    signal magnitude_out : unsigned(23 downto 0) := (others => '0');
    signal magnitude_valid : std_logic := '0';
    signal bin_index : integer range 0 to FFT_SIZE-1 := 0;
    signal peak_detected : std_logic := '0';

    -- Simulation control
    signal sim_done : boolean := false;

begin




    -- Instantiate the FFT core
    uut: xfft_0
        PORT MAP (
            aclk => aclk,
            s_axis_config_tdata => s_axis_config_tdata,
            s_axis_config_tvalid => s_axis_config_tvalid,
            s_axis_config_tready => s_axis_config_tready,
            s_axis_data_tdata => s_axis_data_tdata,
            s_axis_data_tvalid => s_axis_data_tvalid,
            s_axis_data_tready => s_axis_data_tready,
            s_axis_data_tlast => s_axis_data_tlast,
            m_axis_data_tdata => m_axis_data_tdata,
            m_axis_data_tvalid => m_axis_data_tvalid,
            m_axis_data_tready => m_axis_data_tready,
            m_axis_data_tuser => m_axis_data_tuser,
            m_axis_data_tlast => m_axis_data_tlast,
            event_frame_started => event_frame_started,
            event_tlast_unexpected => event_tlast_unexpected,
            event_tlast_missing => event_tlast_missing,
            event_status_channel_halt => event_status_channel_halt,
            event_data_in_channel_halt => event_data_in_channel_halt,
            event_data_out_channel_halt => event_data_out_channel_halt
        );

    -- Clock generation process
    clock_proc: process
    begin
        while not sim_done loop
            aclk <= '0';
            wait for CLOCK_PERIOD/2;
            aclk <= '1';
            wait for CLOCK_PERIOD/2;
        end loop;
        wait;
    end process;

   -- Modified stim_proc with corrected sine wave generation
stim_proc: process
    constant SAMPLE_RATE : real := 140.0e6; -- 140 MHz clock rate
    constant SIGNAL_FREQ : real := 10000.0;   -- 440 Hz sine wave
    variable current_sample : integer := 0;
    variable sine_value : integer := 0;
begin
    -- Initialize configuration
    s_axis_config_tdata <= x"0001"; -- Forward FFT, scale schedule: default
    s_axis_config_tvalid <= '1';
    wait for 5 * CLOCK_PERIOD;
    s_axis_config_tvalid <= '0';
    wait for 100 * CLOCK_PERIOD;

    while true loop
        -- Feed input data: 440 Hz sine wave
        s_axis_data_tvalid <= '1';
        for i in 0 to FFT_SIZE-1 loop
            wait until rising_edge(aclk);
           
            -- Calculate sine value for current sample
            sine_value := integer(8388607.0 * sin(2.0 * MATH_PI * SIGNAL_FREQ * real(current_sample) / SAMPLE_RATE));
           
            -- Format the data: real part in bits 23-0, imaginary part in bits 47-24
            s_axis_data_tdata(23 downto 0) <= std_logic_vector(to_signed(sine_value, 24));
            s_axis_data_tdata(47 downto 24) <= (others => '0'); -- No imaginary component

            -- Set tlast on the final sample
            if i = FFT_SIZE-1 then
                s_axis_data_tlast <= '1';
            else
                s_axis_data_tlast <= '0';
            end if;

            -- Wait for handshaking if needed
            if s_axis_data_tready = '0' then
                wait until s_axis_data_tready = '1' and rising_edge(aclk);
            end if;
           
            current_sample := current_sample + 1;
        end loop;

        -- Reset data signals
        s_axis_data_tvalid <= '0';
        s_axis_data_tlast <= '0';
        -- Wait for the FFT processing to complete
        wait until rising_edge(aclk);
    end loop;
end process;

-- Replace your magnitude calculation process with this:
magnitude_calc_proc: process(aclk)
    variable re_signed : signed(23 downto 0);
    variable im_signed : signed(23 downto 0);
    variable re_abs : unsigned(23 downto 0);
    variable im_abs : unsigned(23 downto 0);
    variable re_sq : unsigned(47 downto 0);
    variable im_sq : unsigned(47 downto 0);
    variable mag_sq : unsigned(48 downto 0);
    variable magnitude_temp : unsigned(24 downto 0);
    variable bin_counter : integer range 0 to FFT_SIZE-1 := 0;
begin
    if rising_edge(aclk) then
        magnitude_valid <= '0';
        peak_detected <= '0';
       
        if m_axis_data_tvalid = '1' and m_axis_data_tready = '1' then
            -- Extract real and imaginary parts (signed format)
            re_signed := signed(m_axis_data_tdata(23 downto 0));
            im_signed := signed(m_axis_data_tdata(47 downto 24));
           
            -- Get absolute values for magnitude calculation
            if re_signed >= 0 then
                re_abs := unsigned(re_signed);
            else
                re_abs := unsigned(-re_signed);
            end if;
           
            if im_signed >= 0 then
                im_abs := unsigned(im_signed);
            else
                im_abs := unsigned(-im_signed);
            end if;
           
            -- Calculate magnitude squared
            re_sq := re_abs * re_abs;
            im_sq := im_abs * im_abs;
            mag_sq := ('0' & re_sq) + ('0' & im_sq);
           
            -- For spectral analysis, you often want magnitude, not magnitude squared
            -- This is a simple approximation: mag ≈ sqrt(re² + im²)
            -- For FPGA, we can use: mag ≈ max(|re|, |im|) + 0.5 * min(|re|, |im|)
            -- This gives about 4% error but is much simpler than sqrt
           
            if re_abs >= im_abs then
                magnitude_temp := ('0' & re_abs) + ('0' & im_abs(23 downto 1)); -- re + im/2
            else
                magnitude_temp := ('0' & im_abs) + ('0' & re_abs(23 downto 1)); -- im + re/2
            end if;
           
            magnitude_out <= magnitude_temp(23 downto 0);
            magnitude_valid <= '1';
            bin_index <= bin_counter;
           
            -- Simple peak detection - you can adjust threshold as needed
            if magnitude_temp > x"100000" then -- Adjust this threshold
                peak_detected <= '1';
            end if;
           
            -- Track bin index
            if m_axis_data_tlast = '1' then
                bin_counter := 0;
            else
                bin_counter := bin_counter + 1;
            end if;
        end if;
    end if;
end process;
end architecture behavioral;
