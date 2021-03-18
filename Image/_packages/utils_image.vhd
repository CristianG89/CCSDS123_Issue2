library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_image.all;

-- Package Declaration Section
package utils_image is
	
	-- NOTE: IEEE library "math_real" cannot be used in the present design because
	-- it is not supported by Vivado, so many basic functions are here implemented.
	
	pure function max_int(max1_int : in integer; max2_int : in integer) return integer;
	pure function min_int(min1_int : in integer; min2_int : in integer) return integer;
	pure function max_sgn(max1_sgn : in signed; max2_sgn : in signed) return signed;
	pure function min_sgn(min1_sgn : in signed; min2_sgn : in signed) return signed;
	
	pure function iif(cond_in : in boolean; true_in : in std_logic; false_in : in std_logic) return std_logic;
	
	pure function reset_img_coord return img_coord_t;

end package utils_image;

-- Package Body Section
package body utils_image is

	-- Returns the bigger value from the two arguments (integer format)
	pure function max_int(max1_int : in integer; max2_int : in integer) return integer is
	begin
		if (max1_int > max2_int) then
			return max1_int;
		else
			return max2_int;
		end if;
	end function;

	-- Returns the smaller value from the two arguments (integer format)
	pure function min_int(min1_int : in integer; min2_int : in integer) return integer is
	begin
		if (min1_int < min2_int) then
			return min1_int;
		else
			return min2_int;
		end if;
	end function;
	
	-- Returns the bigger value from the two arguments (signed format)
	pure function max_sgn(max1_sgn : in signed; max2_sgn : in signed) return signed is
	begin
		if (max1_sgn > max2_sgn) then
			return max1_sgn;
		else
			return max2_sgn;
		end if;
	end function;

	-- Returns the smaller value from the two arguments (signed format)
	pure function min_sgn(min1_sgn : in signed; min2_sgn : in signed) return signed is
	begin
		if (min1_sgn < min2_sgn) then
			return min1_sgn;
		else
			return min2_sgn;
		end if;
	end function;
	
	-- Immediate IF (iif) function for "std_logic" values
	pure function iif(cond_in : in boolean; true_in : in std_logic; false_in : in std_logic) return std_logic is
	begin
		if (cond_in = true) then
			return true_in;
		else
			return false_in;
		end if;
	end function;

	-- Resets the image coordinates record
	pure function reset_img_coord return img_coord_t is
		variable img_coord_v : img_coord_t;
	begin
		img_coord_v.x := 0;
		img_coord_v.y := 0;
		img_coord_v.z := 0;
		img_coord_v.t := 0;

		return img_coord_v;
	end function;

end package body utils_image;