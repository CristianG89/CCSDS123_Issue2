library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;

-- Package Declaration Section
package comp_predictor is
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Predictor (top) module
	------------------------------------------------------------------------------------------------------------------------------
	component top_predictor is
		generic (
			-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
			FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0);
			LSUM_TYPE_G		: std_logic_vector(1 downto 0);	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
			PREDICT_MODE_G	: std_logic;	-- 1: Full prediction mode, 0: Reduced prediction mode
			W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
		);
		port (
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;

			enable_i		: in  std_logic;
			enable_o		: out std_logic;
			
			img_coord_i		: in  img_coord_t;
			img_coord_o		: out img_coord_t;
			
			data_s0_i		: in  signed(D_C-1 downto 0);	-- "sz(t)" (original sample)
			data_mp_quan_o	: out unsigned(D_C-1 downto 0)	-- "δz(t)" (mapped quantizer index)
		);
	end component top_predictor;
	
	component adder is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i 	: in  std_logic;

			img_coord_i	: in  img_coord_t;
			data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)" (original sample)
			data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
			data_res_o	: out signed(D_C-1 downto 0)	-- "/\z(t)" (prediction residual)
		);
	end component adder;

	component shift_register is
		generic (
			DATA_SIZE_G	: integer;
			REG_SIZE_G	: integer
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;

			data_i		: in  signed(DATA_SIZE_G-1 downto 0);
			data_o		: out signed(DATA_SIZE_G-1 downto 0)
		);
	end component shift_register;

	------------------------------------------------------------------------------------------------------------------------------
	-- Quantizer module
	------------------------------------------------------------------------------------------------------------------------------
	component quantizer is
		generic (
			-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
			FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
		);
		port (
			clock_i		 : in  std_logic;
			reset_i		 : in  std_logic;
			enable_i 	 : in  std_logic;
			
			img_coord_i	 : in  img_coord_t;		
			data_s3_i	 : in  signed(D_C-1 downto 0); -- "s^z(t)" (predicted sample)
			data_res_i	 : in  signed(D_C-1 downto 0); -- "/\z(t)" (prediction residual)
			
			data_merr_o	 : out signed(D_C-1 downto 0); -- "mz(t)" (maximum error)
			data_quant_o : out signed(D_C-1 downto 0)  -- "qz(t)" (quantizer index)
		);
	end component quantizer;

	component fidelity_ctrl is
		generic (
			-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
			FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i 	: in  std_logic;
			
			data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
			data_merr_o	: out signed(D_C-1 downto 0)	-- "mz(t)" (maximum error)
		);
	end component fidelity_ctrl;

	------------------------------------------------------------------------------------------------------------------------------
	-- Mapper module
	------------------------------------------------------------------------------------------------------------------------------
	component mapper is
		port (
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_s3_i		: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
			data_merr_i		: in  signed(D_C-1 downto 0);	-- "mz(t)" (maximum error)
			data_quant_i	: in  signed(D_C-1 downto 0);	-- "qz(t)" (quantizer index)
			data_mp_quan_o	: out unsigned(D_C-1 downto 0)	-- "δz(t)" (mapped quantizer index)
		);
	end component mapper;

	component scaled_diff is
		port (
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			
			data_s3_i		: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
			data_merr_i		: in  signed(D_C-1 downto 0);	-- "mz(t)" (maximum error)
			data_sc_diff_o	: out signed(D_C-1 downto 0)	-- "θz(t)" (scaled difference)
		);
	end component scaled_diff;

	------------------------------------------------------------------------------------------------------------------------------
	-- Sample Representative module
	------------------------------------------------------------------------------------------------------------------------------
	component sample_representative is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			img_coord_i	: in  img_coord_t;
			data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"	 (maximum error)
			data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"   (quantizer index)
			data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)"	 (original sample)
			data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)"  (predicted sample)
			data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)"	 (high-resolution predicted sample)

			data_s1_o	: out signed(D_C-1 downto 0);	-- "s'z(t)"  (clipped quantizer bin center)
			data_s2_o	: out signed(D_C-1 downto 0)	-- "s''z(t)" (sample representative)
		);
	end component sample_representative;

	component dbl_res_smpl_repr is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;	

			data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"	(maximum error)
			data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"	(quantizer index)		
			data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)"	(high-resolution predicted sample)
			data_s1_i	: in  signed(D_C-1 downto 0);	-- "s'z(t)"	(clipped quantizer bin center)
			data_s5_o	: out signed(D_C-1 downto 0)	-- "s~''z(t)" (double-resolution sample representative)
		);
	end component dbl_res_smpl_repr;

	component clip_quant_bin_center is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
			data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)" (maximum error)
			data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)" (quantizer index)
			data_s1_o	: out signed(D_C-1 downto 0)	-- "s'z(t)" (clipped quantizer bin center)
		);
	end component clip_quant_bin_center;

	------------------------------------------------------------------------------------------------------------------------------
	-- Prediction module (and its submodules)
	------------------------------------------------------------------------------------------------------------------------------
	component prediction is
		generic (
			LSUM_TYPE_G		: std_logic_vector(1 downto 0);	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
			PREDICT_MODE_G	: std_logic;	-- 1: Full prediction mode, 0: Reduced prediction mode
			W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			img_coord_i : in  img_coord_t;
			data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)" (original sample)
			data_s1_i	: in  signed(D_C-1 downto 0);	-- "s'z(t)"	 (clipped quantizer bin center)
			data_s2_i	: in  signed(D_C-1 downto 0);	-- "s''z(t)" (sample representative)
			
			data_s3_o	: out signed(D_C-1 downto 0);	-- "s^z(t)"	 (predicted sample)
			data_s6_o	: out signed(Re_C-1 downto 0)	-- "s)z(t)"	 (high-resolution predicted sample)
		);
	end component prediction;

	component predicted_sample is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;

			data_s4_i	: in  signed(D_C-1 downto 0);	-- "s~z(t)" (double-resolution predicted sample)
			data_s3_o	: out signed(D_C-1 downto 0)	-- "s^z(t)"	(predicted sample)
		);
	end component predicted_sample;

	component dbl_res_pred_smpl is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			img_coord_i	: in  img_coord_t;
			data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)"	(original sample)
			data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)" (high-resolution predicted sample)
			data_s4_o	: out signed(D_C-1 downto 0)	-- "s~z(t)" (double-resolution predicted sample)
		);
	end component dbl_res_pred_smpl;

	component high_res_pred_smpl is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;

			data_pre_cldiff_i : in signed(D_C-1 downto 0);	-- "d^z(t)" (predicted central local difference)
			data_lsum_i	: in  signed(D_C-1 downto 0);		-- "σz(t)"  (local sum)
			data_s6_o	: out signed(Re_C-1 downto 0)		-- "s)z(t)" (high-resolution predicted sample)
		);
	end component high_res_pred_smpl;

	component pred_central_local_diff is
		port (
			clock_i		 : in std_logic;
			reset_i		 : in std_logic;
			enable_i	 : in std_logic;
			
			weight_vect_i: in array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0); -- "Wz(t)" (weight vector)
			ldiff_vect_i : in array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0);		 -- "Uz(t)" (local difference vector)
			
			data_pred_cldiff_o : out signed(D_C-1 downto 0)		-- "d^z(t)" (predicted central local difference)
		);
	end component pred_central_local_diff;

	component weights_vector is
		generic (
			W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
		);
		port (
			clock_i			: in  std_logic;
			reset_i			: in  std_logic;
			enable_i		: in  std_logic;
			
			img_coord_i		: in  img_coord_t;
			data_w_exp_i	: in  signed(D_C-1 downto 0);				-- "p(t)"  (weight update scaling exponent)
			data_pred_err_i : in  signed(D_C-1 downto 0);				-- "ez(t)" (double-resolution prediction error)
			ldiff_vect_i	: in  array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0);		-- "Uz(t)" (local difference vector)
			weight_vect_o	: out array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0)	-- "Wz(t)" (weight vector)
		);
	end component weights_vector;

	component weight_upd_scal_exp is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			img_coord_i	: in  img_coord_t;
			data_w_exp_o: out signed(D_C-1 downto 0)	-- "p(t)" (weight update scaling exponent)
		);
	end component weight_upd_scal_exp;

	component dbl_res_pred_error is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			data_s1_i	: in  signed(D_C-1 downto 0);		-- "s'z(t)"	(clipped quantizer bin center)
			data_s4_i	: in  signed(D_C-1 downto 0);		-- "s~z(t)"	(double-resolution predicted sample)
			data_pred_err_o : out signed(D_C-1 downto 0)	-- "ez(t)"	(double-resolution prediction error)
		);
	end component dbl_res_pred_error;

	component local_diff_vector is
		generic (
			PREDICT_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;
			enable_i	: in  std_logic;
			
			ldiff_pos_i	: in  ldiff_pos_t;
			ldiff_vect_o: out array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0) -- "Uz(t)" (local difference vector)
		);
	end component local_diff_vector;

	component local_diff is
		generic (
			PREDICT_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
		);
		port (
			clock_i		  : in  std_logic;
			reset_i		  : in  std_logic;
			enable_i	  : in  std_logic;
			
			img_coord_i	  : in  img_coord_t;
			data_lsum_i	  : in  signed(D_C-1 downto 0);
			data_s2_pos_i : in  s2_pos_t;
			ldiff_pos_o	  : out ldiff_pos_t
		);
	end component local_diff;

	component local_sum is
		generic (
			LSUM_TYPE_G	 : std_logic_vector(1 downto 0)	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
		);
		port (
			clock_i		 : in  std_logic;
			reset_i		 : in  std_logic;
			enable_i 	 : in  std_logic;
			
			img_coord_i	 : in  img_coord_t;
			data_s2_pos_i: in  s2_pos_t;
			data_lsum_o	 : out signed(D_C-1 downto 0)		-- "σz(t)" (Local sum)
		);
	end component local_sum;

	component sample_store is
		port (
			clock_i	  : in  std_logic;
			reset_i	  : in  std_logic;

			enable_i  : in  std_logic;
			data_s2_i : in  signed(D_C-1 downto 0);

			data_s2_pos_o : out s2_pos_t
		);
	end component sample_store;

end package comp_predictor;