--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		20/02/2021
--------------------------------------------------------------------------------
-- IP name:		metadata_pred
--
-- Description: Defines the "Predictor Metadata" from compressed image header part
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils_image.all;
use work.param_predictor.all;

entity metadata_pred is
	generic (
		PREDICT_MODE_G	: std_logic;
		LSUM_TYPE_G		: std_logic_vector(1 downto 0);
		W_INIT_TYPE_G	: std_logic
	);
	port (
	);
end metadata_pred;

architecture Behaviour of metadata_pred is

	-- Record "Primary" sub-structure from "Predictor Metadata" (Table 5-6)
	type mdata_pred_primary_t is record
		reserved_1					=> (others => '0'),
		smpl_repr_flag				=> iff(THETA_C <= 0, '1', '0'),
		num_pred_bands				=> P_C,
		pred_mode					=> PREDICT_MODE_G,
		w_exp_offset_flag			=> iff(Ci_C = C_C = 0, '0', '1'),
		lsum_type					=> LSUM_TYPE_G,
		register_size				=> std_logic_vector(to_unsigned(R_C, 6)),
		w_comp_res					=> std_logic_vector(to_unsigned((OMEGA_C-4), 4)),
		w_upd_scal_exp_chng_int		=> std_logic_vector(to_unsigned((log2(T_INC_C)-4), 4)),
		w_upd_scal_exp_init_param	=> std_logic_vector(to_unsigned((V_MIN_C+6), 4)),
		w_upd_scal_exp_final_param	=> std_logic_vector(to_unsigned((V_MIN_C+6), 4)),
		w_exp_off_table_flag		: std_logic_vector(0 downto 0);
		w_init_method				=> W_INIT_TYPE_G,
		w_init_table_flag			: std_logic_vector(0 downto 0);
		w_init_res					: std_logic_vector(4 downto 0);
		total_width					: integer;
	end record mdata_pred_primary_t;

begin

end Behaviour;