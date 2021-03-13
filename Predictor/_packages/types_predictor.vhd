library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;

-- Package Declaration Section
package types_predictor is

	-- Record for the image coordinates
	type img_coord_t is record
		x : integer range 0 to NX_C-1;
		y : integer range 0 to NY_C-1;
		z : integer range 0 to NZ_C-1;
		t : integer range 0 to NX_C*NY_C-1;
	end record img_coord_t;	
	
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
	
	-- Arrays of primitive types
	type array_signed_t is array(natural range <>) of signed;
	type array_unsigned_t is array(natural range <>) of unsigned;
	-- Arrays record types
	type img_coord_ar_t is array(natural range <>) of img_coord_t;
	type s2_pos_ar_t is array(natural range <>) of s2_pos_t;
	
	-- Matrix of primitive types
	type matrix_signed_t is array(natural range <>) of array_signed_t;
	type matrix_unsigned_t is array(natural range <>) of array_unsigned_t;

end package types_predictor;