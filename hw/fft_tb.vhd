library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- FFT testbench with signal generator

-- FFT testbench
entity fft_tb is
end entity fft_tb;

architecture behavioral of fft_tb is
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
    signal m_axis_data_tlast : std_logic;
    
    -- Event signals (not used in this testbench)
    signal event_frame_started : std_logic;
    signal event_tlast_unexpected : std_logic;
    signal event_tlast_missing : std_logic;
    signal event_status_channel_halt : std_logic;
    signal event_data_in_channel_halt : std_logic;
    signal event_data_out_channel_halt : std_logic;

    signal real_out, real_in : std_logic_vector(23 downto 0) := (others => '0');
    
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
    
    -- Main stimulus process
    stim_proc: process
        -- Variables for simulation
        variable real_part : integer := 0;
    begin
        -- Initialize configuration
--        s_axis_config_tdata <= x"0001"; -- Forward FFT, scale schedule: default
--        s_axis_config_tvalid <= '1';
--        wait for 5 * CLOCK_PERIOD;
--        s_axis_config_tvalid <= '0';
        wait for 5 * CLOCK_PERIOD;
        
        while true loop 
        -- Feed input data: single sine wave at 1/4 of the sampling frequency
        s_axis_data_tvalid <= '1';
        
        for i in 0 to FFT_SIZE-1 loop
            -- Generate real sine wave input with full 24-bit precision
            real_part := integer(15000.0 * sin(2 * MATH_PI * real(i) / real(FFT_SIZE)) + MATH_PI/2); -- Max 24-bit signed value (2^23-1)
            
            -- Format the data: real part in bits 23-0, imaginary part in bits 47-24
            -- Using full 24-bit precision for the real component
            s_axis_data_tdata(23 downto 0) <= std_logic_vector(to_signed(real_part, 24)); -- Full 24-bit real part
            s_axis_data_tdata(47 downto 24) <= (others => '0'); -- No imaginary component
            
            -- Set tlast on the final sample
            s_axis_data_tlast <= '0';
            if i = FFT_SIZE-1 then
                s_axis_data_tlast <= '1';
            end if;
            
            -- Wait for handshaking
            wait until rising_edge(aclk);
            if s_axis_data_tready = '0' then
                wait until s_axis_data_tready = '1' and rising_edge(aclk);
            end if;
        end loop;
        
        -- Reset data signals
        s_axis_data_tvalid <= '0';
        s_axis_data_tlast <= '0';
        
        -- Wait for the FFT processing to complete
        --wait until m_axis_data_tlast = '1' and rising_edge(aclk);
        wait until rising_edge(aclk);
        end loop;

    end process;
    real_in <= s_axis_data_tdata(23 downto 0);
    real_out <= m_axis_data_tdata(23 downto 0);

end architecture behavioral;