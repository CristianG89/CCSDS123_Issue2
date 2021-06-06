library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;

use work.param_predictor.all;

-- Package Declaration Section
package types_predictor is
	
	-- Record for the absolute/relative error limit values
	type err_lim_t is record
		abs_c	: integer range 0 to (2**DA_C-1);
		abs_arr : array_integer_t(0 to NZ_C-1);
		rel_c	: integer range 0 to (2**DR_C-1);
		rel_arr : array_integer_t(0 to NZ_C-1);
	end record err_lim_t;
	
	type s2_pos_t is record
		cur : signed(D_C-1 downto 0);
		w	: signed(D_C-1 downto 0);
		wz	: signed(D_C-1 downto 0);
		n	: signed(D_C-1 downto 0);
		nw	: signed(D_C-1 downto 0);
		ne	: signed(D_C-1 downto 0);
	end record s2_pos_t;

	type ldiff_pos_t is record
		c	: signed(D_C-1 downto 0);
		n	: signed(D_C-1 downto 0);
		w	: signed(D_C-1 downto 0);
		nw	: signed(D_C-1 downto 0);
	end record ldiff_pos_t;

	-- Arrays record types
	type s2_pos_ar_t is array(natural range <>) of s2_pos_t;
	type err_lim_ar_t is array(natural range <>) of err_lim_t;

end package types_predictor;