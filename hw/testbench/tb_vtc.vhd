library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_vtc is
end entity tb_vtc;

architecture behavioral of tb_vtc is

    constant CLOCK_PERIOD : time := 13.5 ns; -- 74.25 MHz clock
    constant BIN_INDEX_WIDTH : integer := 6;

    constant H_ACTIVE_PIX : integer := 1280;
    constant H_FRONT_PORCH_PIX : integer := 110;
    constant HSYNC_PIX : integer := 40;
    constant H_BACK_PORCH_PIX : integer := 220;
    constant H_TOTAL_PIX : integer := 1650;

    constant V_ACTIVE_PIX : integer := 720;
    constant V_FRONT_PORCH_PIX : integer := 5;
    constant VSYNC_PIX : integer := 5;
    constant V_BACK_PORCH_PIX : integer := 20;
    
    
    signal pixel_clk : std_logic := '0';
    signal hsync,vsync : std_logic := '0';
    signal video_active : std_logic := '0';
        
    begin
    
    pixel_clock_process : process
    begin
        pixel_clk <= '0';
        wait for CLOCK_PERIOD/2;
        pixel_clk <= '1';
        wait for CLOCK_PERIOD/2;
    end process pixel_clock_process;
    
    vtc_proc: process
    begin
        loop
            -- vertical back porch
            for j in 0 to V_BACK_PORCH_PIX-1 loop
                  for i in 0 to H_BACK_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  --video_active <= '1';
                  for i in 0 to H_ACTIVE_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  --video_active <= '0';
                  for i in 0 to H_FRONT_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '1';
                  for i in 0 to HSYNC_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '0';
            end loop;
            -- active vertical
            for j in 0 to V_ACTIVE_PIX-1 loop
                  for i in 0 to H_BACK_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  video_active <= '1';
                  for i in 0 to H_ACTIVE_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  video_active <= '0';
                  for i in 0 to H_FRONT_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '1';
                  for i in 0 to HSYNC_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '0';
            end loop;
            -- vertical front porch
            for j in 0 to V_BACK_PORCH_PIX-1 loop
                  for i in 0 to H_BACK_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  --video_active <= '1';
                  for i in 0 to H_ACTIVE_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  --video_active <= '0';
                  for i in 0 to H_FRONT_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '1';
                  for i in 0 to HSYNC_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '0';
            end loop;
            -- vertical sync
            vsync <= '1';
            for j in 0 to V_BACK_PORCH_PIX-1 loop
                  for i in 0 to H_BACK_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  --video_active <= '1';
                  for i in 0 to H_ACTIVE_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  --video_active <= '0';
                  for i in 0 to H_FRONT_PORCH_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '1';
                  for i in 0 to HSYNC_PIX-1 loop
                      wait for CLOCK_PERIOD;
                  end loop;
                  hsync <= '0';
            end loop;
            vsync <= '0';
        end loop;
    end process vtc_proc;

end behavioral;
