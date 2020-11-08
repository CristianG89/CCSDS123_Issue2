library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.param_image.all;

-- Package Declaration Section
package comp_gen is
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Adder module
	------------------------------------------------------------------------------------------------------------------------------	
	component adder is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			
			valid_i 	: in  std_logic;
			valid_o		: out std_logic;

			img_coord_i	: in  img_coord_t;
			img_coord_o	: out img_coord_t;
			
			data_s0_i	: in  std_logic_vector(D_C-1 downto 0);	-- "sz(t)" (original sample)
			data_s3_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
			data_res_o	: out std_logic_vector(D_C-1 downto 0)	-- "/\z(t)" (prediction residual)
		);
	end component adder;
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Shift Register module
	------------------------------------------------------------------------------------------------------------------------------
	component shift_register is
		generic (
			DATA_SIZE_G	: integer;
			REG_SIZE_G	: integer
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;

			valid_i		: in  std_logic;
			data_i		: in  unsigned(DATA_SIZE_G-1 downto 0);
			data_o		: out unsigned(DATA_SIZE_G-1 downto 0)
		);
	end component shift_register;

end package comp_gen;