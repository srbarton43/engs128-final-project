library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_fft_with_chunking is
end entity tb_fft_with_chunking;

architecture behavioral of tb_fft_with_chunking is
    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;
    constant FFT_SIZE : integer := 64;
    constant AXIS_DATA_WIDTH : integer := 32;
    constant FFT_DATA_WIDTH : integer := 48;
    constant I2S_DATA_WIDTH : integer := 24;

    -- Component declarations
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
    
    COMPONENT axis_fft_chunking_interface
    Generic (
        AXIS_DATA_WIDTH : integer := 32;
        FFT_DATA_WIDTH : integer := 48;
        I2S_DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 64
    );
    Port (
        -- Ports of Axi Responder Bus Interface S00_AXIS
        s00_axis_aclk     : in std_logic;
        s00_axis_aresetn  : in std_logic;
        s00_axis_tready   : out std_logic;
        s00_axis_tdata    : in std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
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
        m00_axis_tready   : in std_logic
    );
    END COMPONENT;

    -- Clock and reset signals
    signal aclk : std_logic := '0';
    signal aresetn : std_logic := '0';
    
    -- Sine wave generator to chunking interface signals
    signal s00_axis_tdata : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
    signal s00_axis_tstrb : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0) := (others => '1');
    signal s00_axis_tlast : std_logic := '0';
    signal s00_axis_tvalid : std_logic := '0';
    signal s00_axis_tready : std_logic;
    
    -- Chunking interface to FFT signals
    signal m00_axis_tdata : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
    signal m00_axis_tstrb : std_logic_vector((FFT_DATA_WIDTH/8)-1 downto 0);
    signal m00_axis_tlast : std_logic;
    signal m00_axis_tvalid : std_logic;
    signal m00_axis_tready : std_logic;
    
    -- FFT configuration
    signal s_axis_config_tdata : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_config_tvalid : std_logic := '0';
    signal s_axis_config_tready : std_logic;
    
    -- FFT output signals
    signal m_axis_data_tdata : std_logic_vector(47 downto 0);
    signal m_axis_data_tuser : std_logic_vector(7 downto 0);
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tlast : std_logic;
    
    -- FFT event signals
    signal event_frame_started : std_logic;
    signal event_tlast_unexpected : std_logic;
    signal event_tlast_missing : std_logic;
    signal event_status_channel_halt : std_logic;
    signal event_data_in_channel_halt : std_logic;
    signal event_data_out_channel_halt : std_logic;
    
    -- Magnitude calculation signals
    signal magnitude_out : unsigned(23 downto 0) := (others => '0');
    signal magnitude_valid : std_logic := '0';
    signal peak_detected : std_logic := '0';
    
    -- Simulation control
    signal sim_done : boolean := false;
    
