library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_hdmi_controller is
end entity tb_hdmi_controller;

architecture behavioral of tb_hdmi_controller is

    constant CLOCK_PERIOD : time := 13.5 ns; -- 74.25 MHz clock
    constant BIN_INDEX_WIDTH : integer := 6;

    constant ACTIVE_PIX : integer := 1280;
    constant FRONT_PORCH_PIX : integer := 110;
    constant HSYNC_PIX : integer := 40;
    constant BACK_PORCH_PIX : integer := 220;
    
    component hdmi_controller is
        Generic (
            NUMBER_BINS : integer := 64;
            BIN_INDEX_WIDTH : integer := 6
        );
        Port (
            pixel_clk_i     : in std_logic;
            hsync_i         : in std_logic;
            video_active_i  : in std_logic;
    
            bin_index_o     : out unsigned(BIN_INDEX_WIDTH-1 downto 0)
        );
    end component;
    
    signal pixel_clk : std_logic := '0';
    signal hsync : std_logic := '1';
    signal video_active : std_logic := '0';
    
    signal bin_index : unsigned(BIN_INDEX_WIDTH-1 downto 0);
    
    begin
    
    uut: hdmi_controller
        Port Map(
            pixel_clk_i => pixel_clk,
            hsync_i => hsync,
            video_active_i => video_active,
            bin_index_o => bin_index
        );

    clock_process : process
    begin
        pixel_clk <= '0';
        wait for CLOCK_PERIOD/2;
        pixel_clk <= '1';
        wait for CLOCK_PERIOD/2;
    end process clock_process;
    
    stim_proc: process
    begin
        loop
            video_active <= '1';
            for i in 0 to ACTIVE_PIX-1 loop
                wait for CLOCK_PERIOD;
            end loop;
            video_active <= '0';
            for i in 0 to FRONT_PORCH_PIX-1 loop
                wait for CLOCK_PERIOD;
            end loop;
            hsync <= '1';
            for i in 0 to HSYNC_PIX-1 loop
                wait for CLOCK_PERIOD;
            end loop;
            hsync <= '0';
            for i in 0 to BACK_PORCH_PIX-1 loop
                wait for CLOCK_PERIOD;
            end loop;
        end loop;
    end process stim_proc;
    
end behavioral;
