library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axis_splitting_chunking is
end tb_axis_splitting_chunking;

architecture Behavioral of tb_axis_splitting_chunking is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant DATA_WIDTH : integer := 32;
    constant FFT_DATA_WIDTH : integer := 48;
    constant I2S_DATA_WIDTH : integer := 24;
    constant FFT_DEPTH : integer := 4; -- Adjusted for 4 samples per chunk

    -- Signals for axis_splitter
    signal s00_axis_aclk     : std_logic := '0';
    signal s00_axis_aresetn  : std_logic := '0';
    signal s00_axis_tready   : std_logic;
    signal s00_axis_tdata    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal s00_axis_tstrb    : std_logic_vector((DATA_WIDTH/8)-1 downto 0) := (others => '1');
    signal s00_axis_tlast    : std_logic := '0';
    signal s00_axis_tvalid   : std_logic := '0';

    signal m00_axis_tvalid   : std_logic;
    signal m00_axis_tdata    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal m00_axis_tstrb    : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    signal m00_axis_tlast    : std_logic;
    signal m00_axis_tready   : std_logic := '1';

    signal m01_axis_tvalid   : std_logic;
    signal m01_axis_tdata    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal m01_axis_tstrb    : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    signal m01_axis_tlast    : std_logic;
    signal m01_axis_tready   : std_logic := '1';

    -- Signals for chunking interfaces
    signal chunk0_m00_axis_tvalid : std_logic;
    signal chunk0_m00_axis_tdata  : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
    signal chunk0_m00_axis_tstrb  : std_logic_vector((FFT_DATA_WIDTH/8)-1 downto 0);
    signal chunk0_m00_axis_tlast  : std_logic;
    signal chunk0_m00_axis_tready : std_logic := '1';

    signal chunk1_m00_axis_tvalid : std_logic;
    signal chunk1_m00_axis_tdata  : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
    signal chunk1_m00_axis_tstrb  : std_logic_vector((FFT_DATA_WIDTH/8)-1 downto 0);
    signal chunk1_m00_axis_tlast  : std_logic;
    signal chunk1_m00_axis_tready : std_logic := '1';

    -- Test signals
    signal test_data : std_logic_vector(95 downto 0) := X"1234567890ABCDEF12345678";
    signal test_done : boolean := false;
    signal m00_axis_aclk : std_logic;
    signal m01_axis_aclk : std_logic;

