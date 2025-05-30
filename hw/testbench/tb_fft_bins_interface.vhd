library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity axis_fft_bins_interface_tb is
end axis_fft_bins_interface_tb;

architecture Behavioral of axis_fft_bins_interface_tb is

    -- Constants
    constant DATA_WIDTH : integer := 24;
    constant FFT_DEPTH : integer := 64;
    constant BIN_INDEX_DEPTH : integer := 6;
    constant RGB_WIDTH : integer := 24;
    constant CLK_PERIOD : time := 10 ns;

    -- Component declaration
    component axis_fft_bins_interface is
        Generic (
            DATA_WIDTH : integer := 24;
            FFT_DEPTH : integer := 64;
            BIN_INDEX_DEPTH : integer := 6);
        Port (
            s00_axis_aclk     : in std_logic;
            s00_axis_tdata    : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
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

    -- Signals
    signal s00_axis_aclk     : std_logic := '0';
    signal s00_axis_tdata    : std_logic_vector(DATA_WIDTH*2-1 downto 0) := (others => '0');
    signal s00_axis_tlast    : std_logic := '0';
    signal s00_axis_tuser    : unsigned(BIN_INDEX_DEPTH-1 downto 0) := (others => '0');
    signal s00_axis_tvalid   : std_logic := '0';
    signal vsync_i           : std_logic := '0';
    signal bin_read_index_i  : unsigned(BIN_INDEX_DEPTH-1 downto 0) := (others => '0');
    signal rgb_value_o       : std_logic_vector(RGB_WIDTH-1 downto 0);
    signal dbg_tuser_o       : unsigned(BIN_INDEX_DEPTH-1 downto 0);
    signal dbg_magnitude_o   : unsigned(DATA_WIDTH-1 downto 0);

    signal testbench_magnitude_i : unsigned(DATA_WIDTH-1 downto 0);
    signal testbench_rgb_o : std_logic_vector(RGB_WIDTH-1 downto 0);

    -- Test signals
    signal sim_done : boolean := false;

    -- Function to create interesting patterns
    function create_pattern(bin_index: integer; pattern_type: integer) return integer is
        variable result : integer;
        variable max_value : integer := 8000;  -- Maximum magnitude value
    begin
        case pattern_type is
            when 0 =>  -- Peaks at specific frequencies
                if (bin_index = 5) or (bin_index = 20) or (bin_index = 40) or (bin_index = 60) then
                    result := max_value;
                elsif (bin_index = 6) or (bin_index = 19) or (bin_index = 41) or (bin_index = 59) then
                    result := max_value * 3/4;
                elsif (bin_index = 7) or (bin_index = 18) or (bin_index = 42) or (bin_index = 58) then
                    result := max_value * 1/2;
                else
                    result := max_value * 1/10 + (bin_index * 20);
                end if;

            when 1 =>  -- Ascending pattern with dips
                result := bin_index * max_value / FFT_DEPTH;
                if (bin_index mod 8 = 0) then
                    result := result / 4;
                end if;

            when 2 =>  -- Sinusoidal pattern with multiple frequencies
                result := integer(
                    real(max_value/3) * sin(real(bin_index) * MATH_PI / 8.0) +
                    real(max_value/3) * sin(real(bin_index) * MATH_PI / 4.0) +
                    real(max_value/3)
                );

            when 3 =>  -- Exponential decay with resonant peaks
                result := integer(real(max_value) * exp(-real(bin_index) / 20.0));
                if (bin_index = 10) or (bin_index = 30) or (bin_index = 50) then
                    result := max_value * 3/4;
                end if;

            when others =>  -- Random-like pattern
                result := (bin_index * 123) mod max_value;
                if result < 0 then
                    result := -result;
                end if;
        end case;

        -- Ensure non-negative result
        if result < 0 then
            result := 0;
        end if;

        return result;
    end function;
begin

    -- DUT instantiation
    DUT: axis_fft_bins_interface
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            FFT_DEPTH => FFT_DEPTH,
            BIN_INDEX_DEPTH => BIN_INDEX_DEPTH
        )
        port map (
            s00_axis_aclk => s00_axis_aclk,
            s00_axis_tdata => s00_axis_tdata,
            s00_axis_tlast => s00_axis_tlast,
            s00_axis_tuser => s00_axis_tuser,
            s00_axis_tvalid => s00_axis_tvalid,
            vsync_i => vsync_i,
            bin_read_index_i => bin_read_index_i,
            rgb_value_o => rgb_value_o,
            dbg_tuser_o => dbg_tuser_o,
            dbg_magnitude_o => dbg_magnitude_o
        );

    -- Clock generation
    clk_process: process
    begin
        while not sim_done loop
            s00_axis_aclk <= '0';
            wait for CLK_PERIOD/2;
            s00_axis_aclk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
        variable magnitude, real_part, imag_part : integer;
        variable phase : real;
    begin
        -- Initialize signals
        s00_axis_tvalid <= '0';
        s00_axis_tlast <= '0';
        s00_axis_tuser <= (others => '0');
        s00_axis_tdata <= (others => '0');
        vsync_i <= '0';
        bin_read_index_i <= (others => '0');

        wait for CLK_PERIOD * 5;

        -- Test 1: Write data to the first RAM with pattern 0
        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s00_axis_aclk);

            -- Generate interesting magnitude pattern
            magnitude := create_pattern(i, 0);

            -- Create a random phase for each bin
            phase := real(i) * MATH_PI / 16.0;

            -- Convert magnitude and phase to real and imaginary components
            real_part := integer(real(magnitude) * cos(phase));
            imag_part := integer(real(magnitude) * sin(phase));

            -- Set the tdata with our calculated values
            s00_axis_tdata(DATA_WIDTH-1 downto 0) <= std_logic_vector(to_signed(real_part, DATA_WIDTH));
            s00_axis_tdata(2*DATA_WIDTH-1 downto DATA_WIDTH) <= std_logic_vector(to_signed(imag_part, DATA_WIDTH));

            s00_axis_tuser <= to_unsigned(i, BIN_INDEX_DEPTH);
            s00_axis_tvalid <= '1';

            if i = FFT_DEPTH-1 then
                s00_axis_tlast <= '1';
            else
                s00_axis_tlast <= '0';
            end if;
        end loop;

        wait until rising_edge(s00_axis_aclk);
        s00_axis_tvalid <= '0';
        s00_axis_tlast <= '0';

        -- Read back data from the first RAM
        wait for CLK_PERIOD * 5;

        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s00_axis_aclk);
            bin_read_index_i <= to_unsigned(i, BIN_INDEX_DEPTH);
            wait for CLK_PERIOD;
            -- Here we could add checks or report statements to verify output
