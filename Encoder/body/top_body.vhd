--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		09/06/2021
--------------------------------------------------------------------------------
-- IP name:		top_body
--
-- Description: Defines the body part of the compressed image
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

entity top_body is
	generic (
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G		: std_logic_vector(1 downto 0)
	);
	port (
		clock_i	  : in std_logic
	);
end top_body;

architecture Behaviour of top_body is	

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
		clock_i : in  std_logic
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
		clock_i	  : in std_logic;
		
		err_lim_i : in  err_lim_t;
		err_lim_o : out err_lim_t
	);

	i_metadata_encod : metadata_encod
	generic map(
		ENCODER_TYPE_G		   => ENCODER_TYPE_G,
		ACCU_INIT_TABLE_FLAG_G => ACCU_INIT_TABLE_FLAG_G
	)
	port map(
		clock_i : in std_logic
	);

end Behaviour;