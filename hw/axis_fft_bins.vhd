----------------------------------------------------------------------------
--  Final Project
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Samuel Barton
----------------------------------------------------------------------------
--	Description: Bins RAM from FFT
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fft_bins is
    Generic (
        FIFO_DEPTH : integer := 1024;
        DATA_WIDTH : integer := 24;
        FFT_DEPTH : integer := 256);
    Port (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		ram_filled_o        : out std_logic;

end axis_fft_bins;

----------------------------------------------------------------------------
-- Architecture Definition
architecture Behavioral of axis_fft_bins is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------
type ram_t is array(0 to FFT_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal bins_ram : ram_t := (others => (others => '0'));
signal write_pointer : integer := ;

----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------
----------------------------------------------------------------------------

begin
----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------
write_pointer : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        if s00_axis_tlast = '1' then
            write_pointer <= 0;
        elsif s00_axis_tvalid = '1' then
            write_pointer <= write_pointer + 1;
        end if;
    end if;
end process write_pointer;

write_bin : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        if s00_axis_tvalid = '1' then
            bins_ram(write_pointer) <= s00_axis_tdata(DATA_WIDTH-1 downto 0);
        end if;
    end if;
end process write_bin;

bins_filled_logic : process(s00_axis_tlast)
    ram_filled_o <= '0';
    if s00_axis_tlast = '1' then
        ram_filled_o <= '1';
    end if;
end process bins_filled_logic;


end Behavioral;
