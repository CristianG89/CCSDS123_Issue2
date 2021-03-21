--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		20/02/2021
--------------------------------------------------------------------------------
-- IP name:		metadata_img
--
-- Description: Defines the "Image Metadata" from compressed image header part
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.utils_image.all;

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;

entity metadata_img is
	generic (
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0);
		-- "00": Sample-Adaptive Entropy, "01": Hybrid Entropy, "10": Block-Adaptive Entropy
		ENCODER_TYPE_G	  : std_logic_vector(1 downto 0)
	);
	port (
		clock_i : in  std_logic
	);
end metadata_img;

architecture Behaviour of metadata_img is

	-- Record "Supplementary Information" sub-structure from "Image Metadata" (Table 5-4)
	constant MDATA_IMG_SUPL_INFO_C : mdata_img_supl_info_t := (
		table_type			=> "01",	-- "01": signed type
		reserved_1			=> (others => '0'),
		table_purpose		=> std_logic_vector(to_unsigned(1, 4)),		-- 1: offset
		reserved_2			=> (others => '0'),
		table_structure		=> "01",	-- "01": one-dimensional
		reserved_3			=> (others => '0'),
		supl_user_def_data	=> x"8",
		table_data_subblock	=> "0",
		total_width			=> 17
	);
	constant MDATA_IMG_SUPL_INFO_ARR_C : mdata_img_supl_info_arr_t(0 to TAU_C-1) := (
		0 => MDATA_IMG_SUPL_INFO_C
	);

	-- Record "Essential" sub-structure from "Image Metadata" (Table 5-3)
	constant MDATA_IMG_ESSEN_C : mdata_img_essential_t := (
		udef_data			=> x"C8",
		x_size				=> std_logic_vector(to_unsigned(NX_C, 16)),
		y_size				=> std_logic_vector(to_unsigned(NY_C, 16)),
		z_size				=> std_logic_vector(to_unsigned(NZ_C, 16)),
		smpl_type			=> (others => SAMPLE_TYPE_C),
		reserved_1			=> (others => '0'),
		larg_dyn_rng_flag	=> iif(D_C > 16, "1", "0"),
		dyn_range			=> std_logic_vector(to_unsigned(D_C, 4)),
		smpl_enc_order		=> (others => SMPL_ENC_ORDER_C),
		sub_frm_intlv_depth => iif(SMPL_ENC_ORDER_C = '0', std_logic_vector(to_unsigned(NZ_C, 16)), x"0000"),
		reserved_2			=> (others => '0'),
		out_word_size		=> std_logic_vector(to_unsigned(B_C, 3)),
		entropy_coder_type	=> ENCODER_TYPE_G,
		reserved_3			=> (others => '0'),
		quant_fidel_ctrl_mth=> FIDEL_CTRL_TYPE_G,
		reserved_4			=> (others => '0'),
		supl_info_table_cnt	=> std_logic_vector(to_unsigned(TAU_C, 4)),
		total_width			=> 96	-- 12 bytes * 8 bits/byte = 96 bits
	);
	
	-- Record "Image Metadata" structure (Table 5-2)
	constant MDATA_IMG_C : mdata_img_t := (
		essential			=> MDATA_IMG_ESSEN_C,
		supl_info_arr		=> MDATA_IMG_SUPL_INFO_ARR_C,
		total_width			=> MDATA_IMG_ESSEN_C.total_width + MDATA_IMG_SUPL_INFO_ARR_C'length*MDATA_IMG_SUPL_INFO_C.total_width
	);

begin

end Behaviour;