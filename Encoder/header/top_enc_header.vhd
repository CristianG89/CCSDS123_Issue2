--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		09/06/2021
--------------------------------------------------------------------------------
-- IP name:		top_enc_header
--
-- Description: Defines the header part of the compressed image
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_predictor.all;

use work.types_encoder.all;
use work.comp_encoder.all;

entity top_enc_header is
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
		-- 00: Sample-Adaptive Entropy, 01: Hybrid Entropy, 10: Block-Adaptive Entropy
		ENCODER_TYPE_G			: std_logic_vector(1 downto 0);
		-- User Defined Data
		UDEF_DATA_G				: std_logic_vector(7 downto 0);
		-- Array with values -> 00: unsigned integer, 01: signed integer, 10: float
		SUPL_TABLE_TYPE_G		: supl_table_type_t;
		-- Array with values -> From 0 to 15 (check Table 3-1)
		SUPL_TABLE_PURPOSE_G	: supl_table_purpose_t;
		-- Array with values -> 00: zero-dimensional, 01: one-dimensional, 10: two-dimensional-zx, 11: two-dimensional-yx
		SUPL_TABLE_STRUCT_G		: supl_table_struct_t;
		-- Array with values -> Suplementary User-Defined Data
		SUPL_TABLE_UDATA_G		: supl_table_udata_t;
		-- Flag to add the "Weight Initialization Table"
		W_INIT_TABL_FLAG_G		: std_logic;
		-- Flag to add the "Weight Exponent Offset Table"
		W_EXP_OFF_TABL_FLAG_G	: std_logic;
		-- Flag to add the "Damping Table"
		DAMP_TABLE_FLAG_G		: std_logic;
		-- Flag to add the "Offset Table"
		OFFSET_TABLE_FLAG_G		: std_logic;
		-- Flag to add the "Accumulator Initialization Table"
		ACCU_INIT_TABLE_FLAG_G	: std_logic
	);
	port (
		clock_i				: in  std_logic;
		err_lim_i			: in  err_lim_t;
		
		enc_header_width_o	: out integer;
		enc_header_data_o	: out unsigned(1023 downto 0)
	);
end top_enc_header;

architecture Behaviour of top_enc_header is
	signal md_img_width_s	: integer := 0;
	signal md_img_data_s	: unsigned(1023 downto 0) := (others => '0');

	signal md_pred_width_s	: integer := 0;
	signal md_pred_data_s	: unsigned(1023 downto 0) := (others => '0');

	signal md_enc_width_s	: integer := 0;
	signal md_enc_data_s	: unsigned(1023 downto 0) := (others => '0');

begin
	i_metadata_img : metadata_img
	generic map(
		SMPL_ORDER_G		 => SMPL_ORDER_G,
		FIDEL_CTRL_TYPE_G	 => FIDEL_CTRL_TYPE_G,
		ENCODER_TYPE_G		 => ENCODER_TYPE_G,
		UDEF_DATA_G			 => UDEF_DATA_G,
		SUPL_TABLE_TYPE_G	 => SUPL_TABLE_TYPE_G,
		SUPL_TABLE_PURPOSE_G => SUPL_TABLE_PURPOSE_G,
		SUPL_TABLE_STRUCT_G	 => SUPL_TABLE_STRUCT_G,
		SUPL_TABLE_UDATA_G	 => SUPL_TABLE_UDATA_G
	)
	port map(
		md_img_width_o		 => md_img_width_s,
		md_img_data_o		 => md_img_data_s
	);

	i_metadata_pred : metadata_pred
	generic map(
		SMPL_ORDER_G		  => SMPL_ORDER_G,
		PREDICT_MODE_G		  => PREDICT_MODE_G,
		LSUM_TYPE_G			  => LSUM_TYPE_G,
		W_INIT_TYPE_G		  => W_INIT_TYPE_G,
		PER_ERR_LIM_UPD_G	  => PER_ERR_LIM_UPD_G,
		FIDEL_CTRL_TYPE_G	  => FIDEL_CTRL_TYPE_G,
		ABS_ERR_BAND_TYPE_G	  => ABS_ERR_BAND_TYPE_G,
		REL_ERR_BAND_TYPE_G	  => REL_ERR_BAND_TYPE_G,
		W_INIT_TABL_FLAG_G	  => W_INIT_TABL_FLAG_G,
		W_EXP_OFF_TABL_FLAG_G => W_EXP_OFF_TABL_FLAG_G,
		DAMP_TABLE_FLAG_G	  => DAMP_TABLE_FLAG_G,
		OFFSET_TABLE_FLAG_G	  => OFFSET_TABLE_FLAG_G
	)
	port map(
		clock_i				=> clock_i,
		err_lim_i			=> err_lim_i,
		
		md_pred_width_o		=> md_pred_width_s,
		md_pred_data_o		=> md_pred_data_s
	);

	i_metadata_encod : metadata_encod
	generic map(
		ENCODER_TYPE_G		   => ENCODER_TYPE_G,
		ACCU_INIT_TABLE_FLAG_G => ACCU_INIT_TABLE_FLAG_G
	)
	port map(
		clock_i				=> clock_i,
		
		md_enc_width_o		=> md_enc_width_s,
		md_enc_data_o		=> md_enc_data_s
	);
	
	-- Output signals
	enc_header_width_o	<= md_enc_width_s + md_pred_width_s + md_img_width_s;
	enc_header_data_o	<= (enc_header_data_o'length-1 downto enc_header_width_o => '0') &
							md_enc_data_s(md_enc_width_s-1 downto 0) & md_pred_data_s(md_pred_width_s-1 downto 0) & md_img_data_s(md_img_width_s-1 downto 0);

end Behaviour;