library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rgb_package.all;

entity tb_axis_fft_bins_interface is
end tb_axis_fft_bins_interface;

architecture Behavioral of tb_axis_fft_bins_interface is

    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant DATA_WIDTH : integer := 24;
    constant FFT_DEPTH : integer := 64;
    constant RGB_WIDTH : integer := 24;
    constant RGB_LUT_INDEX_WIDTH : integer := 8;
    constant BIN_INDEX_DEPTH : integer := 6;
    constant MAG_MSB_OFFSET : integer := 5;  -- Matches your UUT LUT indexing

    -- Signals for AXI-Stream interface
    signal s00_axis_aclk     : std_logic := '0';
    signal s00_axis_tdata    : std_logic_vector(DATA_WIDTH*2-1 downto 0) := (others => '0');  -- Real & Imag packed
    signal s00_axis_tlast    : std_logic := '0';
    signal s00_axis_tuser    : unsigned(BIN_INDEX_DEPTH-1 downto 0) := (others => '0');
    signal s00_axis_tvalid   : std_logic := '0';

    -- Control signals
    signal color_select_i    : std_logic := '0';  -- grayscale mode
    signal vsync_i           : std_logic := '0';
    signal bin_read_index_i  : unsigned(BIN_INDEX_DEPTH-1 downto 0) := (others => '0');

    -- Outputs from UUT
    signal rgb_value_o       : std_logic_vector(RGB_WIDTH-1 downto 0);
    signal dbg_tuser_o       : unsigned(BIN_INDEX_DEPTH-1 downto 0);
    signal dbg_magnitude_o   : unsigned(DATA_WIDTH-1 downto 0);
    signal dbg_rgb_lut_index : unsigned(RGB_LUT_INDEX_WIDTH-1 downto 0);
    signal dbg_rgb_write_val : std_logic_vector(RGB_WIDTH-1 downto 0);

    -- Test control flag
    signal test_done : boolean := false;

begin

    -- Clock generation: 100 MHz
    s00_axis_aclk <= not s00_axis_aclk after CLK_PERIOD/2;

    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.axis_fft_bins_interface
        generic map (
            DATA_WIDTH          => DATA_WIDTH,
            FFT_DEPTH           => FFT_DEPTH,
            RGB_LUT_INDEX_WIDTH => RGB_LUT_INDEX_WIDTH,
            BIN_INDEX_DEPTH     => BIN_INDEX_DEPTH
        )
        port map (
            s00_axis_aclk     => s00_axis_aclk,
            s00_axis_tdata    => s00_axis_tdata,
            s00_axis_tlast    => s00_axis_tlast,
            s00_axis_tuser    => s00_axis_tuser,
            s00_axis_tvalid   => s00_axis_tvalid,
            color_select_i    => color_select_i,
            vsync_i           => vsync_i,
            bin_read_index_i  => bin_read_index_i,
            rgb_value_o       => rgb_value_o,
            dbg_tuser_o       => dbg_tuser_o,
            dbg_magnitude_o   => dbg_magnitude_o,
            dbg_rgb_lut_index => dbg_rgb_lut_index,
            dbg_rgb_write_val => dbg_rgb_write_val
        );

    ------------------------------------------------------------------------
    -- Stimulus process: drive input data and control signals
    ------------------------------------------------------------------------
    stimulus: process
    begin
        -- Initialization
        s00_axis_tvalid <= '0';
        s00_axis_tlast  <= '0';
        s00_axis_tuser  <= (others => '0');
        s00_axis_tdata  <= (others => '0');
        color_select_i  <= '0'; -- grayscale output
        vsync_i        <= '0';
        bin_read_index_i <= (others => '0');
        wait for CLK_PERIOD * 5;

        -- Start vsync (optional, depending on your design)
        vsync_i <= '1';
        wait for CLK_PERIOD * 5;
        vsync_i <= '0';

        -- Send AXI Stream samples - simulate FFT output with increasing magnitudes:
        for i in 0 to 4 loop
            s00_axis_tvalid <= '1';
            s00_axis_tuser  <= to_unsigned(i * 8, BIN_INDEX_DEPTH);  -- bins: 0, 8, 16, 24, 32

            -- Construct real and imaginary parts:
            -- Real = ((i+1) * 0x1000), Imag = 0, both signed 24-bit
            s00_axis_tdata <= std_logic_vector(to_signed((i + 1)*16#1000#, DATA_WIDTH)) &
                              std_logic_vector(to_signed(0, DATA_WIDTH));

            if i = 4 then
                s00_axis_tlast <= '1';  -- End of frame
            else
                s00_axis_tlast <= '0';
            end if;

            wait for CLK_PERIOD;
        end loop;

        -- Finish AXI Stream transfer
        s00_axis_tvalid <= '0';
        s00_axis_tlast  <= '0';

        -- Wait for processing latency in UUT
        wait for CLK_PERIOD * 10;

        -- Read back bins to check output rgb and magnitude
        for i in 0 to 4 loop
            bin_read_index_i <= to_unsigned(i * 8, BIN_INDEX_DEPTH);
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 5;

        -- Finish test
        test_done <= true;

        wait;
    end process;

end Behavioral;
