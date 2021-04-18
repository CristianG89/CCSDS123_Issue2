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
	
	component smpl_adap_gpo2_code is
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
	end component smpl_adap_gpo2_code;

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

	------------------------------------------------------------------------------------------------------------------------------
	-- Sample Adaptive Entropy Coder (top) module
	------------------------------------------------------------------------------------------------------------------------------
	component hybrid_wrapper is
		port(
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)" (mapped quantizer index)		
			rvd_codeword_o	: out unsigned(Umax_C+D_C-1 downto 0)	-- "R'k(j)" (reversed codeword)
		);
	end component hybrid_wrapper;
	
	component hybrid_low_entr_code is
		port(
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)"  (mapped quantizer index)
			high_res_accu_i	: in  integer;							-- "Σ~z(t)" (high resolution accumulator)
			counter_i		: in  integer;							-- "Γ(t)"   (counter)
			
			rvd_codeword_o	: out unsigned(Umax_C+D_C-1 downto 0)	-- "R'k(j)" (reversed codeword)
		);
	end component hybrid_low_entr_code;
	
	component hybrid_high_entr_code is
		port(
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)"  (mapped quantizer index)
			high_res_accu_i	: in  integer;							-- "Σ~z(t)" (high resolution accumulator)
			counter_i		: in  integer;							-- "Γ(t)"   (counter)
			
			rvd_codeword_o	: out unsigned(Umax_C+D_C-1 downto 0)	-- "R'k(j)" (reversed codeword)
		);
	end component hybrid_high_entr_code;
	
	component hybrid_statistic is
		port(
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_mp_quan_i	: in  unsigned(D_C-1 downto 0);		-- "?z(t)" (mapped quantizer index)
			
			high_res_accu_o	: out integer;						-- High resolution accumulator Σ~z(t)
			counter_o		: out integer;						-- Counter Γ(t)
			entropy_select_o: out std_logic						-- Selected Entropy method (1=high-entropy, 0=low-entropy)
		);
	end component hybrid_statistic;
	
end package comp_encoder;