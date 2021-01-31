library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

-- Package Declaration Section
package utils is
	
	-- NOTE: IEEE library "math_real" cannot be used in the present design because
	-- it is not supported by Vivado, so many basic functions are here implemented.
	
	pure function max_int(max1_int : in integer; max2_int : in integer) return integer;
	pure function min_int(min1_int : in integer; min2_int : in integer) return integer;
	pure function max_sgn(max1_sgn : in signed; max2_sgn : in signed) return signed;
	pure function min_sgn(min1_sgn : in signed; min2_sgn : in signed) return signed;
	
	pure function round_down(down_sgd : in signed) return signed;
	pure function round_up(up_sgd : in signed) return signed;
	
	pure function modulus(mod1_sgd : in signed; mod2_sgd : in signed) return signed;
	pure function mod_R(modR_sgd : in signed; R_int : in integer) return signed;

	pure function sgn(sgn_sgn : in signed) return signed;
	pure function sgnp(sgnp_sgn : in signed) return signed;
	
	pure function clip(clip_sgd : in signed; clip_min_sgd : in signed; clip_max_sgd : in signed) return signed;

	pure function vector_product(arr1_sgd : in array_signed_t; arr2_sgd : in array_signed_t) return signed;
	pure function vector_product(arr1_usgd : in array_unsigned_t; arr2_usgd : in array_unsigned_t) return unsigned;
	
	pure function reset_img_coord return img_coord_t;
	pure function reset_s2_pos return s2_pos_t;
	pure function reset_ldiff_pos return ldiff_pos_t;

end package utils;

-- Package Body Section
package body utils is

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
	
	-- Modulus*R function		--- REVISAR (ARE DIMENSIONS OK???)
	pure function mod_R(modR_sgd : in signed; R_int : in integer) return signed is	
		variable power0_v	: signed(R_int-1 downto 0) := (others => '1');
		variable power1_v	: signed(R_int-2 downto 0) := (others => '1');
		variable modulus_v	: signed(R_int-1 downto 0);
	begin
		modulus_v := modulus(resize(modR_sgd + power1_v, R_int), power0_v);

		return resize(modulus_v - power1_v, R_int);
	end function;
	
	-- Sign function
	pure function sgn(sgn_sgn : in signed) return signed is
	begin
		if (sgn_sgn > "0") then
			return "1";
		elsif (sgn_sgn = "0") then
			return "0";
		else
			return "-1";
		end if;
	end function;
	
	-- Sign plus function
	pure function sgnp(sgnp_sgn : in signed) return signed is
	begin
		if (sgnp_sgn >= "0") then
			return "1";
		else
			return "-1";
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
		variable product_v : signed(arr2_sgd(0)'length-1 downto 0);
	begin
		for i in 0 to (arr2_sgd'length-1) loop
			product_v := resize(product_v + arr1_sgd(i)*arr2_sgd(i), arr2_sgd(0)'length);
		end loop;

		return product_v;
	end function;

	-- Vector inner product function for "unsigned" signals
	pure function vector_product(arr1_usgd : in array_unsigned_t; arr2_usgd : in array_unsigned_t) return unsigned is
		variable product_v : unsigned(arr2_usgd(0)'length-1 downto 0) := (others => '0');
	begin
		for i in 0 to (arr2_usgd'length-1) loop
			product_v := resize(product_v + arr1_usgd(i)*arr2_usgd(i), arr2_usgd(0)'length);
		end loop;

		return product_v;
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

	-- Resets the s2 positions record
	pure function reset_s2_pos return s2_pos_t is
		variable s2_pos_v : s2_pos_t;
	begin
		s2_pos_v.cur := (others => '0');
		s2_pos_v.w	 := (others => '0');
		s2_pos_v.wz  := (others => '0');
		s2_pos_v.n	 := (others => '0');
		s2_pos_v.nw  := (others => '0');
		s2_pos_v.ne  := (others => '0');
		
		return s2_pos_v;
	end function;

	-- Resets the local differences positions record
	pure function reset_ldiff_pos return ldiff_pos_t is
		variable ldiff_pos_v : ldiff_pos_t;
	begin
		ldiff_pos_v.c  := (others => '0');
		ldiff_pos_v.n  := (others => '0');
		ldiff_pos_v.w  := (others => '0');
		ldiff_pos_v.nw := (others => '0');
		
		return ldiff_pos_v;
	end function;	

end package body utils;