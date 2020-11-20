library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Table E-1: Coordinate Indices and Image Quantities
package param_image is

	constant NX_C	: integer range 1 to 2**16 := 10;		-- Image X-dimensions 
	constant NY_C	: integer range 1 to 2**16 := 10;		-- Image Y-dimensions
	constant NZ_C	: integer range 1 to 2**16 := 10;		-- Image Z-dimensions	

	constant TAU_C	: integer range 1 to 15 := 7;			-- Number of supplementary information tables
	constant D_C	: integer range 2 to 32 := 16;			-- Image dynamic range in bits
	constant DI_C	: integer range 1 to 32 := 30;			-- Supplementary information integer table bit depth
	constant DF_C	: integer range 1 to 23 := 20;			-- Supplementary information float table significand bit depth
	constant DE_C	: integer range 2 to 8	:= 5;			-- Supplementary information float table exponent bit depth
	constant ALPHA_C: integer range 0 to (2**DE_C-1) := 10;	-- Supplementary information float table exponent
	constant BETA_C	: integer range 0 to (2**DE_C-1) := 20;	-- Supplementary information float table exponent bias
	
	constant S_MIN_C : integer := 0;					-- S_MIN_C when working with unsigned samples
	constant S_MAX_C : integer := 2**D_C-1;			-- S_MAX_C when working with unsigned samples
	constant S_MID_C : integer := 2**(D_C-1);			-- S_MID_C when working with unsigned samples
	
	constant S_MIN_SGN_C  : integer := -2**(D_C-1);			-- S_MIN_C when working with signed samples
	constant S_MAX_SGN_C  : integer := 2**(D_C-1);			-- S_MAX_C when working with signed samples
	constant S_MID_SGN_C  : integer := 0;					-- S_MID_C when working with signed samples

end package param_image;