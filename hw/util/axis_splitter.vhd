----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: AXI Stream FIFO Controller/Responder Interface
----------------------------------------------------------------------------
-- Library Declarations
library ieee;
use ieee.std_logic_1164.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_splitter is
	generic (
		DATA_WIDTH	: integer	:= 32
	);
	port (

		-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;


		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic;

		-- Ports of Axi Controller Bus Interface M01_AXIS
		m01_axis_aclk     : in std_logic;
		m01_axis_aresetn  : in std_logic;
		m01_axis_tvalid   : out std_logic;
		m01_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m01_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m01_axis_tlast    : out std_logic;
		m01_axis_tready   : in std_logic
	);
end axis_splitter;

-- Architecture Definition
architecture Behavioral of axis_splitter is

begin
s00_axis_tready <= m00_axis_tready and m01_axis_tready;

m00_axis_tdata <= s00_axis_tdata;
m01_axis_tdata <= s00_axis_tdata;

m00_axis_tvalid <= s00_axis_tvalid;
m01_axis_tvalid <= s00_axis_tvalid;

m00_axis_tlast <= s00_axis_tlast;
m01_axis_tlast <= s00_axis_tlast;

m00_axis_tstrb <= s00_axis_tstrb;
m01_axis_tstrb <= s00_axis_tstrb;

end Behavioral;
