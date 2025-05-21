----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
--
--  Modified by: Samuel Barton
----------------------------------------------------------------------------
--	Description: Clock divider with unbuffered output and starts on falling edge
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity clock_divider_unbuffered is
    Generic (CLK_DIV_RATIO : integer := 25_000_000);
    Port (  fast_clk_i : in STD_LOGIC;		  
            slow_clk_o : out STD_LOGIC); 
end clock_divider_unbuffered;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of clock_divider_unbuffered is

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant CLK_DIV_TC : integer := integer(CLK_DIV_RATIO/2);
constant CLK_COUNT_BITS : integer := integer(ceil(log2(real(CLK_DIV_TC))));
signal unbuffered_clk : std_logic := '1';
signal clock_counter : unsigned(CLK_COUNT_BITS-1 downto 0) := (others => '0');


----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Slow clock counter
slow_clock_counter : process(fast_clk_i)
begin
    if falling_edge (fast_clk_i) then
        if (clock_counter = CLK_DIV_TC-1) then 
            clock_counter <= (others => '0');   -- reset
        else
            clock_counter <= clock_counter + 1; -- increment
        end if;
    end if;
end process slow_clock_counter;

----------------------------------------------------------------------------
-- Slow clock toggle
slow_clock_ff : process(fast_clk_i)
begin
    if falling_edge (fast_clk_i) then
        if (clock_counter = CLK_DIV_TC-1) then 
            unbuffered_clk <= not unbuffered_clk;
        end if;
    end if;
end process slow_clock_ff;

----------------------------------------------------------------------------   
slow_clk_o <= unbuffered_clk;

end Behavioral;