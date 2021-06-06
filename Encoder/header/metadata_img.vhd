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
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G		: std_logic_vector(1 downto 0);
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G	: std_logic_vector(1 downto 0);
		-- 00: Sample-Adaptive Entropy, 01: Hybrid Entropy, 10: Block-Adaptive Entropy
		ENCODER_TYPE_G		: std_logic_vector(1 downto 0);
		UDEF_DATA_G			: std_logic_vector(7 downto 0);
		-- Array with values -> 00: unsigned integer, 01: signed integer, 10: float
		SUPL_TABLE_TYPE_G	: supl_table_type_t;
		-- Array with values -> From 0 to 15 (check Table 3-1)
		SUPL_TABLE_PURPOSE_G: supl_table_purpose_t;
		-- Array with values -> 00: zero-dimensional, 01: one-dimensional, 10: two-dimensional-zx, 11: two-dimensional-yx
		SUPL_TABLE_STRUCT_G	: supl_table_struct_t;
		SUPL_TABLE_UDATA_G	: supl_table_udata_t
	);
	port (
		clock_i : in  std_logic
	);
end metadata_img;

architecture Behaviour of metadata_img is
	function get_supl_tables_length(supl_tables_in : mdata_img_supl_info_arr_t) return integer is
		variable supl_tables_length_v : integer := 0;
	begin
		for i in 0 to (supl_tables_in'length-1) loop
			supl_tables_length_v := supl_tables_length_v + supl_tables_in(i).total_width;
		end loop;
		
		return supl_tables_length_v;
	end function get_supl_tables_length;
	
	function create_tdata_subblock(tdata_type_in : std_logic_vector; tdata_struct_in : std_logic_vector) return std_logic_vector is
		variable tdata_subblock_v : std_logic_vector(1023 downto 0);
		variable pointer_v		  : integer := 0;
		variable padding_bits_v	  : integer;
	begin
		if ((tdata_type_in = "00") or (tdata_type_in = "01")) then	-- signed or unsigned table types
			
			tdata_subblock_v(4 downto 0) := std_logic_vector(to_unsigned(DI_C, 5));

			case tdata_struct_in is
				when "00" =>	-- 00: zero-dimensional
					
				when "01" =>	-- 01: one-dimensional
				
				when "10" =>	-- 10: two-dimensional-zx
				
				when others =>	-- 11: two-dimensional-yx
				
			end case;
			
		elsif (tdata_type_in = "10") then		-- float table type
		
		else	-- NON-acceptable table type
			return x"FFFF";
		end if;		
	
		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		tdata_subblock_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(tdata_subblock_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return tdata_subblock_v(padding_bits_v+pointer_v-1 downto 0);
		
	end function create_tdata_subblock;
	
	function create_supl_tables(num_tables_in : integer) return mdata_img_supl_info_arr_t is
		variable supl_tables_v : mdata_img_supl_info_arr_t(0 to num_tables_in-1);
	begin
		for i in 0 to (num_tables_in-1) loop
			supl_tables_v(i).table_type			 := SUPL_TABLE_TYPE_G(i);
			supl_tables_v(i).reserved_1			 := (others => '0');
			supl_tables_v(i).table_purpose		 := std_logic_vector(to_unsigned(SUPL_TABLE_PURPOSE_G(i), 4));
			supl_tables_v(i).reserved_2			 := (others => '0');
			supl_tables_v(i).table_structure	 := SUPL_TABLE_STRUCT_G(i);
			supl_tables_v(i).reserved_3			 := (others => '0');
			supl_tables_v(i).supl_user_def_data	 := SUPL_TABLE_UDATA_G(i);
			supl_tables_v(i).table_data_subblock := create_tdata_subblock(SUPL_TABLE_TYPE_G(i), SUPL_TABLE_STRUCT_G(i));
			supl_tables_v(i).total_width		 := 16 + supl_tables_v(i).table_data_subblock'length;
		end loop;
		
		return supl_tables_v;
	end function create_supl_tables;
	
	-- Record "Supplementary Information" sub-structure from "Image Metadata" (Table 5-4)
	constant MDATA_IMG_SUPL_INFO_ARR_C : mdata_img_supl_info_arr_t(0 to TAU_C-1) := create_supl_tables(TAU_C);

	-- Record "Essential" sub-structure from "Image Metadata" (Table 5-3)
	constant MDATA_IMG_ESSEN_C : mdata_img_essential_t := (
		udef_data			=> UDEF_DATA_G,
		x_size				=> std_logic_vector(to_unsigned(NX_C, 16)),
		y_size				=> std_logic_vector(to_unsigned(NY_C, 16)),
		z_size				=> std_logic_vector(to_unsigned(NZ_C, 16)),
		smpl_type			=> (others => SAMPLE_TYPE_C),
		reserved_1			=> (others => '0'),
		larg_dyn_rng_flag	=> iif(D_C > 16, "1", "0"),
		dyn_range			=> std_logic_vector(to_unsigned(D_C, 4)),
		smpl_enc_order		=> (others => iif(SMPL_ORDER_G = BSQ_C, '1', '0')),
		sub_frm_intlv_depth => iif(SMPL_ORDER_G = BSQ_C, x"0000", std_logic_vector(to_unsigned(NZ_C, 16))),
		reserved_2			=> (others => '0'),
		out_word_size		=> std_logic_vector(to_unsigned(B_C, 3)),
		entropy_coder_type	=> ENCODER_TYPE_G,
		reserved_3			=> (others => '0'),
		quant_fidel_ctrl_mth=> FIDEL_CTRL_TYPE_G,
		reserved_4			=> (others => '0'),
		supl_info_table_cnt	=> std_logic_vector(to_unsigned(TAU_C, 4)),
		total_width			=> 96	-- The previous fields are a total of: 12 bytes * 8 bits/byte = 96 bits
	);
	
	-- Record "Image Metadata" structure (Table 5-2)
	constant MDATA_IMG_C : mdata_img_t := (
		essential			=> MDATA_IMG_ESSEN_C,
		supl_info_arr		=> MDATA_IMG_SUPL_INFO_ARR_C,
		total_width			=> MDATA_IMG_ESSEN_C.total_width + get_supl_tables_length(MDATA_IMG_SUPL_INFO_ARR_C)
	);

begin

end Behaviour;