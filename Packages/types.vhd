library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;

-- Package Declaration Section
package types is

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
	
	-- Different arrays of primitive types
	type array_int_t is array(natural range <>) of integer;
	type array_real_t is array(natural range <>) of real;
	type array_signed_t is array(natural range <>) of signed;
	type array_unsigned_t is array(natural range <>) of unsigned;
	-- Array for the image coordinates
	type img_coord_ar_t is array(natural range <>) of img_coord_t;

end package types;