begin
    -- Clock generation
    s00_axis_aclk <= not s00_axis_aclk after CLK_PERIOD/2;
    m00_axis_aclk <= s00_axis_aclk;
    m01_axis_aclk <= s00_axis_aclk;

    -- Instantiate axis_splitter
    uut_splitter: entity work.axis_splitter
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            s00_axis_aclk     => s00_axis_aclk,
            s00_axis_aresetn  => s00_axis_aresetn,
            s00_axis_tready   => s00_axis_tready,
            s00_axis_tdata    => s00_axis_tdata,
            s00_axis_tstrb    => s00_axis_tstrb,
            s00_axis_tlast    => s00_axis_tlast,
            s00_axis_tvalid   => s00_axis_tvalid,
            m00_axis_aclk     => s00_axis_aclk,
            m00_axis_aresetn  => s00_axis_aresetn,
            m00_axis_tvalid   => m00_axis_tvalid,
            m00_axis_tdata    => m00_axis_tdata,
            m00_axis_tstrb    => m00_axis_tstrb,
            m00_axis_tlast    => m00_axis_tlast,
            m00_axis_tready   => m00_axis_tready,
            m01_axis_aclk     => s00_axis_aclk,
            m01_axis_aresetn  => s00_axis_aresetn,
            m01_axis_tvalid   => m01_axis_tvalid,
            m01_axis_tdata    => m01_axis_tdata,
            m01_axis_tstrb    => m01_axis_tstrb,
            m01_axis_tlast    => m01_axis_tlast,
            m01_axis_tready   => m01_axis_tready
        );

    -- Instantiate first chunking interface (connected to m00_axis)
    uut_chunk0: entity work.axis_fft_chunking_interface
        generic map (
            AXIS_DATA_WIDTH => DATA_WIDTH,
            FFT_DATA_WIDTH  => FFT_DATA_WIDTH,
            I2S_DATA_WIDTH  => I2S_DATA_WIDTH,
            FFT_DEPTH       => FFT_DEPTH
        )
        port map (
            s00_axis_aclk     => s00_axis_aclk,
            s00_axis_aresetn  => s00_axis_aresetn,
            s00_axis_tready   => m00_axis_tready,
            s00_axis_tdata    => m00_axis_tdata,
            s00_axis_tstrb    => m00_axis_tstrb,
            s00_axis_tlast    => m00_axis_tlast,
            s00_axis_tvalid   => m00_axis_tvalid,
            m00_axis_aclk     => s00_axis_aclk,
            m00_axis_aresetn  => s00_axis_aresetn,
            m00_axis_tvalid   => chunk0_m00_axis_tvalid,
            m00_axis_tdata    => chunk0_m00_axis_tdata,
            m00_axis_tstrb    => chunk0_m00_axis_tstrb,
            m00_axis_tlast    => chunk0_m00_axis_tlast,
            m00_axis_tready   => chunk0_m00_axis_tready
        );

    -- Instantiate second chunking interface (connected to m01_axis)
    uut_chunk1: entity work.axis_fft_chunking_interface
        generic map (
            AXIS_DATA_WIDTH => DATA_WIDTH,
            FFT_DATA_WIDTH  => FFT_DATA_WIDTH,
            I2S_DATA_WIDTH  => I2S_DATA_WIDTH,
            FFT_DEPTH       => FFT_DEPTH
        )
        port map (
            s00_axis_aclk     => s00_axis_aclk,
            s00_axis_aresetn  => s00_axis_aresetn,
            s00_axis_tready   => m01_axis_tready,
            s00_axis_tdata    => m01_axis_tdata,
            s00_axis_tstrb    => m01_axis_tstrb,
            s00_axis_tlast    => m01_axis_tlast,
            s00_axis_tvalid   => m01_axis_tvalid,
            m00_axis_aclk     => s00_axis_aclk,
            m00_axis_aresetn  => s00_axis_aresetn,
            m00_axis_tvalid   => chunk1_m00_axis_tvalid,
            m00_axis_tdata    => chunk1_m00_axis_tdata,
            m00_axis_tstrb    => chunk1_m00_axis_tstrb,
            m00_axis_tlast    => chunk1_m00_axis_tlast,
            m00_axis_tready   => chunk1_m00_axis_tready
        );

    -- Stimulus process
    stimulus: process
        variable sample_count : integer := 0;
    begin
        -- Reset
        s00_axis_aresetn <= '0';
        wait for CLK_PERIOD * 2;
        s00_axis_aresetn <= '1';
        wait for CLK_PERIOD * 2;

        -- Send 196 bits (8 samples of 24 bits each, in 32-bit transactions)
        for i in 0 to 7 loop
            s00_axis_tvalid <= '1';
            s00_axis_tdata <= test_data((95 - i *32) downto (64 - i * 32));
            if i = 7 then
                s00_axis_tlast <= '1';
            end if;
            wait until s00_axis_tready = '1' and rising_edge(s00_axis_aclk);
            wait for CLK_PERIOD;
        end loop;
        s00_axis_tvalid <= '0';
        s00_axis_tlast <= '0';

        -- Wait for chunking output
        wait for CLK_PERIOD * 20;
        test_done <= true;
        wait;
    end process;

--    -- Checker process for chunk0
--    check_chunk0: process
--        variable expected_data : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
--        variable sample_count : integer := 0;
--    begin
--        wait until chunk0_m00_axis_tvalid = '1' and rising_edge(s00_axis_aclk);
--        for i in 0 to 3 loop
--            expected_data := (others => '0');
--            expected_data(I2S_DATA_WIDTH-1 downto 0) := test_data(195 - i*24 downto 172 - i*24);
--            assert chunk0_m00_axis_tdata = expected_data
--                report "Chunk0 mismatch at sample " & integer'image(i) & ": expected " & to_hstring(expected_data) & ", got " & to_hstring(chunk0_m00_axis_tdata)
--                severity error;
--            if i = 3 then
--                assert chunk0_m00_axis_tlast = '1'
--                    report "Chunk0 tlast not asserted at sample 3"
--                    severity error;
--            end if;
--            wait until chunk0_m00_axis_tvalid = '1' and rising_edge(s00_axis_aclk);
--        end loop;
--    end process;

--    -- Checker process for chunk1
--    check_chunk1: process
--        variable expected_data : std_logic_vector(FFT_DATA_WIDTH-1 downto 0);
--        variable sample_count : integer := 0;
--    begin
--        wait until chunk1_m00_axis_tvalid = '1' and rising_edge(s00_axis_aclk);
--        for i in 0 to 3 loop
--            expected_data := (others => '0');
--            expected_data(I2S_DATA_WIDTH-1 downto 0) := test_data(195 - i*24 downto 172 - i*24);
--            assert chunk1_m00_axis_tdata = expected_data
--                report "Chunk1 mismatch at sample " & integer'image(i) & ": expected " & to_hstring(expected_data) & ", got " & to_hstring(chunk1_m00_axis_tdata)
--                severity error;
--            if i = 3 then
--                assert chunk1_m00_axis_tlast = '1'
--                    report "Chunk1 tlast not asserted at sample 3"
--                    severity error;
--            end if;
--            wait until chunk1_m00_axis_tvalid = '1' and rising_edge(s00_axis_aclk);
--        end loop;
--    end process;

end Behavioral;
