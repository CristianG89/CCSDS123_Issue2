library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package Declaration Section
package types_encoder is
	
	-------------------------------------------------------------------------------------------------------
	-- ENTROPY CODER METADATA
	-------------------------------------------------------------------------------------------------------
	
	-- Record "Block Adaptive Entropy" sub-structure from "Entropy Coder Metadata" (Table 5-15)
	type mdata_enc_block_adapt_t is record
		reserved_1				: std_logic_vector(0 downto 0);
		block_size				: std_logic_vector(1 downto 0);
		restr_code_opt_flag		: std_logic_vector(0 downto 0);
		ref_smpl_interval		: std_logic_vector(11 downto 0);
		total_width				: integer;
	end record mdata_enc_block_adapt_t;
	
	-- Record "Hybrid Entropy" sub-structure from "Entropy Coder Metadata" (Table 5-14)
	type mdata_enc_hybrid_t is record
		unary_len_limit			: std_logic_vector(4 downto 0);
		resc_count_size			: std_logic_vector(2 downto 0);
		init_count_exp			: std_logic_vector(2 downto 0);
		reserved_1				: std_logic_vector(4 downto 0);
		total_width				: integer;
	end record mdata_enc_hybrid_t;

	-- Record "Sample Adaptive Entropy" sub-structure from "Entropy Coder Metadata" (Table 5-13)
	type mdata_enc_smpl_adapt_t is record
		unary_len_limit			: std_logic_vector(4 downto 0);
		resc_count_size			: std_logic_vector(2 downto 0);
		init_count_exp			: std_logic_vector(2 downto 0);
		accu_init_const			: std_logic_vector(3 downto 0);
		accu_init_table_flag	: std_logic_vector(0 downto 0);
		accu_init_table			: std_logic_vector;
		total_width				: integer;
	end record mdata_enc_smpl_adapt_t;

	-- Record "Encoder Metadata" structure (Additional Table)
	type mdata_enc_t is record
		enc_subtype_data		: std_logic_vector;
		total_width				: integer;
	end record mdata_enc_t;

	-------------------------------------------------------------------------------------------------------
	-- PREDICTOR METADATA
	-------------------------------------------------------------------------------------------------------

	-- Record "Sample Representative" sub-structure from "Predictor Metadata" (Table 5-12)
	type mdata_pred_smpl_repr_t is record
		reserved_1					: std_logic_vector(4 downto 0);
		smpl_repr_resolution		: std_logic_vector(2 downto 0);
		reserved_2					: std_logic_vector(0 downto 0);
		band_var_damp_flag			: std_logic_vector(0 downto 0);
		damp_table_flag				: std_logic_vector(0 downto 0);
		reserved_3					: std_logic_vector(0 downto 0);
		fixed_damp_value			: std_logic_vector(3 downto 0);
		reserved_4					: std_logic_vector(0 downto 0);
		band_var_offset_flag		: std_logic_vector(0 downto 0);
		offset_table_flag			: std_logic_vector(0 downto 0);
		reserved_5					: std_logic_vector(0 downto 0);
		fixed_offset_value			: std_logic_vector(3 downto 0);
		damp_table_subblock			: std_logic_vector;
		offset_table_subblock		: std_logic_vector;
		total_width					: integer;
	end record mdata_pred_smpl_repr_t;
	
	-- Record "Relative Error Limit" sub-structure from "Predictor Metadata" (Table 5-11)
	type mdata_pred_rel_err_limit_t is record
		reserved_1						: std_logic_vector(0 downto 0);
		rel_err_limit_assig_meth		: std_logic_vector(0 downto 0);
		reserved_2						: std_logic_vector(1 downto 0);
		rel_err_limit_bit_depth			: std_logic_vector(3 downto 0);
		rel_err_limit_val_subblock		: std_logic_vector;
		total_width						: integer;
	end record mdata_pred_rel_err_limit_t;

	-- Record "Absolute Error Limit" sub-structure from "Predictor Metadata" (Table 5-10)
	type mdata_pred_abs_err_limit_t is record
		reserved_1						: std_logic_vector(0 downto 0);
		abs_err_limit_assig_meth		: std_logic_vector(0 downto 0);
		reserved_2						: std_logic_vector(1 downto 0);
		abs_err_limit_bit_depth			: std_logic_vector(3 downto 0);
		abs_err_limit_val_subblock		: std_logic_vector;
		total_width						: integer;
	end record mdata_pred_abs_err_limit_t;
	
	-- Record "Error Limit Update Period" sub-structure from "Predictor Metadata" (Table 5-9)
	type mdata_pred_err_limit_upd_period_t is record
		reserved_1					: std_logic_vector(0 downto 0);
		per_upd_flag				: std_logic_vector(0 downto 0);
		reserved_2					: std_logic_vector(1 downto 0);
		upd_period_exp				: std_logic_vector(3 downto 0);
		total_width					: integer;
	end record mdata_pred_err_limit_upd_period_t;
	
	-- Record "Quantization" sub-structure from "Predictor Metadata" (Table 5-8)
	type mdata_pred_quant_t is record
		err_limit_upd_period		: mdata_pred_err_limit_upd_period_t;
		absol_err_limit				: mdata_pred_abs_err_limit_t;
		relat_err_limit				: mdata_pred_rel_err_limit_t;
		total_width					: integer;
	end record mdata_pred_quant_t;
	
	-- Record "Weight tables" sub-structure from "Predictor Metadata" (Table 5-7)
	type mdata_pred_weight_tables_t is record
		w_init_table				: std_logic_vector;
		w_exp_off_table				: std_logic_vector;
		total_width					: integer;
	end record mdata_pred_weight_tables_t;
	
	-- Record "Primary" sub-structure from "Predictor Metadata" (Table 5-6)
	type mdata_pred_primary_t is record
		reserved_1					: std_logic_vector(0 downto 0);
		smpl_repr_flag				: std_logic_vector(0 downto 0);
		num_pred_bands				: std_logic_vector(3 downto 0);
		pred_mode					: std_logic_vector(0 downto 0);
		w_exp_offset_flag			: std_logic_vector(0 downto 0);
		lsum_type					: std_logic_vector(1 downto 0);
		register_size				: std_logic_vector(5 downto 0);
		w_comp_res					: std_logic_vector(3 downto 0);
		w_upd_scal_exp_chng_int		: std_logic_vector(3 downto 0);
		w_upd_scal_exp_init_param	: std_logic_vector(3 downto 0);
		w_upd_scal_exp_final_param	: std_logic_vector(3 downto 0);
		w_exp_off_table_flag		: std_logic_vector(0 downto 0);
		w_init_method				: std_logic_vector(0 downto 0);
		w_init_table_flag			: std_logic_vector(0 downto 0);
		w_init_res					: std_logic_vector(4 downto 0);
		total_width					: integer;
	end record mdata_pred_primary_t;

	-- Record "Predictor Metadata" structure (Table 5-5)
	type mdata_pred_t is record
		primary						: mdata_pred_primary_t;
		weight_tables				: mdata_pred_weight_tables_t;
		quantization				: mdata_pred_quant_t;
		smpl_repr					: mdata_pred_smpl_repr_t;
		total_width					: integer;
	end record mdata_pred_t;

	-------------------------------------------------------------------------------------------------------
	-- IMAGE METADATA
	-------------------------------------------------------------------------------------------------------
	
	-- Record "Supplementary Information" sub-structure from "Image Metadata" (Table 5-4)
	type mdata_img_supl_info_t is record
		table_type				 : std_logic_vector(1 downto 0);
		reserved_1				 : std_logic_vector(1 downto 0);
		table_purpose			 : std_logic_vector(3 downto 0);
		reserved_2				 : std_logic_vector(0 downto 0);
		table_structure			 : std_logic_vector(1 downto 0);
		reserved_3				 : std_logic_vector(0 downto 0);
		supl_user_def_data		 : std_logic_vector(3 downto 0);
		table_data_subblock		 : std_logic_vector;
		total_width				 : integer;
	end record mdata_img_supl_info_t;
	-- Array of "Supplementary Information" records
	type mdata_img_supl_info_arr_t is array(natural range <>) of mdata_img_supl_info_t;
	
	-- Record "Essential" sub-structure from "Image Metadata" (Table 5-3)
	type mdata_img_essential_t is record
		udef_data			: std_logic_vector(7 downto 0);
		x_size				: std_logic_vector(15 downto 0);
		y_size				: std_logic_vector(15 downto 0);
		z_size				: std_logic_vector(15 downto 0);
		smpl_type			: std_logic_vector(0 downto 0);
		reserved_1			: std_logic_vector(0 downto 0);
		larg_dyn_rng_flag	: std_logic_vector(0 downto 0);
		dyn_range			: std_logic_vector(3 downto 0);
		smpl_enc_order		: std_logic_vector(0 downto 0);
		sub_frm_intlv_depth : std_logic_vector(15 downto 0);
		reserved_2			: std_logic_vector(1 downto 0);
		out_word_size		: std_logic_vector(2 downto 0);
		entropy_coder_type	: std_logic_vector(1 downto 0);
		reserved_3			: std_logic_vector(0 downto 0);
		quant_fidel_ctrl_mth: std_logic_vector(1 downto 0);
		reserved_4			: std_logic_vector(1 downto 0);
		supl_info_table_cnt	: std_logic_vector(3 downto 0);
		total_width			: integer;
	end record mdata_img_essential_t;

	-- Record "Image Metadata" structure (Table 5-2)
	type mdata_img_t is record
		essential			: mdata_img_essential_t;
		supl_info_arr		: mdata_img_supl_info_arr_t;
		total_width			: integer;
	end record mdata_img_t;
	
	-------------------------------------------------------------------------------------------------------
	-- TOP ENCODER HEADER
	-------------------------------------------------------------------------------------------------------
	
	-- Record "Header" top structure (Table 5-1)
	type enc_header_t is record
		mdata_img			: mdata_img_t;
		mdata_pred			: mdata_pred_t;
		mdata_enc			: mdata_enc_t;
		total_width			: integer;
	end record enc_header_t;

end package types_encoder;