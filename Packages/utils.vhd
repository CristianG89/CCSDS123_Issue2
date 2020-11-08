library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

-- Package Declaration Section
package utils is
	
	-- NOTE: IEEE library "math_real" cannot be used in the present design because
	-- it is not supported by Vivado, so many basic functions are here implemented.
	
	pure function max(int1_in : in integer; int2_in : in integer) return integer;
	pure function min(int1_in : in integer; int2_in : in integer) return integer;
	pure function pointer_inc(int_in : in integer; max_in : in integer) return integer;
	pure function abs_int(int_in : in integer) return integer;
	
	pure function round_down(real_in : in real) return integer;
	pure function round_up(real_in : in real) return integer;
	
	pure function modulus(int1_in : in integer; int2_in : in integer) return integer;
	pure function mod_R(int1_in : in integer; pos1_in : in positive) return integer;
	
	pure function sgn(int_in : in integer) return integer;
	pure function sgnp(int_in : in integer) return integer;
	
	pure function clip(int_in : in integer; int_min_in : in integer; int_max_in : in integer) return integer;

	pure function vector_product(arr1_in : in array_unsigned_t; arr2_in : in array_unsigned_t) return unsigned;
	
	pure function reset_img_coord return img_coord_t;

end package utils;

-- Package Body Section
package body utils is

	-- Returns the bigger value from the two arguments
	pure function max(int1_in : in integer; int2_in : in integer) return integer is
	begin
		if (int1_in > int2_in) then
			return int1_in;
		else
			return int2_in;
		end if;
	end function;

	-- Returns the smaller value from the two arguments
	pure function min(int1_in : in integer; int2_in : in integer) return integer is
	begin
		if (int1_in < int2_in) then
			return int1_in;
		else
			return int2_in;
		end if;
	end function;

	-- Increases a value, or sets it to 0 if reaches maximum value
	pure function pointer_inc(int_in : in integer; max_in : in integer) return integer is
	begin
		if (int_in + 1 > max_in) then
			return 0;
		else
			return int_in + 1;
		end if;
	end pointer_inc;

	-- Returns the absolute value
	pure function abs_int(int_in : in integer) return integer is
	begin
		if (int_in < 0) then
			return -int_in;
		else
			return int_in;
		end if;		
	end function;

	-- Transforms incoming real value into integer (removing the decimal part) to round down
	pure function round_down(real_in : in real) return integer is
	begin
		return integer(real_in);
	end function;
	
	-- Transforms incoming real value into integer (removing the decimal part) and adds it 1 to round up
	pure function round_up(real_in : in real) return integer is
	begin
		return (integer(real_in) + 1);
	end function;
	
	-- Modulus (remainder) function
	pure function modulus(int1_in : in integer; int2_in : in integer) return integer is
	begin
		return (int1_in - int2_in*round_down(real(int1_in)/real(int2_in)));
	end function;
	
	-- Modulus*R function
	pure function mod_R(int1_in : in integer; pos1_in : in positive) return integer is	
		variable power_v  : integer := 2 ** (pos1_in - 1);
		variable modulus_v : integer;
	begin
		modulus_v := modulus((int1_in+power_v), 2**pos1_in);
	
		return (modulus_v - power_v);
	end function;
	
	-- Sign function
	pure function sgn(int_in : in integer) return integer is
	begin
		if (int_in > 0) then
			return 1;
		elsif (int_in = 0) then
			return 0;
		else
			return -1;
		end if;
	end function;
	
	-- Sign plus function
	pure function sgnp(int_in : in integer) return integer is
	begin
		if (int_in >= 0) then
			return 1;
		else
			return -1;
		end if;
	end function;
	
	-- Clipping function
	pure function clip(int_in : in integer; int_min_in : in integer; int_max_in : in integer) return integer is
	begin
		if (int_in < int_min_in) then
			return int_min_in;
		elsif (int_in > int_max_in) then
			return int_max_in;
		else
			return int_in;
		end if;
	end function;
	
	-- Vector inner product function
	pure function vector_product(arr1_in : in array_unsigned_t; arr2_in : in array_unsigned_t) return unsigned is
		variable product_v	: integer := 0;
		variable out_v		: unsigned(arr1_in(0)'length-1 downto 0);
	begin
		for i in 0 to (arr1_in'length-1) loop
			product_v := product_v + to_integer(arr1_in(i)*arr2_in(i));
		end loop;
		out_v := to_unsigned(product_v, arr1_in(0)'length);

		return out_v;
	end function;
	
	-- Returns an image coordinates record set to 0
	pure function reset_img_coord return img_coord_t is
		variable img_coord_v : img_coord_t;
	begin
		img_coord_v.x := 0;
		img_coord_v.y := 0;
		img_coord_v.z := 0;
		img_coord_v.t := 0;

		return img_coord_v;
	end function;
	
end package body utils;