begin
    -- Clock generation
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
    
    -- Reset generation
    reset_proc: process
    begin
        aresetn <= '0';
        wait for CLOCK_PERIOD * 10;
        aresetn <= '1';
        wait;
    end process;
    
    -- Instantiate the chunking interface
    chunking_inst: axis_fft_chunking_interface
    generic map (
        AXIS_DATA_WIDTH => AXIS_DATA_WIDTH,
        FFT_DATA_WIDTH => FFT_DATA_WIDTH,
        I2S_DATA_WIDTH => I2S_DATA_WIDTH,
        FFT_DEPTH => FFT_SIZE
    )
    port map (
        -- Input side
        s00_axis_aclk => aclk,
        s00_axis_aresetn => aresetn,
        s00_axis_tready => s00_axis_tready,
        s00_axis_tdata => s00_axis_tdata,
        s00_axis_tstrb => s00_axis_tstrb,
        s00_axis_tlast => s00_axis_tlast,
        s00_axis_tvalid => s00_axis_tvalid,
        
        -- Output side
        m00_axis_aclk => aclk,
        m00_axis_aresetn => aresetn,
        m00_axis_tvalid => m00_axis_tvalid,
        m00_axis_tdata => m00_axis_tdata,
        m00_axis_tstrb => m00_axis_tstrb,
        m00_axis_tlast => m00_axis_tlast,
        m00_axis_tready => m00_axis_tready
    );
    
    -- Instantiate the FFT core
    fft_inst: xfft_0
    port map (
        aclk => aclk,
        
        -- Configuration channel
        s_axis_config_tdata => s_axis_config_tdata,
        s_axis_config_tvalid => s_axis_config_tvalid,
        s_axis_config_tready => s_axis_config_tready,
        
        -- Input data channel (from chunking interface)
        s_axis_data_tdata => m00_axis_tdata,
        s_axis_data_tvalid => m00_axis_tvalid,
        s_axis_data_tready => m00_axis_tready,
        s_axis_data_tlast => m00_axis_tlast,
        
        -- Output data channel
        m_axis_data_tdata => m_axis_data_tdata,
        m_axis_data_tuser => m_axis_data_tuser,
        m_axis_data_tvalid => m_axis_data_tvalid,
        m_axis_data_tready => '1',  -- Always ready to receive output
        m_axis_data_tlast => m_axis_data_tlast,
        
        -- Event signals
        event_frame_started => event_frame_started,
        event_tlast_unexpected => event_tlast_unexpected,
        event_tlast_missing => event_tlast_missing,
        event_status_channel_halt => event_status_channel_halt,
        event_data_in_channel_halt => event_data_in_channel_halt,
        event_data_out_channel_halt => event_data_out_channel_halt
    );
    
    -- Stimulus process - generate sine wave
    stim_proc: process
        constant SAMPLE_RATE : real := 25.0e6;  -- 25 MHz sample rate
        constant SIGNAL_FREQ : real := 10000.0;  -- 10 kHz sine wave
        variable current_sample : integer := 0;
        variable sine_value : integer := 0;
        variable frame_count : integer := 0;
    begin
        -- Wait for reset to complete
        wait until aresetn = '1';
        wait for CLOCK_PERIOD * 5;
        
        -- Configure FFT
        s_axis_config_tdata <= x"01";  -- Forward FFT, default scaling
        s_axis_config_tvalid <= '1';
        wait for CLOCK_PERIOD * 5;
        s_axis_config_tvalid <= '0';
        wait for CLOCK_PERIOD * 10;
        
        -- Generate multiple frames of sine wave data
            loop
                wait until rising_edge(aclk) and s00_axis_tready = '1';
                
                -- Calculate sine value for current sample
                sine_value := integer(8388607.0 * sin(2.0 * MATH_PI * SIGNAL_FREQ * real(current_sample) / SAMPLE_RATE));
                
                -- Format the data: real part in lower bits
                s00_axis_tdata(I2S_DATA_WIDTH-1 downto 0) <= std_logic_vector(to_signed(sine_value, I2S_DATA_WIDTH));
                s00_axis_tdata(AXIS_DATA_WIDTH-1 downto I2S_DATA_WIDTH) <= (others => '0');
                
                -- Set tlast on the final sample of each frame
                
                s00_axis_tvalid <= '1';
                current_sample := current_sample + 1;
                wait for CLOCK_PERIOD/4;
            end loop;
            
--            -- Small gap between frames
--            s00_axis_tvalid <= '0';
--            s00_axis_tlast <= '0';
--            wait for CLOCK_PERIOD * 10;
        
        -- End of stimulus
--        s00_axis_tvalid <= '0';
        
        -- Wait for processing to complete
--        wait for CLOCK_PERIOD * FFT_SIZE * 20;
        
        -- End simulation
        sim_done <= true;
        wait;
    end process;
    
    -- Magnitude calculation process
    magnitude_calc_proc: process(m_axis_data_tvalid, m_axis_data_tdata)
        variable re_signed : signed(23 downto 0);
        variable im_signed : signed(23 downto 0);
        variable re_abs : unsigned(23 downto 0);
        variable im_abs : unsigned(23 downto 0);
        variable magnitude_temp : unsigned(24 downto 0);
    begin
        magnitude_valid <= '0';
        peak_detected <= '0';
        magnitude_out <= (others => '0');

        if m_axis_data_tvalid = '1' then
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

            -- Approximate magnitude: mag ≈ max(|re|, |im|) + 0.5 * min(|re|, |im|)
            if re_abs >= im_abs then
                magnitude_temp := (('0' & re_abs) + ('0' & im_abs(23 downto 1))); -- re + im/2
            else
                magnitude_temp := (('0' & im_abs) + ('0' & re_abs(23 downto 1))); -- im + re/2
            end if;

            magnitude_out <= magnitude_temp(23 downto 0);
            magnitude_valid <= '1';

            -- Simple peak detection
            if magnitude_temp > x"100000" then -- Threshold
                peak_detected <= '1';
            end if;
        end if;
    end process;
    
    -- Monitor process to display FFT outputs
    monitor_proc: process
        variable bin_count : integer := 0;
    begin
        wait until aresetn = '1';
        
        while not sim_done loop
            wait until rising_edge(aclk);
            
            if magnitude_valid = '1' then
                report "FFT Bin " & integer'image(bin_count) & 
                       ": Magnitude = " & integer'image(to_integer(magnitude_out));
                
                if peak_detected = '1' then
                    report "Peak detected at bin " & integer'image(bin_count);
                end if;
                
                bin_count := (bin_count + 1) mod FFT_SIZE;
            end if;
        end loop;
        
        wait;
    end process;

end behavioral;