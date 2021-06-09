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
use work.param_image.all;
use work.utils_image.all;

use work.param_predictor.all;
use work.types_predictor.all;

use work.types_encoder.all;
use work.utils_encoder.all;

entity metadata_pred is
	generic (
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G			: std_logic_vector(1 downto 0);
		-- 1: Full prediction mode, 0: Reduced prediction mode
		PREDICT_MODE_G			: std_logic;
		-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
		LSUM_TYPE_G				: std_logic_vector(1 downto 0);
		-- 1: Custom weight init, 0: Default weight init
		W_INIT_TYPE_G			: std_logic;
		-- 1: enabled, 0: disabled
		PER_ERR_LIM_UPD_G		: std_logic;
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G		: std_logic_vector(1 downto 0);
		-- 1: band-dependent, 0: band-independent (for both absolute and relative error limit assignments)
		ABS_ERR_BAND_TYPE_G		: std_logic;
		REL_ERR_BAND_TYPE_G		: std_logic;
		-- Flag to add the "Weight Initialization Table"
		W_INIT_TABL_FLAG_G		: std_logic;
		-- Flag to add the "Weight Exponent Offset Table"
		W_EXP_OFF_TABL_FLAG_G	: std_logic;
		-- Flag to add the "Damping Table"
		DAMP_TABLE_FLAG_G		: std_logic;
		-- Flag to add the "Offset Table"
		OFFSET_TABLE_FLAG_G		: std_logic
	);
	port (
		clock_i			: in  std_logic;		
		err_lim_i		: in  err_lim_t;
		
		md_pred_width_o	: out integer;
		md_pred_data_o	: out unsigned
	);
end metadata_pred;

