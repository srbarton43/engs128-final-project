library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axis_chunking_interface is
end tb_axis_chunking_interface ;

architecture Behavioral of tb_axis_chunking_interface is

    -- Constants
    constant AXIS_DATA_WIDTH : integer := 32;
    constant FFT_DATA_WIDTH : integer := 48;
    constant I2S_DATA_WIDTH : integer := 24;
    constant FFT_DEPTH : integer := 16;
    constant CLK_PERIOD : time := 10 ns;

    -- Component declaration
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

    -- Signals for clock and reset
    signal s_aclk : std_logic := '0';
    signal m_aclk : std_logic := '0';
    signal s_aresetn : std_logic := '0';
    signal m_aresetn : std_logic := '0';

    -- Signals for S00_AXIS interface
    signal s00_axis_tready : std_logic;
    signal s00_axis_tdata : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
    signal s00_axis_tvalid : std_logic := '0';

    -- Signals for M00_AXIS interface
    signal m00_axis_tvalid : std_logic := '0';
    signal m00_axis_tdata : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
    signal m00_axis_tstrb : std_logic_vector((FFT_DATA_WIDTH/8)-1 downto 0):= (others => '1');
    signal m00_axis_tlast : std_logic;
    signal m00_axis_tready : std_logic := '0';

    -- Test control
    signal test_done : boolean := false;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: axis_fft_chunking_interface
        generic map (
            AXIS_DATA_WIDTH => AXIS_DATA_WIDTH,
            FFT_DATA_WIDTH => FFT_DATA_WIDTH,
            I2S_DATA_WIDTH => I2S_DATA_WIDTH,
            FFT_DEPTH => FFT_DEPTH
        )
        port map (
            s00_axis_aclk => s_aclk,
            s00_axis_aresetn => s_aresetn,
            s00_axis_tstrb => "1111",
            s00_axis_tlast => '0',
            s00_axis_tready => s00_axis_tready,
            s00_axis_tdata => s00_axis_tdata,
            s00_axis_tvalid => s00_axis_tvalid,

            m00_axis_aclk => m_aclk,
            m00_axis_aresetn => m_aresetn,
            m00_axis_tvalid => m00_axis_tvalid,
            m00_axis_tdata => m00_axis_tdata,
            m00_axis_tstrb => m00_axis_tstrb,
            m00_axis_tlast => m00_axis_tlast,
            m00_axis_tready => m00_axis_tready
        );

    -- Clock generation processes
    s_clk_process: process
    begin
        while not test_done loop
            s_aclk <= '0';
            wait for CLK_PERIOD/2;
            s_aclk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    m_clk_process: process
    begin
        while not test_done loop
            m_aclk <= '0';
            wait for CLK_PERIOD/2;
            m_aclk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Initialize
        s_aresetn <= '0';
        m_aresetn <= '0';
        s00_axis_tvalid <= '0';
        m00_axis_tready <= '1';

        wait for CLK_PERIOD * 5;

        -- Release reset
        s_aresetn <= '1';
        m_aresetn <= '1';

        wait for CLK_PERIOD * 2;

        -- Test 1: Fill the FIFO
        -- Send data until FIFO is full
        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s_aclk);
            if s00_axis_tready = '1' then
                s00_axis_tdata <= std_logic_vector(to_unsigned(i + 1, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            else
                -- Wait until tready is asserted
                wait until s00_axis_tready = '1';
                wait until rising_edge(s_aclk);
                s00_axis_tdata <= std_logic_vector(to_unsigned(i + 1, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            end if;
--            wait until rising_edge(s_aclk);
           -- s00_axis_tvalid <= '0';
        end loop;

        -- Test 2: Read from FIFO
        -- Now enable m00_axis_tready to read data
--        wait for CLK_PERIOD * 5;
        m00_axis_tready <= '1';

        -- Wait for FIFO to empty and tlast to be asserted
        wait until m00_axis_tlast = '1';
        wait for CLK_PERIOD * 2;

        -- Test 3: Fill and flush again
        -- Send more data to fill FIFO again
        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s_aclk);
            if s00_axis_tready = '1' then
                s00_axis_tdata <= std_logic_vector(to_unsigned(i+100, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            else
                wait until s00_axis_tready = '1';
                wait until rising_edge(s_aclk);
                s00_axis_tdata <= std_logic_vector(to_unsigned(i+100, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            end if;
            wait until rising_edge(s_aclk);
            s00_axis_tvalid <= '0';
        end loop;

        -- Wait for FIFO to empty and tlast to be asserted again
        wait until m00_axis_tlast = '1';
        wait for CLK_PERIOD * 2;

        -- Test 4: Test reset during operation
        -- Start filling FIFO
        for i in 0 to 10 loop
            wait until rising_edge(s_aclk);
            if s00_axis_tready = '1' then
                s00_axis_tdata <= std_logic_vector(to_unsigned(i+200, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            else
                wait until s00_axis_tready = '1';
                wait until rising_edge(s_aclk);
                s00_axis_tdata <= std_logic_vector(to_unsigned(i+200, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            end if;
            wait until rising_edge(s_aclk);
            s00_axis_tvalid <= '0';
        end loop;

        -- Apply reset
        s_aresetn <= '0';
        m_aresetn <= '0';
        wait for CLK_PERIOD * 5;
        s_aresetn <= '1';
        m_aresetn <= '1';
        wait for CLK_PERIOD * 5;

        -- Final test: Normal operation after reset
        -- Send data
        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s_aclk);
            if s00_axis_tready = '1' then
                s00_axis_tdata <= std_logic_vector(to_unsigned(i+300, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            else
                wait until s00_axis_tready = '1';
                wait until rising_edge(s_aclk);
                s00_axis_tdata <= std_logic_vector(to_unsigned(i+300, AXIS_DATA_WIDTH));
                s00_axis_tvalid <= '1';
            end if;
            wait until rising_edge(s_aclk);
            s00_axis_tvalid <= '0';
        end loop;

        -- Wait for FIFO to empty and tlast to be asserted
        wait until m00_axis_tlast = '1';
        wait for CLK_PERIOD * 10;

        -- End test
        test_done <= true;
        report "Test completed successfully";
        std.env.stop;
    end process;

--    -- Monitor process to check outputs
--    monitor: process
--        variable data_count : integer := 0;
--    begin
--        wait until m00_axis_tvalid = '1';

--        while not test_done loop
--            if m00_axis_tvalid = '1' and m00_axis_tready = '1' then
--                report "Data received: " & integer'image(to_integer(unsigned(m00_axis_tdata(I2S_DATA_WIDTH-1 downto 0))));
--                data_count := data_count + 1;

--                if m00_axis_tlast = '1' then
--                    report "TLAST received after " & integer'image(data_count) & " data words";
--                    data_count := 0;
--                end if;
--            end if;

--            wait until rising_edge(m_aclk);
--        end loop;

--        wait;
--    end process;

end Behavioral;
