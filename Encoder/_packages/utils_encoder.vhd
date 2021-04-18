library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_encoder.all;
use work.types_encoder.all;

-- Package Declaration Section
package utils_encoder is

	-- ENTROPY CODER METADATA	
	pure function serial_mdata_enc_block_adapt(mdata_enc_in : in mdata_enc_block_adapt_t) return std_logic_vector;
	pure function serial_mdata_enc_hybrid(mdata_enc_in : in mdata_enc_hybrid_t) return std_logic_vector;
	pure function serial_mdata_enc_smpl_adapt(mdata_enc_in : in mdata_enc_smpl_adapt_t) return std_logic_vector;
	pure function serial_mdata_enc(mdata_enc_in : in mdata_enc_t) return std_logic_vector;

	-- PREDICTOR METADATA
	pure function serial_mdata_pred_smpl_repr(mdata_pred_in : in mdata_pred_smpl_repr_t) return std_logic_vector;
	pure function serial_mdata_pred_rel_err_limit(mdata_pred_in : in mdata_pred_rel_err_limit_t) return std_logic_vector;
	pure function serial_mdata_pred_abs_err_limit(mdata_pred_in : in mdata_pred_abs_err_limit_t) return std_logic_vector;
	pure function serial_mdata_pred_err_limit_upd_period(mdata_pred_in : in mdata_pred_err_limit_upd_period_t) return std_logic_vector;
	pure function serial_mdata_pred_quant(mdata_pred_in : in mdata_pred_quant_t) return std_logic_vector;
	pure function serial_mdata_pred_weight_tables(mdata_pred_in : in mdata_pred_weight_tables_t) return std_logic_vector;
	pure function serial_mdata_pred_primary(mdata_pred_in : in mdata_pred_primary_t) return std_logic_vector;
	pure function serial_mdata_pred(mdata_pred_in : in mdata_pred_t) return std_logic_vector;
	
	-- IMAGE METADATA
	pure function serial_mdata_img_supl_info(mdata_img_in : in mdata_img_supl_info_t) return std_logic_vector;
	pure function serial_mdata_img_supl_info_arr(mdata_img_arr_in : in mdata_img_supl_info_arr_t) return std_logic_vector;
	pure function serial_mdata_img_essential(mdata_img_in : in mdata_img_essential_t) return std_logic_vector;
	pure function serial_mdata_img(mdata_img_in : in mdata_img_t) return std_logic_vector;
	
	-- TOP ENCODER HEADER
	pure function serial_enc_header(enc_header_in : in enc_header_t) return std_logic_vector;
	
	-- OTHER FUNCTIONS
	pure function check_pos_low_entr_table(threshold_in : in integer) return integer;
	
end package utils_encoder;

