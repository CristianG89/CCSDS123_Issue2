library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Table E-1: Coordinate Indices and Image Quantities
package param_image is

	constant NX_C	: integer range 1 to 2**16 := 10;		-- Image X-dimensions 
	constant NY_C	: integer range 1 to 2**16 := 10;		-- Image Y-dimensions
	constant NZ_C	: integer range 1 to 2**16 := 10;		-- Image Z-dimensions	

	constant TAU_C	: integer range 1 to 15 := 1;			-- Number of supplementary information tables
	constant D_C	: integer range 2 to 32 := 16;			-- Image dynamic range in bits
	constant DI_C	: integer range 1 to 32 := 30;			-- Supplementary information integer table bit depth
	constant DF_C	: integer range 1 to 23 := 20;			-- Supplementary information float table significand bit depth
	constant DE_C	: integer range 2 to 8	:= 5;			-- Supplementary information float table exponent bit depth
	constant ALPHA_C: integer range 0 to (2**DE_C-1) := 10;	-- Supplementary information float table exponent
	constant BETA_C	: integer range 0 to (2**DE_C-1) := 20;	-- Supplementary information float table exponent bias

	constant SAMPLE_TYPE_C : std_logic := '0';				-- 0 = samples unsigned type, 1 = samples signed type
	
	-----------------------------------------------------------------------------------------------------------------------
	
	constant n0_C : signed(2 downto 0) := "000";
	constant n1_C : signed(2 downto 0) := "001";
	constant n2_C : signed(2 downto 0) := "010";
	constant n3_C : signed(2 downto 0) := "011";
	constant n4_C : signed(2 downto 0) := "100";
	constant n5_C : signed(2 downto 0) := "101";
	constant n6_C : signed(2 downto 0) := "110";
	constant n7_C : signed(2 downto 0) := "111";

	-----------------------------------------------------------------------------------------------------------------------

	constant BSQ_C : std_logic_vector(1 downto 0) := "00";
	constant BIP_C : std_logic_vector(1 downto 0) := "01";
	constant BIL_C : std_logic_vector(1 downto 0) := "10";

end package param_image;