architecture Behaviour of metadata_pred is	
	-- Creation of the weight initialization table (TO BE REVISED!)
	function create_w_init_table(flag_in : std_logic) return std_logic_vector is
		variable w_init_table_v	: std_logic_vector(1023 downto 0);
		variable pointer_v		: integer := 0;
		variable padding_bits_v	: integer;
	begin
		if (flag_in = '1') then			
			for i in 0 to (NZ_C-1) loop
				for j in 0 to (Cz_C-1) loop
					w_init_table_v(pointer_v+Q_C-1 downto pointer_v) := std_logic_vector(LAMBDA_C(j));
					pointer_v := pointer_v + Q_C;
				end loop;
			end loop;
		else
			return x"FFFF";
		end if;
	
		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		w_init_table_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(w_init_table_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return w_init_table_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_w_init_table;
	
	-- Creation of the weight exponent offset table (TO BE REVISED!)
	function create_w_exp_off_table(flag_in : std_logic) return std_logic_vector is
		variable w_exp_off_table_v	: std_logic_vector(1023 downto 0);
		variable pointer_v			: integer := 0;
		variable padding_bits_v		: integer;
	begin
		if (flag_in = '1') then			
			for i in 0 to (NZ_C-1) loop
				if (PREDICT_MODE_G = '1') then
					w_exp_off_table_v(pointer_v+4-1 downto pointer_v) := std_logic_vector(to_unsigned(C_C, 4));
					pointer_v := pointer_v + 4;
				end if;

				for j in 1 to Pz_C loop
					w_exp_off_table_v(pointer_v+4-1 downto pointer_v) := std_logic_vector(to_unsigned(Ci_C, 4));
					pointer_v := pointer_v + 4;
				end loop;
			end loop;
		else
			return x"FFFF";
		end if;		
	
		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		w_exp_off_table_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(w_exp_off_table_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return w_exp_off_table_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_w_exp_off_table;
	
	-- Creation of the Absolute Error Limit Values subblock
	function create_abs_err_lim_val_subblock(band_type_in : std_logic) return std_logic_vector is
		variable abs_err_lim_val_v	: std_logic_vector(1023 downto 0);
		variable pointer_v			: integer := 0;
		variable padding_bits_v		: integer;
	begin
		if (band_type_in = '1') then	-- band-dependent
			for i in 0 to (NZ_C-1) loop
				abs_err_lim_val_v(pointer_v+DA_C-1 downto pointer_v) := std_logic_vector(to_unsigned(err_lim_i.abs_arr(i), DA_C));
				pointer_v := pointer_v + DA_C;
			end loop;
		else							-- band-independent
			abs_err_lim_val_v(DA_C-1 downto 0) := std_logic_vector(to_unsigned(err_lim_i.abs_c, DA_C));
			pointer_v := pointer_v + DA_C;
		end if;
		
		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		abs_err_lim_val_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(abs_err_lim_val_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return abs_err_lim_val_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_abs_err_lim_val_subblock;
	
	-- Creation of the Relative Error Limit Values subblock
	function create_rel_err_lim_val_subblock(band_type_in : std_logic) return std_logic_vector is
		variable rel_err_lim_val_v	: std_logic_vector(1023 downto 0);
		variable pointer_v			: integer := 0;
		variable padding_bits_v		: integer;
	begin
		if (band_type_in = '1') then	-- band-dependent
			for i in 0 to (NZ_C-1) loop
				rel_err_lim_val_v(pointer_v+DR_C-1 downto pointer_v) := std_logic_vector(to_unsigned(err_lim_i.rel_arr(i), DR_C));
				pointer_v := pointer_v + DR_C;
			end loop;
		else							-- band-independent
			rel_err_lim_val_v(DR_C-1 downto 0) := std_logic_vector(to_unsigned(err_lim_i.rel_c, DR_C));
			pointer_v := pointer_v + DR_C;
		end if;
		
		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		rel_err_lim_val_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(rel_err_lim_val_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return rel_err_lim_val_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_rel_err_lim_val_subblock;
	
	-- Creation of the Damping Table subblock
	function create_damp_table_subblock return std_logic_vector is
		variable damp_table_v	: std_logic_vector(1023 downto 0);
		variable pointer_v		: integer := 0;
		variable padding_bits_v	: integer;
	begin
		for i in 0 to (NZ_C-1) loop
			damp_table_v(pointer_v+THETA_C-1 downto pointer_v) := std_logic_vector(to_unsigned(FI_AR_C(i), THETA_C));
			pointer_v := pointer_v + THETA_C;
		end loop;

		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		damp_table_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(damp_table_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return damp_table_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_damp_table_subblock;

	-- Creation of the Offset Table subblock
	function create_offset_table_subblock return std_logic_vector is
		variable offset_table_v	: std_logic_vector(1023 downto 0);
		variable pointer_v		: integer := 0;
		variable padding_bits_v	: integer;
	begin
		for i in 0 to (NZ_C-1) loop
			offset_table_v(pointer_v+THETA_C-1 downto pointer_v) := std_logic_vector(to_unsigned(PSI_AR_C(i), THETA_C));
			pointer_v := pointer_v + THETA_C;
		end loop;

		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		offset_table_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(offset_table_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return offset_table_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_offset_table_subblock;
	
	-- Record "Sample Representative" sub-structure from "Predictor Metadata" (Table 5-12)
	constant MDATA_PRED_SMPL_REPR_C : mdata_pred_smpl_repr_t := (
		reserved_1					=> (others => '0'),
		smpl_repr_resolution		=> std_logic_vector(to_unsigned(THETA_C, 3)),
		reserved_2					=> (others => '0'),
		band_var_damp_flag			=> (others => check_array_pos_same(FI_AR_C)),
		damp_table_flag				=> (others => DAMP_TABLE_FLAG_G),
		reserved_3					=> (others => '0'),
		fixed_damp_value			=> iif(check_array_pos_same(FI_AR_C) = '0', std_logic_vector(to_unsigned(FI_AR_C(0), 4)), "0000"),
		reserved_4					=> (others => '0'),
		band_var_offset_flag		=> (others => check_array_pos_same(PSI_AR_C)),
		offset_table_flag			=> (others => OFFSET_TABLE_FLAG_G),
		reserved_5					=> (others => '0'),
		fixed_offset_value			=> iif(check_array_pos_same(PSI_AR_C) = '0', std_logic_vector(to_unsigned(PSI_AR_C(0), 4)), "0000"),
		damp_table_subblock			=> create_damp_table_subblock,
		offset_table_subblock		=> create_offset_table_subblock,
		total_width					=> 24 + get_length(create_damp_table_subblock) + get_length(create_offset_table_subblock)
	);

	-- Record "Relative Error Limit" sub-structure from "Predictor Metadata" (Table 5-11)
	constant MDATA_PRED_REL_ERR_LIM_C : mdata_pred_rel_err_limit_t := (
		reserved_1					=> (others => '0'),
		rel_err_limit_assig_meth	=> (others => REL_ERR_BAND_TYPE_G),
		reserved_2					=> (others => '0'),
		rel_err_limit_bit_depth		=> std_logic_vector(to_unsigned(DR_C, 4)),
		rel_err_limit_val_subblock	=> create_rel_err_lim_val_subblock(REL_ERR_BAND_TYPE_G),
		total_width					=> 8 + get_length(create_rel_err_lim_val_subblock(REL_ERR_BAND_TYPE_G))
	);

	-- Record "Absolute Error Limit" sub-structure from "Predictor Metadata" (Table 5-10)
	constant MDATA_PRED_ABS_ERR_LIM_C : mdata_pred_abs_err_limit_t := (
		reserved_1					=> (others => '0'),
		abs_err_limit_assig_meth	=> (others => ABS_ERR_BAND_TYPE_G),
		reserved_2					=> (others => '0'),
		abs_err_limit_bit_depth		=> std_logic_vector(to_unsigned(DA_C, 4)),
		abs_err_limit_val_subblock	=> create_abs_err_lim_val_subblock(ABS_ERR_BAND_TYPE_G),
		total_width					=> 8 + get_length(create_abs_err_lim_val_subblock(ABS_ERR_BAND_TYPE_G))
	);
	
	-- Record "Error Limit Update Period" sub-structure from "Predictor Metadata" (Table 5-9)
	constant MDATA_PRED_ERR_LIM_UPD_PER_C : mdata_pred_err_limit_upd_period_t := (
		reserved_1					=> (others => '0'),
		per_upd_flag				=> (others => PER_ERR_LIM_UPD_G),
		reserved_2					=> (others => '0'),
		upd_period_exp				=> iif(PER_ERR_LIM_UPD_G = '1', std_logic_vector(to_unsigned(U_C, 4)), "0000"),
		total_width					=> 8
	);
	
	-- Record "Quantization" sub-structure from "Predictor Metadata" (Table 5-8)
	constant MDATA_PRED_QUANT_C : mdata_pred_quant_t := (
		err_limit_upd_period		=> MDATA_PRED_ERR_LIM_UPD_PER_C,
		absol_err_limit				=> MDATA_PRED_ABS_ERR_LIM_C,
		relat_err_limit				=> MDATA_PRED_REL_ERR_LIM_C,
		total_width					=> MDATA_PRED_ERR_LIM_UPD_PER_C.total_width+MDATA_PRED_ABS_ERR_LIM_C.total_width+MDATA_PRED_REL_ERR_LIM_C.total_width
	);

	-- Record "Weight tables" sub-structure from "Predictor Metadata" (Table 5-7)
	constant MDATA_PRED_WEIGHT_TABLES_C : mdata_pred_weight_tables_t := (
		w_init_table				=> create_w_init_table(W_INIT_TABL_FLAG_G),
		w_exp_off_table				=> create_w_exp_off_table(W_EXP_OFF_TABL_FLAG_G),
		total_width					=> get_length(create_w_init_table(W_INIT_TABL_FLAG_G)) + get_length(create_w_exp_off_table(W_EXP_OFF_TABL_FLAG_G))
	);

	-- Record "Primary" sub-structure from "Predictor Metadata" (Table 5-6)
	constant MDATA_PRED_PRIMARY_C : mdata_pred_primary_t := (
		reserved_1					=> (others => '0'),
		smpl_repr_flag				=> iif(THETA_C > 0, "1", "0"),
		num_pred_bands				=> std_logic_vector(to_unsigned(P_C, 4)),
		pred_mode					=> (others => not PREDICT_MODE_G),	-- Documentation uses opposite logic as I do here
		w_exp_offset_flag			=> iif((Ci_C = 0) and (C_C = 0), "0", "1"),
		lsum_type					=> LSUM_TYPE_G,
		register_size				=> std_logic_vector(to_unsigned(Re_C, 6)),
		w_comp_res					=> std_logic_vector(to_unsigned(OMEGA_C-4, 4)),
		w_upd_scal_exp_chng_int		=> std_logic_vector(to_unsigned(log2(T_INC_C)-4, 4)),
		w_upd_scal_exp_init_param	=> std_logic_vector(to_unsigned(V_MIN_C+6, 4)),
		w_upd_scal_exp_final_param	=> std_logic_vector(to_unsigned(V_MIN_C+6, 4)),
		w_exp_off_table_flag		=> (others => W_EXP_OFF_TABL_FLAG_G),
		w_init_method				=> (others => W_INIT_TYPE_G),
		w_init_table_flag			=> (others => W_INIT_TABL_FLAG_G),
		w_init_res					=> iif(W_INIT_TYPE_G = '1', std_logic_vector(to_unsigned(Q_C, 5)), "00000"),
		total_width					=> 40
	);
	
	-- Record "Predictor Metadata" structure (Table 5-5)
	constant MDATA_PRED_C : mdata_pred_t := (
		primary						=> MDATA_PRED_PRIMARY_C,
		weight_tables				=> MDATA_PRED_WEIGHT_TABLES_C,
		quantization				=> MDATA_PRED_QUANT_C,
		smpl_repr					=> MDATA_PRED_SMPL_REPR_C,
		total_width					=> MDATA_PRED_PRIMARY_C.total_width+MDATA_PRED_WEIGHT_TABLES_C.total_width+MDATA_PRED_QUANT_C.total_width+MDATA_PRED_SMPL_REPR_C.total_width
	);

begin

	md_pred_width_o <= MDATA_PRED_C.total_width;
	md_pred_data_o	<= unsigned(serial_mdata_pred(MDATA_PRED_C));

end Behaviour;