-- Package Body Section
package body utils_encoder is

	-------------------------------------------------------------------------------------------------------
	-- ENTROPY CODER METADATA
	-------------------------------------------------------------------------------------------------------
	
	-- Serializes record "mdata_enc_block_adapt_t" to "std_logic_vector" (from Table 5-15)
	pure function serial_mdata_enc_block_adapt(mdata_enc_in : in mdata_enc_block_adapt_t) return std_logic_vector is
		variable ser_mdata_enc_in_v : std_logic_vector(mdata_enc_in.total_width-1 downto 0);
	begin
		ser_mdata_enc_in_v(0 downto 0)	:= mdata_enc_in.reserved_1;
		ser_mdata_enc_in_v(2 downto 1)	:= mdata_enc_in.block_size;
		ser_mdata_enc_in_v(3 downto 3)	:= mdata_enc_in.restr_code_opt_flag;
		ser_mdata_enc_in_v(mdata_enc_in.total_width-1 downto 4) := mdata_enc_in.ref_smpl_interval;
		
		return ser_mdata_enc_in_v;
	end function;
	
	-- Serializes record "mdata_enc_hybrid_t" to "std_logic_vector" (from Table 5-14)
	pure function serial_mdata_enc_hybrid(mdata_enc_in : in mdata_enc_hybrid_t) return std_logic_vector is
		variable ser_mdata_enc_in_v : std_logic_vector(mdata_enc_in.total_width-1 downto 0);
	begin
		ser_mdata_enc_in_v(4 downto 0)	:= mdata_enc_in.unary_len_limit;
		ser_mdata_enc_in_v(7 downto 5)	:= mdata_enc_in.resc_count_size;
		ser_mdata_enc_in_v(10 downto 8)	:= mdata_enc_in.init_count_exp;
		ser_mdata_enc_in_v(mdata_enc_in.total_width-1 downto 11) := (others => '0');	-- reserved_1
		
		return ser_mdata_enc_in_v;
	end function;

	-- Serializes record "mdata_enc_smpl_adapt_t" to "std_logic_vector" (from Table 5-13)
	pure function serial_mdata_enc_smpl_adapt(mdata_enc_in : in mdata_enc_smpl_adapt_t) return std_logic_vector is
		variable ser_mdata_enc_in_v : std_logic_vector(mdata_enc_in.total_width-1 downto 0);
	begin
		ser_mdata_enc_in_v(4 downto 0)	 := mdata_enc_in.unary_len_limit;
		ser_mdata_enc_in_v(7 downto 5)	 := mdata_enc_in.resc_count_size;
		ser_mdata_enc_in_v(10 downto 8)	 := mdata_enc_in.init_count_exp;
		ser_mdata_enc_in_v(14 downto 11) := mdata_enc_in.accu_init_const;
		ser_mdata_enc_in_v(15 downto 15) := mdata_enc_in.accu_init_table_flag;
		ser_mdata_enc_in_v(mdata_enc_in.total_width-1 downto 16) := mdata_enc_in.accu_init_table;
		
		return ser_mdata_enc_in_v;
	end function;
	
	-- Serializes record "mdata_enc_t" to "std_logic_vector" (Additional Table)
	pure function serial_mdata_enc(mdata_enc_in : in mdata_enc_t) return std_logic_vector is
		variable ser_mdata_enc_in_v : std_logic_vector(mdata_enc_in.total_width-1 downto 0);
	begin
		ser_mdata_enc_in_v := mdata_enc_in.enc_subtype_data;

		return ser_mdata_enc_in_v;
	end function;

	-------------------------------------------------------------------------------------------------------
	-- PREDICTOR METADATA
	-------------------------------------------------------------------------------------------------------

	-- Serializes record "mdata_pred_smpl_repr_t" to "std_logic_vector" (from Table 5-12)
	pure function serial_mdata_pred_smpl_repr(mdata_pred_in : in mdata_pred_smpl_repr_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(4 downto 0)		:= mdata_pred_in.reserved_1;
		ser_mdata_pred_in_v(7 downto 5)		:= mdata_pred_in.smpl_repr_resolution;
		ser_mdata_pred_in_v(8 downto 8)		:= mdata_pred_in.reserved_2;
		ser_mdata_pred_in_v(9 downto 9)		:= mdata_pred_in.band_var_damp_flag;
		ser_mdata_pred_in_v(10 downto 10)	:= mdata_pred_in.damp_table_flag;
		ser_mdata_pred_in_v(11 downto 11)	:= mdata_pred_in.reserved_3;
		ser_mdata_pred_in_v(15 downto 12)	:= mdata_pred_in.fixed_damp_value;
		ser_mdata_pred_in_v(16 downto 16)	:= mdata_pred_in.reserved_4;
		ser_mdata_pred_in_v(17 downto 17)	:= mdata_pred_in.band_var_offset_flag;
		ser_mdata_pred_in_v(18 downto 18)	:= mdata_pred_in.offset_table_flag;
		ser_mdata_pred_in_v(19 downto 19)	:= mdata_pred_in.reserved_5;
		ser_mdata_pred_in_v(23 downto 20)	:= mdata_pred_in.fixed_offset_value;
		ser_mdata_pred_in_v(24+mdata_pred_in.damp_table_subblock'length-1 downto 24)						:= mdata_pred_in.damp_table_subblock;
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto 24+mdata_pred_in.damp_table_subblock'length) := mdata_pred_in.offset_table_subblock;
		
		return ser_mdata_pred_in_v;
	end function;
	
	-- Serializes record "mdata_pred_rel_err_limit_t" to "std_logic_vector" (from Table 5-11)
	pure function serial_mdata_pred_rel_err_limit(mdata_pred_in : in mdata_pred_rel_err_limit_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(0 downto 0)	:= mdata_pred_in.reserved_1;
		ser_mdata_pred_in_v(1 downto 1)	:= mdata_pred_in.rel_err_limit_assig_meth;
		ser_mdata_pred_in_v(3 downto 2)	:= mdata_pred_in.reserved_2;
		ser_mdata_pred_in_v(7 downto 4)	:= mdata_pred_in.rel_err_limit_bit_depth;
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto 8) := mdata_pred_in.rel_err_limit_val_subblock;
		
		return ser_mdata_pred_in_v;
	end function;
	
	-- Serializes record "mdata_pred_abs_err_limit_t" to "std_logic_vector" (from Table 5-10)
	pure function serial_mdata_pred_abs_err_limit(mdata_pred_in : in mdata_pred_abs_err_limit_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(0 downto 0)	:= mdata_pred_in.reserved_1;
		ser_mdata_pred_in_v(1 downto 1)	:= mdata_pred_in.abs_err_limit_assig_meth;
		ser_mdata_pred_in_v(3 downto 2)	:= mdata_pred_in.reserved_2;
		ser_mdata_pred_in_v(7 downto 4)	:= mdata_pred_in.abs_err_limit_bit_depth;
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto 8) := mdata_pred_in.abs_err_limit_val_subblock;
		
		return ser_mdata_pred_in_v;
	end function;
	
	-- Serializes record "mdata_pred_err_limit_upd_period_t" to "std_logic_vector" (from Table 5-9)
	pure function serial_mdata_pred_err_limit_upd_period(mdata_pred_in : in mdata_pred_err_limit_upd_period_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(0 downto 0)	:= mdata_pred_in.reserved_1;
		ser_mdata_pred_in_v(1 downto 1)	:= mdata_pred_in.per_upd_flag;
		ser_mdata_pred_in_v(3 downto 2)	:= mdata_pred_in.reserved_2;
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto 4) := mdata_pred_in.upd_period_exp;
		
		return ser_mdata_pred_in_v;
	end function;

	-- Serializes record "mdata_pred_quant_t" to "std_logic_vector" (from Table 5-8)
	pure function serial_mdata_pred_quant(mdata_pred_in : in mdata_pred_quant_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(mdata_pred_in.err_limit_upd_period.total_width-1 downto 0)																						 := serial_mdata_pred_err_limit_upd_period(mdata_pred_in.err_limit_upd_period);
		ser_mdata_pred_in_v(mdata_pred_in.err_limit_upd_period.total_width+mdata_pred_in.absol_err_limit.total_width-1 downto mdata_pred_in.err_limit_upd_period.total_width):= serial_mdata_pred_abs_err_limit(mdata_pred_in.absol_err_limit);
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto mdata_pred_in.err_limit_upd_period.total_width+mdata_pred_in.absol_err_limit.total_width)					 := serial_mdata_pred_rel_err_limit(mdata_pred_in.relat_err_limit);
		
		return ser_mdata_pred_in_v;
	end function;

	-- Serializes record "mdata_pred_weight_tables_t" to "std_logic_vector" (from Table 5-7)
	pure function serial_mdata_pred_weight_tables(mdata_pred_in : in mdata_pred_weight_tables_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(mdata_pred_in.w_init_table'length-1 downto 0)						 := mdata_pred_in.w_init_table;
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto mdata_pred_in.w_init_table'length):= mdata_pred_in.w_exp_off_table;

		return ser_mdata_pred_in_v;
	end function;
	
	-- Serializes record "mdata_pred_primary_t" to "std_logic_vector" (from Table 5-6)
	pure function serial_mdata_pred_primary(mdata_pred_in : in mdata_pred_primary_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(0 downto 0)	  := mdata_pred_in.reserved_1;
		ser_mdata_pred_in_v(1 downto 1)	  := mdata_pred_in.smpl_repr_flag;
		ser_mdata_pred_in_v(5 downto 2)	  := mdata_pred_in.num_pred_bands;
		ser_mdata_pred_in_v(6 downto 6)	  := mdata_pred_in.pred_mode;
		ser_mdata_pred_in_v(7 downto 7)	  := mdata_pred_in.w_exp_offset_flag;
		ser_mdata_pred_in_v(9 downto 8)	  := mdata_pred_in.lsum_type;
		ser_mdata_pred_in_v(15 downto 10) := mdata_pred_in.register_size;
		ser_mdata_pred_in_v(19 downto 16) := mdata_pred_in.w_comp_res;
		ser_mdata_pred_in_v(23 downto 20) := mdata_pred_in.w_upd_scal_exp_chng_int;
		ser_mdata_pred_in_v(27 downto 24) := mdata_pred_in.w_upd_scal_exp_init_param;
		ser_mdata_pred_in_v(31 downto 28) := mdata_pred_in.w_upd_scal_exp_final_param;
		ser_mdata_pred_in_v(32 downto 32) := mdata_pred_in.w_exp_off_table_flag;
		ser_mdata_pred_in_v(33 downto 33) := mdata_pred_in.w_init_method;
		ser_mdata_pred_in_v(34 downto 34) := mdata_pred_in.w_init_table_flag;
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto 35):= mdata_pred_in.w_init_res;
		
		return ser_mdata_pred_in_v;
	end function;

	-- Serializes record "mdata_pred_t" to "std_logic_vector" (from Table 5-5)
	pure function serial_mdata_pred(mdata_pred_in : in mdata_pred_t) return std_logic_vector is
		variable ser_mdata_pred_in_v : std_logic_vector(mdata_pred_in.total_width-1 downto 0);
	begin
		ser_mdata_pred_in_v(mdata_pred_in.primary.total_width-1 downto 0)																																						 := serial_mdata_pred_primary(mdata_pred_in.primary);
		ser_mdata_pred_in_v(mdata_pred_in.primary.total_width+mdata_pred_in.weight_tables.total_width-1 downto mdata_pred_in.primary.total_width)																				 := serial_mdata_pred_weight_tables(mdata_pred_in.weight_tables);
		ser_mdata_pred_in_v(mdata_pred_in.primary.total_width+mdata_pred_in.weight_tables.total_width+mdata_pred_in.quantization.total_width-1 downto mdata_pred_in.primary.total_width+mdata_pred_in.weight_tables.total_width) := serial_mdata_pred_quant(mdata_pred_in.quantization);
		ser_mdata_pred_in_v(mdata_pred_in.total_width-1 downto mdata_pred_in.primary.total_width+mdata_pred_in.weight_tables.total_width+mdata_pred_in.quantization.total_width)												 := serial_mdata_pred_smpl_repr(mdata_pred_in.smpl_repr);
		
		return ser_mdata_pred_in_v;
	end function;

	-------------------------------------------------------------------------------------------------------
	-- IMAGE METADATA
	-------------------------------------------------------------------------------------------------------
	
	-- Serializes record "mdata_img_supl_info_t" to "std_logic_vector" (from Table 5-4)
	pure function serial_mdata_img_supl_info(mdata_img_in : in mdata_img_supl_info_t) return std_logic_vector is
		variable ser_mdata_img_in_v : std_logic_vector(mdata_img_in.total_width-1 downto 0);
	begin
		ser_mdata_img_in_v(1 downto 0)	 := mdata_img_in.table_type;
		ser_mdata_img_in_v(3 downto 2)	 := mdata_img_in.reserved_1;
		ser_mdata_img_in_v(7 downto 4)	 := mdata_img_in.table_purpose;
		ser_mdata_img_in_v(8 downto 8)	 := mdata_img_in.reserved_2;
		ser_mdata_img_in_v(10 downto 9)	 := mdata_img_in.table_structure;
		ser_mdata_img_in_v(11 downto 11) := mdata_img_in.reserved_3;
		ser_mdata_img_in_v(15 downto 12) := mdata_img_in.supl_user_def_data;
		ser_mdata_img_in_v(mdata_img_in.total_width-1 downto 16):= mdata_img_in.table_data_subblock;
		
		return ser_mdata_img_in_v;
	end function;

	-- Serializes array of record "mdata_img_supl_info_t" to "std_logic_vector" (from Table 5-4)
	pure function serial_mdata_img_supl_info_arr(mdata_img_arr_in : in mdata_img_supl_info_arr_t) return std_logic_vector is
		variable ser_mdata_img_in_v : std_logic_vector(mdata_img_arr_in'length*mdata_img_arr_in(0).total_width-1 downto 0);
	begin		
		for i in 0 to (mdata_img_arr_in'length-1) loop
			ser_mdata_img_in_v((i+1)*mdata_img_arr_in(i).total_width-1 downto i*mdata_img_arr_in(i).total_width) := serial_mdata_img_supl_info(mdata_img_arr_in(i));
		end loop;
		
		return ser_mdata_img_in_v;
	end function;

	-- Serializes record "mdata_img_essential_t" to "std_logic_vector" (from Table 5-3)
	pure function serial_mdata_img_essential(mdata_img_in : in mdata_img_essential_t) return std_logic_vector is
		variable ser_mdata_img_in_v : std_logic_vector(mdata_img_in.total_width-1 downto 0);
	begin
		ser_mdata_img_in_v(7 downto 0)	 := mdata_img_in.udef_data;
		ser_mdata_img_in_v(23 downto 8)	 := mdata_img_in.x_size;
		ser_mdata_img_in_v(39 downto 24) := mdata_img_in.y_size;
		ser_mdata_img_in_v(55 downto 40) := mdata_img_in.z_size;
		ser_mdata_img_in_v(56 downto 56) := mdata_img_in.smpl_type;
		ser_mdata_img_in_v(57 downto 57) := mdata_img_in.reserved_1;
		ser_mdata_img_in_v(58 downto 58) := mdata_img_in.larg_dyn_rng_flag;
		ser_mdata_img_in_v(62 downto 59) := mdata_img_in.dyn_range;
		ser_mdata_img_in_v(63 downto 63) := mdata_img_in.smpl_enc_order;
		ser_mdata_img_in_v(79 downto 64) := mdata_img_in.sub_frm_intlv_depth;
		ser_mdata_img_in_v(81 downto 80) := mdata_img_in.reserved_2;
		ser_mdata_img_in_v(84 downto 82) := mdata_img_in.out_word_size;
		ser_mdata_img_in_v(86 downto 85) := mdata_img_in.entropy_coder_type;
		ser_mdata_img_in_v(87 downto 87) := mdata_img_in.reserved_3;
		ser_mdata_img_in_v(89 downto 88) := mdata_img_in.quant_fidel_ctrl_mth;
		ser_mdata_img_in_v(91 downto 90) := mdata_img_in.reserved_4;
		ser_mdata_img_in_v(mdata_img_in.total_width-1 downto 92):= mdata_img_in.supl_info_table_cnt;
		
		return ser_mdata_img_in_v;

	end function;

	-- Serializes record "mdata_img_t" to "std_logic_vector" (from Table 5-2)
	pure function serial_mdata_img(mdata_img_in : in mdata_img_t) return std_logic_vector is
		variable ser_mdata_img_in_v : std_logic_vector(mdata_img_in.total_width-1 downto 0);
	begin
		ser_mdata_img_in_v(mdata_img_in.essential.total_width-1 downto 0)						 := serial_mdata_img_essential(mdata_img_in.essential);
		ser_mdata_img_in_v(mdata_img_in.total_width-1 downto mdata_img_in.essential.total_width) := serial_mdata_img_supl_info_arr(mdata_img_in.supl_info_arr);

		return ser_mdata_img_in_v;
	end function;
	
	-------------------------------------------------------------------------------------------------------
	-- TOP ENCODER HEADER
	-------------------------------------------------------------------------------------------------------
	
	-- Serializes record "enc_header_t" to "std_logic_vector" (from Table 5-1)
	pure function serial_enc_header(enc_header_in : in enc_header_t) return std_logic_vector is
		variable ser_enc_header_in_v : std_logic_vector(enc_header_in.total_width-1 downto 0);
	begin
		ser_enc_header_in_v(enc_header_in.mdata_img.total_width-1 downto 0)																			:= serial_mdata_img(enc_header_in.mdata_img);
		ser_enc_header_in_v(enc_header_in.mdata_img.total_width+enc_header_in.mdata_pred.total_width-1 downto enc_header_in.mdata_img.total_width)	:= serial_mdata_pred(enc_header_in.mdata_pred);
		ser_enc_header_in_v(enc_header_in.total_width-1 downto enc_header_in.mdata_img.total_width+enc_header_in.mdata_pred.total_width)			:= serial_mdata_enc(enc_header_in.mdata_enc);	
		
		return ser_enc_header_in_v;
	end function;
	
	-------------------------------------------------------------------------------------------------------
	-- OTHER FUNCTIONS
	-------------------------------------------------------------------------------------------------------
	
	-- Returns the position from the Low-Entropy codes table, where the incoming threshold belongs to
	pure function check_pos_low_entr_table(threshold_in : in integer) return integer is
		variable position_v : integer := -1;
		variable max_loop_v : integer := LOW_ENTR_CODES_C.threshold'length-2;
	begin
		for i in 0 to max_loop_v loop
			if ((threshold_in <= LOW_ENTR_CODES_C.threshold(i)) and (threshold_in > LOW_ENTR_CODES_C.threshold(i+1))) then
				position_v := i;
				exit;
			else
				if (i = max_loop_v) then	-- Last iteration, so no need for "exit" command
					position_v := 15;
				end if;
			end if;
		end loop;
		
		return position_v;
	end function;

end package body utils_encoder;