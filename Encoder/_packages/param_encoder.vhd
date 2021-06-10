library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.types_encoder.all;

-- Table E-3: Encoder Quantities
package param_encoder is

	constant B_C	: integer range 1 to 8		:= 1;			-- Output word size in bytes
	constant M_C	: integer range 1 to NZ_C	:= 3;			-- Sub-frame interleaving depth
	
	-- Sample-Adaptive Entropy Coder
	constant K2_AR_C: array_integer_t(1 to NZ_C-1) := (others => 7);				-- range 0 to (work.utils_image.min(D_C-2, 14)) Accumulator initialization parameters
	constant K_C	: integer range 0 to (work.utils_image.min(D_C-2, 14)) := 7;	-- Accumulator initialization constant
	
	-- Hybrid Entropy Coder (and Sample-Adaptive)
	constant Umax_C	: integer range 8 to 32		:= 16;			-- Unary length limit
	constant Yo_C	: integer range 1 to 8		:= 4;			-- Initial count exponent
	constant Y_C	: integer range (work.utils_image.max(4, Yo_C+1)) to 11 := 6; -- Rescaling counter size
	
	-- Block-Adaptive Entropy Coder
	constant N_C	: integer range 2 to 32		:= D_C;			-- Resolution 5.4.3.4.2.3
	constant J_C	: integer range 8 to 64		:= 8;			-- Block size (only 8, 16, 32 or 64 allowed)
	constant Rs_C	: integer range 1 to 4096	:= 1000;		-- Reference sample interval

	-- Low-Entropy codes table
	constant LOW_ENTR_CODES_C : low_entropy_code_t := (
		in_sym_limit => (12, 10, 8, 6, 6, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 0),
		threshold => (303336, 225404, 166979, 128672, 95597, 69670, 50678, 34898, 23331, 14935, 9282, 5510, 3195, 1928, 1112, 408)
	);

end package param_encoder;