library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity prediction is
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "s''z(t)" (sample representative)
		s_valid_s2z_i	: in  std_logic;
		s_ready_s2z_o	: out std_logic;
		s_data_s2z_i	: in  image_t;
		
		-- Master interface for signal "s^z(t)" (predicted sample)
		m_valid_s3z_o	: out std_logic;
		m_ready_s3z_i	: in  std_logic;
		m_data_s3z_o	: out image_t
	);
end prediction;

architecture behavioural of prediction is
begin

end behavioural;