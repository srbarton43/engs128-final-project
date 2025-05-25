
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: FIFO buffer
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity fifo is
    Generic (
        FIFO_DEPTH : integer := 1024;
        DATA_WIDTH : integer := 32);
    Port (
        clk_i       : in std_logic;
        reset_i     : in std_logic;

        -- Write channel
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Read channel
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Status flags
        empty_o         : out std_logic;
        full_o          : out std_logic);
end fifo;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of fifo is
    ----------------------------------------------------------------------------
    -- Define Constants and Signals
    ----------------------------------------------------------------------------
    type mem_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_buf : mem_type := (others => (others => '0'));

    -- counters
    signal read_pointer, write_pointer : integer range 0 to FIFO_DEPTH-1 := 0;
    --signal prev_data_count, data_count : integer range 0 to FIFO_DEPTH-1 := 0;
    signal data_count : integer range 0 to FIFO_DEPTH := 0;

    signal full_sig : std_logic := '0';
    signal empty_sig : std_logic := '0';

    signal read_and_write_sig : std_logic := '0';
    ----------------------------------------------------------------------------
begin
    ----------------------------------------------------------------------------
    -- Processes and Logic
    ----------------------------------------------------------------------------

    read_counter_logic : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                read_pointer <= 0;
            elsif rd_en_i = '1' and empty_sig = '0' then
                if read_pointer = FIFO_DEPTH - 1 then
                    read_pointer <= 0;
                else
                    read_pointer <= read_pointer + 1;
                end if;
            end if;
        end if;
    end process read_counter_logic;

    write_counter_logic : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                write_pointer <= 0;
            elsif wr_en_i = '1' and full_sig = '0' then
                if write_pointer = FIFO_DEPTH - 1 then
                    write_pointer <= 0;
                else
                    write_pointer <= write_pointer + 1;
                end if;
            end if;
        end if;
    end process write_counter_logic;

    data_count_logic : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                data_count <= 0;
            elsif wr_en_i = '0' or rd_en_i = '0' then
                if wr_en_i = '1' and full_sig = '0' then
                    data_count <= data_count + 1;
                elsif rd_en_i = '1' and empty_sig = '0' then
                    data_count <= data_count - 1;
                end if;
            end if;
        end if;
    end process data_count_logic;

    full_logic : process(data_count)
    begin
        full_sig <= '0';
        if data_count = FIFO_DEPTH then
            full_sig <= '1';
        end if;
    end process full_logic;

    empty_logic : process(data_count, read_and_write_sig)
    begin
        empty_sig <= '0';
        if data_count = 0 then
            empty_sig <= '1';
        end if;

        if data_count = 0 and read_and_write_sig = '1' then
            empty_sig <= '1';
        end if;
    end process empty_logic;

    fifo_buf_readwrite_logic : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if wr_en_i = '1' and full_sig = '0' then
                fifo_buf(write_pointer) <= wr_data_i;
            end if;
        end if;
    end process fifo_buf_readwrite_logic;

    output_logic : process(full_sig, empty_sig, fifo_buf, read_pointer)
    begin
        full_o <= full_sig;
        empty_o <= empty_sig;
        rd_data_o <= fifo_buf(read_pointer);
    end process output_logic;

end Behavioral;
