----------------------------------------------------------------------------
-- 	ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Shift register with parallel load and serial output
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity shift_register_receiver is
    Generic ( DATA_WIDTH : integer := 16);
    Port (
        clk_i         : in std_logic;
        data_i        : in std_logic;
        shift_en_i    : in std_logic;

        data_o        : out std_logic_vector(DATA_WIDTH-1 downto 0));
end shift_register_receiver;
----------------------------------------------------------------------------
architecture Behavioral of shift_register_receiver is
    ----------------------------------------------------------------------------
    -- Define Constants and Signals
    ----------------------------------------------------------------------------
    -- ++++ Add internal signals here ++++
    signal shift_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- ++++ Describe the behavior using processes ++++
    ----------------------------------------------------------------------------     
begin
    data_o <= shift_reg;
    shift_reg_logic : process (clk_i, shift_en_i)
    begin
        if (rising_edge (clk_i)) then
            if (shift_en_i = '1') then       -- load takes priority
                shift_reg <= shift_reg(DATA_WIDTH-2 downto 0) & data_i;
            end if;
        end if;
    end process shift_reg_logic;
    ----------------------------------------------------------------------------   
end Behavioral;
