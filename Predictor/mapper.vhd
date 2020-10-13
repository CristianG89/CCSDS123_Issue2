library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity mapper is
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "qz(t)" (quantizer index)
		s_valid_qz_i	: in  std_logic;
		s_ready_qz_o	: out std_logic;
		s_data_qz_i		: in  image_t;
		
		-- Slave interface for signal "s^z(t)" (predicted sample)
		s_valid_s3z_i	: in  std_logic;
		s_ready_s3z_o	: out std_logic;
		s_data_s3z_i	: in  image_t;

		-- Slave interface for signal "mz(t)" (maximum error)
		s_valid_mz_i	: in  std_logic;
		s_ready_mz_o	: out std_logic;
		s_data_mz_i		: in  image_t;
		
		-- Master (output) interface for signal "dz(t)" (mapped quantizer index)
		m_valid_dz_o	: out std_logic;
		m_ready_dz_i	: in  std_logic;
		m_data_dz_o		: out image_t
	);
end mapper;

architecture behavioural of mapper is
begin

end behavioural;