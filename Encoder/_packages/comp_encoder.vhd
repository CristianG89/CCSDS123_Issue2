library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;

-- Package Declaration Section
package comp_encoder is

	------------------------------------------------------------------------------------------------------------------------------
	-- Sample Adaptive Entropy Coder (top) module
	------------------------------------------------------------------------------------------------------------------------------
	component smpl_adap_wrapper is
		port (
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)" (mapped quantizer index)		
			codeword_o		: out unsigned(Umax_C+D_C-1 downto 0)	-- "Rk(j)" (codeword)
		);
	end component smpl_adap_wrapper;
	
	component smpl_adap_coding is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);		-- "?z(t)" (mapped quantizer index)
		accu_i			: in  integer;						-- "Σz(t)" (accumulator)
		counter_i		: in  integer;						-- "Γ(t)"  (counter)
		
		codeword_o		: out unsigned(Umax_C+D_C-1 downto 0) -- "Rk(j)" (codeword)
	);
	end component smpl_adap_coding;

	component smpl_adap_statistic is
		port (
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_mp_quan_i	: in  unsigned(D_C-1 downto 0);		-- "?z(t)" (mapped quantizer index)
			accu_o			: out integer;						-- Accumulator Σz(t)
			counter_o		: out integer						-- Counter Γ(t)
		);
	end component smpl_adap_statistic;

end package comp_encoder;