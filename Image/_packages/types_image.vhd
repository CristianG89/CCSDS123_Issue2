library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;

-- Package Declaration Section
package types_image is

	-- Record for the image coordinates
	type img_coord_t is record
		x : integer range 0 to NX_C-1;
		y : integer range 0 to NY_C-1;
		z : integer range 0 to NZ_C-1;
		t : integer range 0 to NX_C*NY_C-1;
	end record img_coord_t;
	
	-- Record for the sample value limits
	type smpl_lim_t is record
		min : integer;
		mid : integer;
		max : integer;
	end record smpl_lim_t;

	-- Arrays of primitive types
	type array_integer_t is array(natural range <>) of integer;
	type array_signed_t is array(natural range <>) of signed;
	type array_unsigned_t is array(natural range <>) of unsigned;
	type array_slv_t is array(natural range <>) of std_logic_vector;
	type array_string_t is array(natural range <>) of string;
	-- Arrays record types
	type img_coord_ar_t is array(natural range <>) of img_coord_t;
	
	-- Matrix of primitive types
	type matrix_signed_t is array(natural range <>) of array_signed_t;
	type matrix_unsigned_t is array(natural range <>) of array_unsigned_t;

end package types_image;