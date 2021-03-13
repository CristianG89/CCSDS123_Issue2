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

end package types_image;