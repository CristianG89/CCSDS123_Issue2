library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity weights is
	generic (
		PREDICTION_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clk_i		 : in  std_logic;
		rst_i		 : in  std_logic;
		
		-- Master interface for "Wz(t)" (weight vector)
		m_valid_wz_o : out std_logic;
		m_ready_wz_i : in  std_logic;
		m_data_wz_o	 : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0)
	);
end weights;

architecture behavioural of weights is
begin

	g_prediction_mode : if (PREDICTION_MODE_G = "1") generate	-- Full prediction mode
		
	else generate	-- Reduced prediction mode
		
	end generate g_prediction_mode;
	
end behavioural;