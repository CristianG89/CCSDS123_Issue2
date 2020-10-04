library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.param_image.all;

-- Table E-3: Encoder Quantities
package param_encoder is

	constant B_C	: integer range 1 to 8		:= 4;			-- Output word size in bytes
	constant M_C	: integer range 1 to Nz_C	:= 3;			-- Sub-frame interleaving depth
	
	-- Sample-Adaptive Entropy Coder
	constant K2_C	: integer range 0 to (min(D_C-2, 14)) := 7;	-- Accumulator initialization parameters
	constant K_C	: integer range 0 to (min(D_C-2, 14)) := 7;	-- Accumulator initialization constant
	
	-- Hybrid Entropy Coder (and Sample-Adaptive)
	constant Umax_C	: integer range 8 to 32		:= 16;			-- Unary length limit
	constant Yo_C	: integer range 1 to 8		:= 4;			-- Initial count exponent
	constant Y_C	: integer range (max(4, Yo_C+1)) to 11 := 7;-- Rescaling counter size
	
	-- Block-Adaptive Entropy Coder
	constant N_C	: integer range 2 to 32		:= D_C;			-- Resolution 5.4.3.4.2.3
	constant J_C	: integer range 8 to 64		:= 8;			-- Block size (only 8, 16, 32 or 64 allowed)
	constant Re_C	: integer range 1 to 4096	:= 1000;		-- Reference sample interval

end package param_encoder;