library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;

-- Package Declaration Section
package utils_image is
	
	-- NOTE: IEEE library "math_real" cannot be used in the present design because
	-- it is not supported by Vivado, so many basic functions are here implemented.
	
	pure function max(max1 : in integer; max2 : in integer) return integer;
	pure function max(max1 : in signed; max2 : in signed) return signed;
	pure function max(max1 : in unsigned; max2 : in unsigned) return unsigned;
	pure function min(min1 : in integer; min2 : in integer) return integer;
	pure function min(min1 : in signed; min2 : in signed) return signed;
	pure function min(min1 : in unsigned; min2 : in unsigned) return unsigned;
	
	pure function log2(val_in : in integer) return integer;
	
	pure function round_down(dw1 : in integer; dw2 : in integer) return integer;
	pure function round_down(dw1 : in signed; dw2 : in signed) return signed;
	pure function round_down(dw1 : in unsigned; dw2 : in unsigned) return unsigned;
	pure function round_up(up1 : in integer; up2 : in integer) return integer;
	pure function round_up(up1 : in signed; up2 : in signed) return signed;
	pure function round_up(up1 : in unsigned; up2 : in unsigned) return unsigned;
	
	pure function iif(cond_in : in boolean; true_in : in integer; false_in : in integer) return integer;
	pure function iif(cond_in : in boolean; true_in : in signed; false_in : in signed) return signed;
	pure function iif(cond_in : in boolean; true_in : in unsigned; false_in : in unsigned) return unsigned;
	pure function iif(cond_in : in boolean; true_in : in std_logic; false_in : in std_logic) return std_logic;
	pure function iif(cond_in : in boolean; true_in : in std_logic_vector; false_in : in std_logic_vector) return std_logic_vector;
	
	pure function check_array_pos_same(array_in : in array_integer_t) return std_logic;
	pure function locate_position(smpl_order : in std_logic_vector; pos1 : in integer; pos2 : in integer; pos3 : in integer) return integer;
	pure function reset_img_coord return img_coord_t;

end package utils_image;

