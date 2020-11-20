library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

-- Package Declaration Section
package utils is
	
	-- NOTE: IEEE library "math_real" cannot be used in the present design because
	-- it is not supported by Vivado, so many basic functions are here implemented.
	
	pure function max(max1_int : in integer; max2_int : in integer) return integer;
	pure function min(min1_int : in integer; min2_int : in integer) return integer;
	
	pure function round_down(down_sgd : in signed) return signed;
	pure function round_up(up_sgd : in signed) return signed;
	
	pure function modulus(mod1_sgd : in signed; mod2_sgd : in signed) return signed;
	pure function mod_R(modR_sgd : in signed; R_int : in integer) return signed;

	pure function sgn(sgn_int : in integer) return integer;
	pure function sgnp(sgnp_int : in integer) return integer;
	
	pure function clip(clip_sgd : in signed; clip_min_sgd : in signed; clip_max_sgd : in signed) return signed;

	pure function vector_product(arr1_sgd : in array_signed_t; arr2_sgd : in array_signed_t) return signed;
	pure function vector_product(arr1_usgd : in array_unsigned_t; arr2_usgd : in array_unsigned_t) return unsigned;
	
	pure function reset_img_coord return img_coord_t;

end package utils;

-- Package Body Section
package body utils is

	-- Returns the bigger value from the two arguments
	pure function max(max1_int : in integer; max2_int : in integer) return integer is
	begin
		if (max1_int > max2_int) then
			return max1_int;
		else
			return max2_int;
		end if;
	end function;

	-- Returns the smaller value from the two arguments
	pure function min(min1_int : in integer; min2_int : in integer) return integer is
	begin
		if (min1_int < min2_int) then
			return min1_int;
		else
			return min2_int;
		end if;
	end function;

	-- Transforms incoming real value into integer (removing the decimal part) to round down
	pure function round_down(down_sgd : in signed) return signed is
	begin
		return down_sgd;
	end function;
	
	-- Transforms incoming real value into integer (removing the decimal part) and adds it 1 to round up
	pure function round_up(up_sgd : in signed) return signed is
	begin
		return (up_sgd + "1");
	end function;
	
	-- Modulus (remainder) function
	pure function modulus(mod1_sgd : in signed; mod2_sgd : in signed) return signed is
	begin
		return resize(mod1_sgd - mod2_sgd*round_down(mod1_sgd/mod2_sgd), mod1_sgd'length);
	end function;
	
	-- Modulus*R function
	pure function mod_R(modR_sgd : in signed; R_int : in integer) return signed is	
		variable power0_v	: signed(R_int downto 0) := (R_int => '1', others => '0');
		variable power1_v	: signed(R_int downto 0) := ((R_int-1) => '1', others => '0');
		variable modR_sgd_v	: signed(R_int downto 0) := resize(modR_sgd, R_int+1);
		variable modulus_v	: signed(R_int-1 downto 0);
	begin
		modulus_v := modulus(resize(modR_sgd_v+power1_v, R_int), power0_v);

		return resize(modulus_v - power1_v, R_int);
	end function;
	
	-- Sign function
	pure function sgn(sgn_int : in integer) return integer is
	begin
		if (sgn_int > 0) then
			return 1;
		elsif (sgn_int = 0) then
			return 0;
		else
			return -1;
		end if;
	end function;
	
	-- Sign plus function
	pure function sgnp(sgnp_int : in integer) return integer is
	begin
		if (sgnp_int >= 0) then
			return 1;
		else
			return -1;
		end if;
	end function;
	
	-- Clipping function
	pure function clip(clip_sgd : in signed; clip_min_sgd : in signed; clip_max_sgd : in signed) return signed is
	begin
		if (clip_sgd < clip_min_sgd) then
			return clip_min_sgd;
		elsif (clip_sgd > clip_max_sgd) then
			return clip_max_sgd;
		else
			return clip_sgd;
		end if;
	end function;
	
	-- Vector inner product function for "signed" signals
	pure function vector_product(arr1_sgd : in array_signed_t; arr2_sgd : in array_signed_t) return signed is
		variable product_v	: integer := 0;
		variable out_v		: signed(arr2_sgd(0)'length-1 downto 0);
	begin
		for i in 0 to (arr2_sgd'length-1) loop
			product_v := product_v + to_integer(arr1_sgd(i)*arr2_sgd(i));
		end loop;
		out_v := to_signed(product_v, arr2_sgd(0)'length);

		return out_v;
	end function;

	-- Vector inner product function for "unsigned" signals
	pure function vector_product(arr1_usgd : in array_unsigned_t; arr2_usgd : in array_unsigned_t) return unsigned is
		variable product_v	: integer := 0;
		variable out_v		: unsigned(arr2_usgd(0)'length-1 downto 0);
	begin
		for i in 0 to (arr2_usgd'length-1) loop
			product_v := product_v + to_integer(arr1_usgd(i)*arr2_usgd(i));
		end loop;
		out_v := to_unsigned(product_v, arr2_usgd(0)'length);

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