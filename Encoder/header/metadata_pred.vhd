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

use work.types_encoder.all;
use work.utils_encoder.all;

entity metadata_pred is
	generic (
		PREDICT_MODE_G			: std_logic;
		LSUM_TYPE_G				: std_logic_vector(1 downto 0);
		W_INIT_TYPE_G			: std_logic;
		PER_ERR_LIM_UPD_G		: std_logic;
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G		: std_logic_vector(1 downto 0);
		W_EXP_OFF_TABL_FLAG_G	: boolean;
		W_INIT_TABL_FLAG_G		: boolean;
		DAMP_TABLE_FLAG_G		: boolean;
		OFFSET_TABLE_FLAG_G		: boolean
	);
	port (
		clock_i : in std_logic
	);
end metadata_pred;

architecture Behaviour of metadata_pred is

	-- Record "Sample Representative" sub-structure from "Predictor Metadata" (Table 5-12)
	constant MDATA_PRED_SMPL_REPR_C : mdata_pred_smpl_repr_t := (
		reserved_1					=> (others => '0'),
		smpl_repr_resolution		=> std_logic_vector(to_unsigned(THETA_C, 3)),
		reserved_2					=> (others => '0'),
		band_var_damp_flag			: std_logic_vector(0 downto 0);
		damp_table_flag				=> (others => DAMP_TABLE_FLAG_G),
		reserved_3					=> (others => '0'),
		fixed_damp_value			=> iif(!!PONER!!, std_logic_vector(to_unsigned(FI_C, 4)), "0000"),
		reserved_4					=> (others => '0'),
		band_var_offset_flag		: std_logic_vector(0 downto 0);
		offset_table_flag			=> (others => OFFSET_TABLE_FLAG_G),
		reserved_5					=> (others => '0'),
		fixed_offset_value			=> iif(!!PONER!!, std_logic_vector(to_unsigned(PSI_C, 4)), "0000"),
		damp_table_subblock			: std_logic_vector;
		offset_table_subblock		: std_logic_vector;
		total_width					: integer
	);
	
	-- Record "Relative Error Limit" sub-structure from "Predictor Metadata" (Table 5-11)
	constant MDATA_PRED_REL_ERR_LIM_C : mdata_pred_rel_err_limit_t := (
		reserved_1					=> (others => '0'),
		abs_err_limit_assig_meth	=> iif((FIDEL_CTRL_TYPE_G = "02" or FIDEL_CTRL_TYPE_G = "03"), '1', '0'),
		reserved_2					=> (others => '0'),
		rel_err_limit_bit_depth		=> std_logic_vector(to_unsigned(DR_C, 4)),
		rel_err_limit_val_subblock		: std_logic_vector;
		total_width						: integer
	);

	-- Record "Absolute Error Limit" sub-structure from "Predictor Metadata" (Table 5-10)
	constant MDATA_PRED_ABS_ERR_LIM_C : mdata_pred_abs_err_limit_t := (
		reserved_1					=> (others => '0'),
		abs_err_limit_assig_meth	=> iif((FIDEL_CTRL_TYPE_G = "01" or FIDEL_CTRL_TYPE_G = "03"), '1', '0'),
		reserved_2					=> (others => '0'),
		abs_err_limit_bit_depth		=> std_logic_vector(to_unsigned(DA_C, 4)),
		abs_err_limit_val_subblock		: std_logic_vector;
		total_width						: integer
	);
	
	-- Record "Error Limit Update Period" sub-structure from "Predictor Metadata" (Table 5-9)
	constant MDATA_PRED_ERR_LIM_UPD_PER_C : mdata_pred_err_limit_upd_period_t := (
		reserved_1					=> (others => '0'),
		per_upd_flag				=> (others => PER_ERR_LIM_UPD_G),
		reserved_2					=> (others => '0'),
		upd_period_exp				=> iif(PER_ERR_LIM_UPD_G, std_logic_vector(to_unsigned(U_C, 4)), "0000"),
		total_width					=> 8
	);
	
	-- Record "Quantization" sub-structure from "Predictor Metadata" (Table 5-8)
	constant MDATA_PRED_QUANT_C : mdata_pred_quant_t := (
		err_limit_upd_period		=> MDATA_PRED_ERR_LIM_UPD_PER_C,
		absol_err_limit				=> MDATA_PRED_ABS_ERR_LIM_C,
		relat_err_limit				=> MDATA_PRED_REL_ERR_LIM_C,
		total_width					=> MDATA_PRED_ERR_LIM_UPD_PER_C'total_width+MDATA_PRED_ABS_ERR_LIM_C'total_width+MDATA_PRED_REL_ERR_LIM_C'total_width
	);

	-- Record "Weight tables" sub-structure from "Predictor Metadata" (Table 5-7)
	constant MDATA_PRED_WEIGHT_TABLES_C : mdata_pred_weight_tables_t := (
		w_init_table				: std_logic_vector;
		w_exp_off_table				: std_logic_vector;
		total_width					: integer
	);

	-- Record "Primary" sub-structure from "Predictor Metadata" (Table 5-6)
	constant MDATA_PRED_PRIMARY_C : mdata_pred_primary_t := (
		reserved_1					=> (others => '0'),
		smpl_repr_flag				=> iif(THETA_C <= 0, "1", "0"),
		num_pred_bands				=> P_C,
		pred_mode					=> (others => PREDICT_MODE_G),
		w_exp_offset_flag			=> iif((Ci_C = 0) and (C_C = 0), "0", "1"),
		lsum_type					=> LSUM_TYPE_G,
		register_size				=> std_logic_vector(to_unsigned(R_C, 6)),
		w_comp_res					=> std_logic_vector(to_unsigned((OMEGA_C-4), 4)),
		w_upd_scal_exp_chng_int		=> std_logic_vector(to_unsigned((log2(T_INC_C)-4), 4)),
		w_upd_scal_exp_init_param	=> std_logic_vector(to_unsigned((V_MIN_C+6), 4)),
		w_upd_scal_exp_final_param	=> std_logic_vector(to_unsigned((V_MIN_C+6), 4)),
		w_exp_off_table_flag		=> iif(W_EXP_OFF_TABL_FLAG_G, "1", "0"),
		w_init_method				=> (others => W_INIT_TYPE_G),
		w_init_table_flag			=> iif(W_INIT_TABL_FLAG_G, "1", "0"),
		w_init_res					=> iif(W_INIT_TYPE_G = '1', std_logic_vector(to_unsigned(Q_C, 5)), "00000"),
		total_width					=> 40
	);
	
	-- Record "Predictor Metadata" structure (Table 5-5)
	constant MDATA_PRED_C : mdata_pred_t := (
		primary						=> MDATA_PRED_PRIMARY_C,
		weight_tables				=> MDATA_PRED_WEIGHT_TABLES_C,
		quantization				=> MDATA_PRED_QUANT_C,
		smpl_repr					=> MDATA_PRED_SMPL_REPR_C,
		total_width					=> MDATA_PRED_PRIMARY_C.total_width+MDATA_PRED_WEIGHT_TABLES_C'total_width+MDATA_PRED_QUANT_C'total_width+MDATA_PRED_SMPL_REPR_C'total_width
	);

begin

end Behaviour;