--            report "Bin " & integer'image(i) & " - Magnitude: " &
--                   integer'image(to_integer(dbg_magnitude_o)) &
--                   " RGB: " & to_hstring(rgb_value_o);
        end loop;

        -- Test 2: Trigger vsync to switch to the second RAM
        wait until rising_edge(s00_axis_aclk);
        vsync_i <= '1';
        wait until rising_edge(s00_axis_aclk);
        vsync_i <= '0';

        wait for CLK_PERIOD * 5;

        -- Write data to the second RAM with pattern 2
        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s00_axis_aclk);

            -- Generate different interesting magnitude pattern
            magnitude := create_pattern(i, 2);

            -- Create a different phase pattern
            phase := real(i) * MATH_PI / 8.0;

            -- Convert magnitude and phase to real and imaginary components
            real_part := integer(real(magnitude) * cos(phase));
            imag_part := integer(real(magnitude) * sin(phase));

            -- Set the tdata with our calculated values
            s00_axis_tdata(DATA_WIDTH-1 downto 0) <= std_logic_vector(to_signed(real_part, DATA_WIDTH));
            s00_axis_tdata(2*DATA_WIDTH-1 downto DATA_WIDTH) <= std_logic_vector(to_signed(imag_part, DATA_WIDTH));

            s00_axis_tuser <= to_unsigned(i, BIN_INDEX_DEPTH);
            s00_axis_tvalid <= '1';

            if i = FFT_DEPTH-1 then
                s00_axis_tlast <= '1';
            else
                s00_axis_tlast <= '0';
            end if;
        end loop;

        wait until rising_edge(s00_axis_aclk);
        s00_axis_tvalid <= '0';
        s00_axis_tlast <= '0';

        -- Read back data from the second RAM
        wait for CLK_PERIOD * 5;

        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s00_axis_aclk);
            bin_read_index_i <= to_unsigned(i, BIN_INDEX_DEPTH);
            wait for CLK_PERIOD;
