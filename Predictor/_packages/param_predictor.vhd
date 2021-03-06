library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

-- Table E-2: Predictor Quantities
package param_predictor is

	constant P_C	 : integer range 0 to 15 			:= 7;			-- Number of spectral bands used for prediction
	constant MAX_CZ_C: integer 							:= P_C + 3;		-- Maximum number of local diff values used for prediction
	
	constant DA_C	 : integer range 1 to (work.utils_image.min(D_C-1, 16)) := 7;	-- Absolute error limit bit depth
	constant A_C	 : integer range 0 to (2**DA_C-1)	:= 30;			-- Absolute error limit constant
	constant DR_C	 : integer range 1 to (work.utils_image.min(D_C-1, 16)) := 7;	-- Relative error limit bit depth
	constant R_C	 : integer range 0 to (2**DR_C-1)	:= 50;			-- Relative error limit constant	
	
	constant U_C	 : integer range 0 to 9 			:= 3;			-- Error limit update period exponent
	
	constant THETA_C : integer range 0 to 4 			:= 3;									-- Sample representative resolution
	constant FI_AR_C : array_integer_t(0 to NZ_C-1) := (others => 5);	-- range 0 to (2**THETA_C-1) Sample representative damping
	constant PSI_AR_C: array_integer_t(0 to NZ_C-1) := (others => 5);	-- range 0 to (2**THETA_C-1) Sample representative offset
	
	constant Ci_C	 : integer range -6 to 5			:= 3;			-- Inter-band weight exponent offsets
	constant C_C	 : integer range -6 to 5			:= 3;			-- Intra-band weight exponent offsets
	
	-- Max. number should be "V_MAX_C"!!
	constant V_MIN_C : integer range -6 to 9 			:= 2;			-- Initial weight update scaling exponent parameters
	constant V_MAX_C : integer range V_MIN_C to 9 		:= 7;			-- Final weight update scaling exponent parameters
	constant T_INC_C : integer range 4 to 11	 		:= 5;			-- Weight update scaling exponent change interval
	
	constant OMEGA_C : integer range 4 to 19			:= 17;			-- Weight resolution
	constant W_MIN_C : signed(OMEGA_C+3-1 downto 0)		:= to_signed(-2**(OMEGA_C+2), OMEGA_C+3);	-- Minimum possible weight value
	constant W_MAX_C : signed(OMEGA_C+3-1 downto 0)		:= to_signed(2**(OMEGA_C+2)-1, OMEGA_C+3);	-- Maximum possible weight value
	constant Q_C	 : integer range 3 to (OMEGA_C+3) 	:= 8;			-- Weight initialization resolution
	constant LAMBDA_C: array_signed_t(MAX_CZ_C-1 downto 0)(Q_C-1 downto 0) := (others => (others => '1')); -- Weight initialization vector
	constant Re_C	 : integer range (work.utils_image.max(32,D_C+OMEGA_C+2)) to 64 := 40; -- Register size in bits, used in prediction calculation

end package param_predictor;