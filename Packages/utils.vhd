library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

-- Package Declaration Section
package utils is
	
	-- NOTE: IEEE library "math_real" cannot be used in the present design because it is not supported by Vivado,
	-- so many basic functions are here implemented.
	
	pure function max(int1_in : in integer; int2_in : in integer) return integer;
	pure function min(int1_in : in integer; int2_in : in integer) return integer;
	
	pure function round_down(real_in : in real) return integer;
	pure function round_up(real_in : in real) return integer;
	
	pure function modulus(int1_in : in integer; int2_in : in integer) return integer;
	pure function mod_R(int1_in : in integer; pos1_in : in positive) return integer;
	
	pure function sgn(real_in : in real) return integer;
	pure function sgnp(real_in : in real) return integer;
	
	pure function clip(real_in : in real; real_max_in : in real; real_min_in : in real) return integer;

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
	pure function mod_R(int1_in : in integer; pos1_in : in positive) return integer;	
		variable power_v  : integer := 2 ** (pos1_in - 1);
		variable modulus_v : integer;
	begin
		modulus_v := modulus((int1_in+power_v), 2**pos1_in);
	
		return (modulus_v - power_v);
	end function;
	
	-- Sign function
	pure function sgn(real_in : in real) return integer is
	begin
		if (real_in > 0.0) then
			return 1;
		elsif (real_in = 0.0) then
			return 0;
		else
			return -1;
		end if;
	end function;
	
	-- Sign plus function
	pure function sgnp(real_in : in real) return integer is
	begin
		if (real_in >= 0.0) then
			return 1;
		else
			return -1;
		end if;
	end function;
	
	-- Clipping function
	pure function clip(real_in : in real; real_max_in : in real; real_min_in : in real) return integer is
	begin
		if (real_in < real_min_in) then
			return integer(real_min_in);
		elsif (real_in > real_max_in) then
			return integer(real_max_in);
		else
			return integer(real_in);
		end if;
	end function;

end package body utils;