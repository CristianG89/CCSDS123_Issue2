--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		06/06/2021
--------------------------------------------------------------------------------
-- IP name:		top_ccsds123_issue2
--
-- Description: Top entity for the whole CCSDS123 Issue 2 algorithm on VHDL
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;
use work.comp_image.all;

use work.param_predictor.all;
use work.types_predictor.all;
use work.utils_predictor.all;
use work.comp_predictor.all;

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;
use work.comp_encoder.all;
	
entity top_ccsds123_issue2 is
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
		-- Flag to add the "Weight Initialization Table"
		W_INIT_TABL_FLAG_G		: std_logic;
		-- Flag to add the "Weight Exponent Offset Table"
		W_EXP_OFF_TABL_FLAG_G	: std_logic;
		-- Flag to add the "Damping Table"
		DAMP_TABLE_FLAG_G		: std_logic;
		-- Flag to add the "Offset Table"
		OFFSET_TABLE_FLAG_G		: std_logic;
		-- Flag to add the "Accumulator Initialization Table"
		ACCU_INIT_TABLE_FLAG_G	: std_logic;
		-- User Defined Data
		UDEF_DATA_G				: std_logic_vector(7 downto 0);
		-- Array with values -> 00: unsigned integer, 01: signed integer, 10: float
		SUPL_TABLE_TYPE_G		: supl_table_type_t;
		-- Array with values -> From 0 to 15 (check Table 3-1)
		SUPL_TABLE_PURPOSE_G	: supl_table_purpose_t;
		-- Array with values -> 00: zero-dimensional, 01: one-dimensional, 10: two-dimensional-zx, 11: two-dimensional-yx
		SUPL_TABLE_STRUCT_G		: supl_table_struct_t;
		-- Array with values -> Suplementary User-Defined Data
		SUPL_TABLE_UDATA_G		: supl_table_udata_t
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		enable_i	: in  std_logic;
		err_lim_i	: in  err_lim_t;
		
		data_s0_i	: in  signed(D_C-1 downto 0)	-- "sz(t)" (original sample)
	);
end top_ccsds123_issue2;

architecture behavioural of top_ccsds123_issue2 is	
	------------------------------------------------------------------------------------------------------
	-- FUNCTIONS
	------------------------------------------------------------------------------------------------------	
	-- User chooses the prediction mode, unless NX_C=1, when only 'reduced prediction mode' can be used
	pure function set_predict_mode(desired_mode_in : std_logic) return std_logic is
	begin
		if (NX_C = 1) then
			return '0';		-- Reduced predicted mode
		else
			return desired_mode_in;
		end if;
	end function set_predict_mode;	
	
	-- Local sum update, according limitations (00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column)
	pure function set_lsum_type(lsum_type_in : std_logic_vector; predict_mode_in : std_logic) return std_logic_vector is
		variable lsum_type_v : std_logic_vector(1 downto 0);
	begin
		-- When Image has width NX=1, column-oriented local sums SHALL be used
		if (NX_C = 1) then
			if (lsum_type_in = "00") then
				lsum_type_v := "10";
			elsif (lsum_type_in = "01") then
				lsum_type_v := "11";
			else
				lsum_type_v	:= lsum_type_in;
			end if;
		-- Under "Full Prediction Mode", column-oriented are NOT SUGGESTED (lower priority than NX=1)
		elsif (predict_mode_in = '1') then
			if (lsum_type_in = "10") then
				lsum_type_v := "00";
			elsif (lsum_type_in = "11") then
				lsum_type_v := "01";
			else
				lsum_type_v	:= lsum_type_in;
			end if;
		else
			lsum_type_v	:= lsum_type_in;
		end if;
		
		return lsum_type_v;
	end function set_lsum_type;

	------------------------------------------------------------------------------------------------------
	-- DESIGN CONSTANTS
	------------------------------------------------------------------------------------------------------
	-- For the undefined case ("11"), automatically configured to use BSQ order as well...
	constant SMPL_ORDER_C	: std_logic_vector(1 downto 0) := iif(SMPL_ORDER_G = "11", BSQ_C, SMPL_ORDER_G);
	constant PREDICT_MODE_C : std_logic := set_predict_mode(PREDICT_MODE_G);
	constant LSUM_TYPE_C	: std_logic_vector(1 downto 0) := set_lsum_type(LSUM_TYPE_G, PREDICT_MODE_C);
	-- Periodic error limit updating is not permitted when BSQ encoding order is used
	constant PER_ERR_LIM_UPD_C : std_logic := iif(SMPL_ORDER_C /= BSQ_C, PER_ERR_LIM_UPD_G, '0');

	------------------------------------------------------------------------------------------------------
	-- SIGNALS
	------------------------------------------------------------------------------------------------------
	-- Enable and image coordinates to interconnect all sub-blocks
	signal enable_s			: std_logic := '0';
	signal img_coord1_s		: img_coord_t := reset_img_coord;
	signal img_coord2_s		: img_coord_t := reset_img_coord;
	signal err_lim1_s		: err_lim_t	  := reset_err_lim;
	signal err_lim2_s		: err_lim_t	  := reset_err_lim;
	
	signal data_mp_quan_s	: unsigned(D_C-1 downto 0)	:= (others => '0');
	
