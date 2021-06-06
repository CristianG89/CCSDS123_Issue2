library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_image.all;
use work.utils_image.all;

use work.types_predictor.all;

-- Package Declaration Section
package utils_predictor is

	pure function modulus(mod1_sgd : in signed; mod2_sgd : in signed) return signed;
	pure function modulus(mod1_usgd : in unsigned; mod2_usgd : in unsigned) return unsigned;
	pure function mod_R(modR_sgd : in signed; R_int : in integer) return signed;
	pure function mod_R(modR_usgd : in unsigned; R_int : in integer) return unsigned;

	pure function sgn(sgn_sgn : in signed) return integer;
	pure function sgnp(sgnp_sgn : in signed) return integer;

	pure function clip(clip_int : in integer; clip_min_int : in integer; clip_max_int : in integer) return integer;
	pure function clip(clip_sgd : in signed; clip_min_sgd : in signed; clip_max_sgd : in signed) return signed;
	pure function clip(clip_usgd : in unsigned; clip_min_usgd : in unsigned; clip_max_usgd : in unsigned) return unsigned;

	pure function vector_product(arr1_sgd : in array_signed_t; arr2_sgd : in array_signed_t) return signed;
	pure function vector_product(arr1_usgd : in array_unsigned_t; arr2_usgd : in array_unsigned_t) return unsigned;

	pure function reset_err_lim return err_lim_t;
	pure function reset_s2_pos return s2_pos_t;
	pure function reset_ldiff_pos return ldiff_pos_t;

end package utils_predictor;

-- Package Body Section
package body utils_predictor is
	
	-- Modulus (remainder) function for signed signals
	pure function modulus(mod1_sgd : in signed; mod2_sgd : in signed) return signed is
	begin
		return resize(mod1_sgd - mod2_sgd*round_down(mod1_sgd, mod2_sgd), mod1_sgd'length);
	end function;
	
	-- Modulus (remainder) function for unsigned signals
	pure function modulus(mod1_usgd : in unsigned; mod2_usgd : in unsigned) return unsigned is
	begin
		return resize(mod1_usgd - mod2_usgd*round_down(mod1_usgd, mod2_usgd), mod1_usgd'length);
	end function;
	
	-- Modulus*R function for signed signals		-- REVISAR (ARE DIMENSIONS OK???)
	pure function mod_R(modR_sgd : in signed; R_int : in integer) return signed is	
		variable power0_v	: signed(R_int+3 downto 0) := (R_int+0 => '1', others => '0');
		variable power1_v	: signed(R_int+3 downto 0) := (R_int+1 => '1', others => '0');
		variable modulus_v	: signed(R_int+3 downto 0);		
	begin	-- "+3"/"+3+1" are used to ensure the MSb will always be 0 (conflictive for "signed"...)
		modulus_v := modulus(resize(modR_sgd + power1_v, R_int+3+1), power0_v);

		return resize(modulus_v - power1_v, R_int);
	end function;
	
	-- Modulus*R function for unsigned signals		-- REVISAR (ARE DIMENSIONS OK???)
	pure function mod_R(modR_usgd : in unsigned; R_int : in integer) return unsigned is
		variable power0_v	: unsigned(R_int+0 downto 0) := (R_int+0 => '1', others => '0');
		variable power1_v	: unsigned(R_int+1 downto 0) := (R_int+1 => '1', others => '0');
		variable modulus_v	: unsigned(R_int+0 downto 0);
	begin
		modulus_v := modulus(resize(modR_usgd + power1_v, R_int), power0_v);

		return resize(modulus_v - power1_v, R_int);
	end function;
	
	-- Sign function
	pure function sgn(sgn_sgn : in signed) return integer is
		variable ref_v : signed(sgn_sgn'length-1 downto 0) := (others => '0');
	begin
		if (sgn_sgn > ref_v) then
			return 1;
		elsif (sgn_sgn = ref_v) then
			return 0;
		else
			return -1;
		end if;
	end function;
	
	-- Sign plus function
	pure function sgnp(sgnp_sgn : in signed) return integer is
		variable ref_v : signed(sgnp_sgn'length-1 downto 0) := (others => '0');
	begin
		if (sgnp_sgn >= ref_v) then
			return 1;
		else
			return -1;
		end if;
	end function;
		
	-- Clipping function for "integer" signals
	pure function clip(clip_int : in integer; clip_min_int : in integer; clip_max_int : in integer) return integer is
	begin
		if (clip_int < clip_min_int) then
			return clip_min_int;
		elsif (clip_int > clip_max_int) then
			return clip_max_int;
		else
			return clip_int;
		end if;
	end function;
	
	-- Clipping function for "signed" signals
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
	
	-- Clipping function for "unsigned" signals
	pure function clip(clip_usgd : in unsigned; clip_min_usgd : in unsigned; clip_max_usgd : in unsigned) return unsigned is
	begin
		if (clip_usgd < clip_min_usgd) then
			return clip_min_usgd;
		elsif (clip_usgd > clip_max_usgd) then
			return clip_max_usgd;
		else
			return clip_usgd;
		end if;
	end function;
	
	-- Vector inner product function for "signed" signals
	pure function vector_product(arr1_sgd : in array_signed_t; arr2_sgd : in array_signed_t) return signed is
		variable max_length_v : integer := max(arr1_sgd(0)'length, arr2_sgd(0)'length);
		variable product_v	  : signed(max_length_v-1 downto 0) := (others => '0');
	begin		-- As the two input arrays might have different values length, we work with the longest until the end
		for i in 0 to (arr1_sgd'length-1) loop
			product_v := resize(product_v + arr1_sgd(i)*arr2_sgd(i), max_length_v);
		end loop;

		return resize(product_v, arr2_sgd(0)'length);
	end function;

	-- Vector inner product function for "unsigned" signals
	pure function vector_product(arr1_usgd : in array_unsigned_t; arr2_usgd : in array_unsigned_t) return unsigned is
		variable max_length_v : integer := max(arr1_usgd(0)'length, arr2_usgd(0)'length);
		variable product_v	  : unsigned(max_length_v-1 downto 0) := (others => '0');
	begin		-- As the two input arrays might have different values length, we work with the longest until the end
		for i in 0 to (arr1_usgd'length-1) loop
			product_v := resize(product_v + arr1_usgd(i)*arr2_usgd(i), max_length_v);
		end loop;

		return resize(product_v, arr2_usgd(0)'length);
	end function;

	-- Resets the error limit values record
	pure function reset_err_lim return err_lim_t is
		variable err_lim_v : err_lim_t;
	begin
		err_lim_v.abs_c	  := 0;
		err_lim_v.abs_arr := (others => 0);
		err_lim_v.rel_c	  := 0;
		err_lim_v.rel_arr := (others => 0);

		return err_lim_v;
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

end package body utils_predictor;