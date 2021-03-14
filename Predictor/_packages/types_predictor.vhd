library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;

-- Package Declaration Section
package types_predictor is
	
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

end package types_predictor;