begin
	i_img_coord_err_ctrl : img_coord_err_ctrl
	generic map(
		SMPL_ORDER_G		=> SMPL_ORDER_C,
		FIDEL_CTRL_TYPE_G	=> FIDEL_CTRL_TYPE_G,
		ABS_ERR_BAND_TYPE_G	=> ABS_ERR_BAND_TYPE_G,
		REL_ERR_BAND_TYPE_G	=> REL_ERR_BAND_TYPE_G,
		PER_ERR_LIM_UPD_G	=> PER_ERR_LIM_UPD_C
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,

		handshake_i	=> enable_i,
		w_valid_i	=> '0',
		ready_o		=> open,
		
		err_lim_i	=> err_lim_i,
		err_lim_o	=> err_lim1_s,
		img_coord_o	=> img_coord1_s
	);
	
	i_top_predictor : top_predictor
	generic map(
		SMPL_ORDER_G		=> SMPL_ORDER_C,
		FIDEL_CTRL_TYPE_G	=> FIDEL_CTRL_TYPE_G,
		LSUM_TYPE_G			=> LSUM_TYPE_C,
		PREDICT_MODE_G		=> PREDICT_MODE_C,
		ABS_ERR_BAND_TYPE_G	=> ABS_ERR_BAND_TYPE_G,
		REL_ERR_BAND_TYPE_G	=> REL_ERR_BAND_TYPE_G,
		PER_ERR_LIM_UPD_G	=> PER_ERR_LIM_UPD_C,
		W_INIT_TYPE_G		=> W_INIT_TYPE_G
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,

		enable_i		=> enable_i,
		enable_o		=> enable_s,
		img_coord_i		=> img_coord1_s,
		img_coord_o		=> img_coord2_s,
		err_lim_i		=> err_lim1_s,
		err_lim_o		=> err_lim2_s,
		
		data_s0_i		=> data_s0_i,
		data_mp_quan_o	=> data_mp_quan_s
	);
	
	i_top_encoder : top_encoder
	generic map(
		SMPL_ORDER_G			=> SMPL_ORDER_G,
		PREDICT_MODE_G			=> PREDICT_MODE_G,
		LSUM_TYPE_G				=> LSUM_TYPE_G,
		W_INIT_TYPE_G			=> W_INIT_TYPE_G,
		PER_ERR_LIM_UPD_G		=> PER_ERR_LIM_UPD_G,
		FIDEL_CTRL_TYPE_G		=> FIDEL_CTRL_TYPE_G,
		ABS_ERR_BAND_TYPE_G		=> ABS_ERR_BAND_TYPE_G,
		REL_ERR_BAND_TYPE_G		=> REL_ERR_BAND_TYPE_G,
		ENCODER_TYPE_G			=> ENCODER_TYPE_G,
		UDEF_DATA_G				=> UDEF_DATA_G,
		SUPL_TABLE_TYPE_G		=> SUPL_TABLE_TYPE_G,
		SUPL_TABLE_PURPOSE_G	=> SUPL_TABLE_PURPOSE_G,
		SUPL_TABLE_STRUCT_G		=> SUPL_TABLE_STRUCT_G,
		SUPL_TABLE_UDATA_G		=> SUPL_TABLE_UDATA_G,
		W_INIT_TABL_FLAG_G		=> W_INIT_TABL_FLAG_G,
		W_EXP_OFF_TABL_FLAG_G	=> W_EXP_OFF_TABL_FLAG_G,
		DAMP_TABLE_FLAG_G		=> DAMP_TABLE_FLAG_G,
		OFFSET_TABLE_FLAG_G		=> OFFSET_TABLE_FLAG_G,
		ACCU_INIT_TABLE_FLAG_G	=> ACCU_INIT_TABLE_FLAG_G
	)
	port map(
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		enable_i		: in  std_logic;
		enable_o		: out std_logic;
		img_coord_i		: in  img_coord_t;
		img_coord_o		: out img_coord_t;
		
		err_lim_i		: in  err_lim_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0)	-- "?z(t)" (mapped quantizer index)
	);

	-- Output signals
	-- enable_o			<= enable5_s;
	-- img_coord_o		<= img_coord5_s;
	-- data_mp_quan_o	<= data_mp_quan_s;
end behavioural;