-- Package Body Section
package body utils_image is

	-- Returns the bigger value from the two arguments (integer format)
	pure function max(max1 : in integer; max2 : in integer) return integer is
	begin
		if (max1 > max2) then
			return max1;
		else
			return max2;
		end if;
	end function;
	
	-- Returns the bigger value from the two arguments (signed format)
	pure function max(max1 : in signed; max2 : in signed) return signed is
	begin
		if (max1 > max2) then
			return max1;
		else
			return max2;
		end if;
	end function;

	-- Returns the bigger value from the two arguments (unsigned format)
	pure function max(max1 : in unsigned; max2 : in unsigned) return unsigned is
	begin
		if (max1 > max2) then
			return max1;
		else
			return max2;
		end if;
	end function;
	
	-- Returns the smaller value from the two arguments (integer format)
	pure function min(min1 : in integer; min2 : in integer) return integer is
	begin
		if (min1 < min2) then
			return min1;
		else
			return min2;
		end if;
	end function;

	-- Returns the smaller value from the two arguments (signed format)
	pure function min(min1 : in signed; min2 : in signed) return signed is
	begin
		if (min1 < min2) then
			return min1;
		else
			return min2;
		end if;
	end function;

	-- Returns the smaller value from the two arguments (unsigned format)
	pure function min(min1 : in unsigned; min2 : in unsigned) return unsigned is
	begin
		if (min1 < min2) then
			return min1;
		else
			return min2;
		end if;
	end function;
	
	-- Returns the logaritmus in base 2 for an integer value
	pure function log2(val_in : in integer) return integer is
        variable log_v : integer;
    begin
        for i in 0 to 31 loop
            if(val_in <= (2**i)) then
                log_v := i;
                exit;
            end if;
        end loop;
		
        return log_v;
    end function log2;
	
	-- Makes a division and rounds the result down (integer format)
	pure function round_down(dw1 : in integer; dw2 : in integer) return integer is
		variable result_v : integer;
	begin
		result_v := dw1/dw2;
		
		return result_v;
	end function;

	-- Makes a division and rounds the result down (signed format)
	pure function round_down(dw1 : in signed; dw2 : in signed) return signed is
		variable result_v : signed(dw1'length-1 downto 0);
	begin
		result_v := dw1/dw2;
		
		return resize(result_v, dw1'length);
	end function;

	-- Makes a division and rounds the result down (unsigned format)
	pure function round_down(dw1 : in unsigned; dw2 : in unsigned) return unsigned is
		variable result_v : unsigned(dw1'length-1 downto 0);
	begin
		result_v := dw1/dw2;
		
		return resize(result_v, dw1'length);
	end function;

	-- Makes a division and rounds the result up (integer format)
	pure function round_up(up1 : in integer; up2 : in integer) return integer is
		variable result_v : integer;
	begin
		if (up1 mod up2 /= 0) then
			result_v := up1/up2 + 1;
		else
			result_v := up1/up2;
		end if;
		
		return result_v;
	end function;

	-- Makes a division and rounds the result up (signed format)
	pure function round_up(up1 : in signed; up2 : in signed) return signed is
		variable result_v : signed(up1'length-1 downto 0);
	begin
		if (up1 mod up2 /= "0") then
			result_v := up1/up2 + "1";
		else
			result_v := up1/up2;
		end if;
		
		return resize(result_v, up1'length);
	end function;

	-- Makes a division and rounds the result up (unsigned format)
	pure function round_up(up1 : in unsigned; up2 : in unsigned) return unsigned is
		variable result_v : unsigned(up1'length-1 downto 0);
	begin
		if (up1 mod up2 /= "0") then
			result_v := up1/up2 + "1";
		else
			result_v := up1/up2;
		end if;
		
		return resize(result_v, up1'length);
	end function;

	-- Immediate IF (iif) function for "integer" values
	pure function iif(cond_in : in boolean; true_in : in integer; false_in : in integer) return integer is
	begin
		if (cond_in = true) then
			return true_in;
		else
			return false_in;
		end if;
	end function;

	-- Immediate IF (iif) function for "signed" values
	pure function iif(cond_in : in boolean; true_in : in signed; false_in : in signed) return signed is
	begin
		if (cond_in = true) then
			return true_in;
		else
			return false_in;
		end if;
	end function;
	
	-- Immediate IF (iif) function for "unsigned" values
	pure function iif(cond_in : in boolean; true_in : in unsigned; false_in : in unsigned) return unsigned is
	begin
		if (cond_in = true) then
			return true_in;
		else
			return false_in;
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
	
	-- Immediate IF (iif) function for "std_logic_vector" values
	pure function iif(cond_in : in boolean; true_in : in std_logic_vector; false_in : in std_logic_vector) return std_logic_vector is
	begin
		if (cond_in = true) then
			return true_in;
		else
			return false_in;
		end if;
	end function;

	-- Returns '0' if all values within the "integer" array are the same. Otherwise '1' 
	pure function check_array_pos_same(array_in : in array_integer_t) return std_logic is
		variable prev_pos_v : integer;
	begin
		prev_pos_v := array_in(0);
		for i in 1 to array_in'length-1 loop
			if (prev_pos_v /= array_in(i)) then
				return '1';
			else
				prev_pos_v := array_in(i);
			end if;
		end loop;
		
		return '0';
	end function;
	
	-- Returns the right position value, depending on the input order
	pure function locate_position(smpl_order : in std_logic_vector; pos1 : in integer; pos2 : in integer; pos3 : in integer) return integer is
		variable pos_v : integer := 0;
	begin
		case smpl_order is
			when BSQ_C	=> pos_v := pos1;
			when BIP_C	=> pos_v := pos2;
			when BIL_C	=> pos_v := pos3;
			when others	=> pos_v := 1;
		end case;

		return pos_v;
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