library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.param_image.all;

-- Table E-2: Predictor Quantities
package param_predictor is

	constant P_C	: integer range 0 to 15 			:= 7;			-- Number of spectral bands used for prediction
	constant OMEGA_C: integer range 4 to 19				:= 10;			-- Weight resolution
	constant Q_C	: integer range 3 to (OMEGA_C+3) 	:= 5;			-- Weight initialization resolution
	constant Re_C	: integer range (max(32, D_C+OMEGA_C+2)) to 64 := 7;-- Register size in bits, used in prediction calculation
	
	constant DA_C	: integer range 1 to (min(D_C-1, 16)) := 7;			-- Absolute error limit bit depth
	constant A_C	: integer range 0 to (2**DA_C-1)	:= 30;			-- Absolute error limit constant
	constant Az_C	: integer range 0 to (2**DA_C-1)	:= 30;			-- Absolute error limit
	constant DR_C	: integer range 1 to (min(D_C-1, 16)) := 7;			-- Relative error limit bit depth
	constant R_C	: integer range 0 to (2**DR_C-1)	:= 50;			-- Relative error limit constant
	constant Rz_C	: integer range 0 to (2**DR_C-1)	:= 50;			-- Relative error limit
	constant U_C	: integer range 0 to 9 				:= 5;			-- Error limit update period exponent
	
	constant THETA_C: integer range 0 to 4 				:= 2;			-- Sample representative resolution
	constant FI_C	: integer range 0 to (2**THETA_C-1)	:= 7;			-- Sample representative damping
	constant PSI_C	: integer range 0 to (2**THETA_C-1) := 7;			-- Sample representative offset
	
	constant Çi_C	: integer range -6 to 5				:= 3;			-- Inter-band weight exponent offsets
	constant Ç_C	: integer range -6 to 5				:= 3;			-- Intra-band weight exponent offsets
	
	constant V_MIN_G: integer range -6 to V_MAX_G 		:= 2;			-- Initial weight update scaling exponent parameters
	constant V_MAX_G: integer range V_MIN_G to 9 		:= 7;			-- Final weight update scaling exponent parameters
	constant T_INC_C: integer range 2**4 to 2**11 		:= 2**5;		-- Weight update scaling exponent change interval

end package param_predictor;