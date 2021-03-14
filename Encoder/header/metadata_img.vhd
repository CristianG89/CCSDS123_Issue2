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

entity metadata_img is
	generic (
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
	);
	port (
	);
end metadata_img;

architecture Behaviour of metadata_img is

	-- Record "Essential" sub-structure from "Image Metadata" (Table 5-3)
	constant MDATA_IMG_ESSEN_C : mdata_img_essential_t := (
		udef_data			=> "C8",
		x_size				=> std_logic_vector(to_unsigned(NX_C, 16)),
		y_size				=> std_logic_vector(to_unsigned(NY_C, 16)),
		z_size				=> std_logic_vector(to_unsigned(NZ_C, 16)),
		smpl_type			=> SAMPLE_TYPE_C,
		reserved_1			=> (others => '0'),
		larg_dyn_rng_flag	=> (D_C > 16),
		dyn_range			=> std_logic_vector(to_unsigned(D_C, 4)),
		smpl_enc_order		=> SMPL_ENC_ORDER_C,
		sub_frm_intlv_depth : std_logic_vector(15 downto 0);
		reserved_2			=> (others => '0'),
		out_word_size		=> std_logic_vector(to_unsigned(B_C, 3)),
		entropy_coder_type	: std_logic_vector(1 downto 0);
		reserved_3			=> (others => '0'),
		quant_fidel_ctrl_mth=> FIDEL_CTRL_TYPE_G,
		reserved_4			=> (others => '0'),
		supl_info_table_cnt	=> std_logic_vector(to_unsigned(TAU_C, 4)),
		total_width			=> 96
	);

begin

end Behaviour;