--            report "Bin " & integer'image(i) & " - Magnitude: " &
--                   integer'image(to_integer(dbg_magnitude_o)) &
--                   " RGB: " & to_hstring(rgb_value_o);
        end loop;

        -- Test 3: Test vsync switching back to the first RAM
        wait until rising_edge(s00_axis_aclk);
        vsync_i <= '1';
        wait until rising_edge(s00_axis_aclk);
        vsync_i <= '0';

        wait for CLK_PERIOD * 5;

        -- Test 4: Write a third pattern to the first RAM (now active again)
        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s00_axis_aclk);

            -- Generate a third interesting magnitude pattern
            magnitude := create_pattern(i, 3);

            -- Create a different phase pattern
            phase := real(i) * MATH_PI / 12.0;

            -- Convert magnitude and phase to real and imaginary components
            real_part := integer(real(magnitude) * cos(phase));
            imag_part := integer(real(magnitude) * sin(phase));

            -- Set the tdata with our calculated values
            s00_axis_tdata(DATA_WIDTH-1 downto 0) <= std_logic_vector(to_signed(real_part, DATA_WIDTH));
            s00_axis_tdata(2*DATA_WIDTH-1 downto DATA_WIDTH) <= std_logic_vector(to_signed(imag_part, DATA_WIDTH));

            s00_axis_tuser <= to_unsigned(i, BIN_INDEX_DEPTH);
            s00_axis_tvalid <= '1';

            if i = FFT_DEPTH-1 then
                s00_axis_tlast <= '1';
            else
                s00_axis_tlast <= '0';
            end if;
        end loop;

        wait until rising_edge(s00_axis_aclk);
        s00_axis_tvalid <= '0';
        s00_axis_tlast <= '0';

        -- Read from the first RAM again
        wait for CLK_PERIOD * 5;

        for i in 0 to FFT_DEPTH-1 loop
            wait until rising_edge(s00_axis_aclk);
            bin_read_index_i <= to_unsigned(i, BIN_INDEX_DEPTH);
            wait for CLK_PERIOD;
--            report "Bin " & integer'image(i) & " - Magnitude: " &
--                   integer'image(to_integer(dbg_magnitude_o)) &
--                   " RGB: " & to_hstring(rgb_value_o);
        end loop;

        -- End simulation
        wait for CLK_PERIOD * 10;
        sim_done <= true;
        report "Simulation complete";
        wait;
    end process;

    rgb_calc_proc : process(testbench_magnitude_i)
    begin

    end process rgb_calc_proc;

    magnitude_calc_proc: process(s00_axis_tvalid, s00_axis_tdata)
        variable re_signed : signed(23 downto 0);
        variable im_signed : signed(23 downto 0);
        variable re_abs : unsigned(23 downto 0);
        variable im_abs : unsigned(23 downto 0);
        variable re_sq : unsigned(47 downto 0);
        variable im_sq : unsigned(47 downto 0);
        variable mag_sq : unsigned(48 downto 0);
        variable magnitude_temp : unsigned(24 downto 0);
    begin
        testbench_magnitude_i <= (others => '0');

        if s00_axis_tvalid = '1' then
            -- Extract real and imaginary parts (signed format)
            re_signed := signed(s00_axis_tdata(23 downto 0));
            im_signed := signed(s00_axis_tdata(47 downto 24));

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

            -- For spectral analysis, you often want magnitude, not magnitude squared
            -- This is a simple approximation: mag ≈ sqrt(re² + im²)
            -- For FPGA, we can use: mag ≈ max(|re|, |im|) + 0.5 * min(|re|, |im|)
            -- This gives about 4% error but is much simpler than sqrt

            if re_abs >= im_abs then
                magnitude_temp := ('0' & re_abs) + ('0' & im_abs(23 downto 1)); -- re + im/2
            else
                magnitude_temp := ('0' & im_abs) + ('0' & re_abs(23 downto 1)); -- im + re/2
            end if;

            testbench_magnitude_i <= magnitude_temp(23 downto 0);

        end if;
    end process;

end Behavioral;
