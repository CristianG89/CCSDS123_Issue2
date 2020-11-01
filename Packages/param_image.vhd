library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Table E-1: Coordinate Indices and Image Quantities
package param_image is

	constant NX_C	: integer range 1 to 2**16 := 100;		-- Image X-dimensions 
	constant NY_C	: integer range 1 to 2**16 := 100;		-- Image Y-dimensions
	constant NZ_C	: integer range 1 to 2**16 := 100;		-- Image Z-dimensions	

	constant TAU_C	: integer range 1 to 15 := 7;			-- Number of supplementary information tables
	constant D_C	: integer range 2 to 32 := 16;			-- Image dynamic range in bits
	constant DI_C	: integer range 1 to 32 := 30;			-- integer supplementary information table bit depth
	constant DF_C	: integer range 1 to 23 := 20;			-- Float supplementary information table significand bit depth
	constant DE_C	: integer range 2 to 8	:= 5;			-- Float supplementary information table exponent bit depth
	constant BIAS_C	: integer range 0 to (2**DE_C-1) := 10;	-- Float supplementary information table exponent bias

end package param_image;