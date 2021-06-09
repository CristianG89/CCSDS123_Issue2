--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		25/02/2021
--------------------------------------------------------------------------------
-- IP name:		metadata_encod
--
-- Description: Defines the "Encoder Metadata" from compressed image header part
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils_image.all;
use work.param_image.all;

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;

entity metadata_encod is
	generic (
		-- "00": Sample-Adaptive Entropy, "01": Hybrid Entropy, "10": Block-Adaptive Entropy
		ENCODER_TYPE_G			: std_logic_vector(1 downto 0);
		-- Flag to add the "Accumulator Initialization Table"
		ACCU_INIT_TABLE_FLAG_G	: std_logic
	);
	port (
		clock_i			: in  std_logic;
		
		md_enc_width_o  : out integer;
		md_enc_data_o	: out unsigned(1023 downto 0)
	);
end metadata_encod;

architecture Behaviour of metadata_encod is
	-- Returns the length of the selected encoder
	function encoder_length(enc_type : in std_logic_vector; enc1 : in mdata_enc_smpl_adapt_t; enc2 : in mdata_enc_hybrid_t; enc3 : in mdata_enc_block_adapt_t) return integer is
		variable enc_length_v : integer;
	begin
		case enc_type is
            when "00" =>		-- "00": Sample-Adaptive Entropy
                enc_length_v := enc1.total_width;
				
            when "01" =>		-- "01": Hybrid Entropy
                enc_length_v := enc2.total_width;
				
            when "10" =>		-- "10": Block-Adaptive Entropy
                enc_length_v := enc3.total_width;
				
            when others =>
                enc_length_v := 0;
        end case;

		return enc_length_v;
	end function;
	
	-- Returns the serialized data of the selected encoder
	function select_encoder(enc_type : in std_logic_vector; enc1 : in mdata_enc_smpl_adapt_t; enc2 : in mdata_enc_hybrid_t; enc3 : in mdata_enc_block_adapt_t) return mdata_enc_t is
		variable sel_encoder_v : mdata_enc_t(enc_subtype_data(encoder_length(enc_type, enc1, enc2, enc3)-1 downto 0));
	begin
		case enc_type is
            when "00" =>		-- "00": Sample-Adaptive Entropy
                sel_encoder_v.enc_subtype_data	:= serial_mdata_enc_smpl_adapt(enc1);
				sel_encoder_v.total_width		:= enc1.total_width;
				
            when "01" =>		-- "01": Hybrid Entropy
                sel_encoder_v.enc_subtype_data	:= serial_mdata_enc_hybrid(enc2);
				sel_encoder_v.total_width		:= enc2.total_width;
				
            when "10" =>		-- "10": Block-Adaptive Entropy
                sel_encoder_v.enc_subtype_data	:= serial_mdata_enc_block_adapt(enc3);
				sel_encoder_v.total_width		:= enc3.total_width;
				
            when others =>
                sel_encoder_v.enc_subtype_data	:= (others => '0');
				sel_encoder_v.total_width		:= 0;
        end case;

		return sel_encoder_v;
	end function;

	-- Creation of the Accumulator Initialization Table subblock
	function create_accu_init_table_subblock return std_logic_vector is
		variable accu_init_table_v	: std_logic_vector(1023 downto 0);
		variable pointer_v			: integer := 0;
		variable padding_bits_v		: integer;
	begin
		for i in 0 to (NZ_C-1) loop
			accu_init_table_v(pointer_v+4-1 downto pointer_v) := std_logic_vector(to_unsigned(K2_AR_C(i), 4));
			pointer_v := pointer_v + 4;
		end loop;
		
		-- If necessary, fills with 0s until reach the next byte boundary
		padding_bits_v := pointer_v mod 8;
		accu_init_table_v(padding_bits_v+pointer_v-1 downto 0) := padding_bits(accu_init_table_v(pointer_v-1 downto 0), padding_bits_v, 0);
		
		return accu_init_table_v(padding_bits_v+pointer_v-1 downto 0);
	end function create_accu_init_table_subblock;
	
	-- Record "Block Adaptive Entropy" sub-structure from "Entropy Coder Metadata" (Table 5-15)
	constant MDATA_ENC_BLOCK_ADAPT_C : mdata_enc_block_adapt_t := (
		reserved_1				=> (others => '0'),
		block_size				=> std_logic_vector(to_unsigned(J_C, 2)),
		restr_code_opt_flag		=> iif((D_C <= 4) and (!!!!), "1", "0"),
		ref_smpl_interval		=> std_logic_vector(to_unsigned(Rs_C, 12)),
		total_width				=> 16
	);
	
	-- Record "Hybrid Entropy" sub-structure from "Entropy Coder Metadata" (Table 5-14)
	constant MDATA_ENC_HYBRID_C : mdata_enc_hybrid_t := (
		unary_len_limit			=> std_logic_vector(to_unsigned(Umax_C, 5)),
		resc_count_size			=> std_logic_vector(to_unsigned(Y_C-4, 3)),
		init_count_exp			=> std_logic_vector(to_unsigned(Yo_C, 3)),
		reserved_1				=> (others => '0'),
		total_width				=> 16
	);

	-- Record "Sample Adaptive Entropy" sub-structure from "Entropy Coder Metadata" (Table 5-13)
	constant MDATA_ENC_SMPL_ADAPT_C : mdata_enc_smpl_adapt_t := (
		unary_len_limit			=> std_logic_vector(to_unsigned(Umax_C, 5)),
		resc_count_size			=> std_logic_vector(to_unsigned(Y_C-4, 3)),
		init_count_exp			=> std_logic_vector(to_unsigned(Yo_C, 3)),
		accu_init_const			=> iif(K_C > 0, std_logic_vector(to_unsigned(K_C, 4)), "1111"),
		accu_init_table_flag	=> (others => ACCU_INIT_TABLE_FLAG_G),
		accu_init_table			=> create_accu_init_table_subblock,
		total_width				=> 16 + get_length(create_accu_init_table_subblock)
	);
	
	-- Record "Encoder Metadata" structure (Additional Table)
	constant MDATA_ENC_C : mdata_enc_t := select_encoder(ENCODER_TYPE_G, MDATA_ENC_SMPL_ADAPT_C, MDATA_ENC_HYBRID_C, MDATA_ENC_BLOCK_ADAPT_C);

begin

	md_enc_width_o	<= MDATA_ENC_C.total_width;
	md_enc_data_o	<= (md_enc_data_o'length-1 downto md_enc_width_o => '0') & unsigned(serial_mdata_enc(MDATA_ENC_C));

end Behaviour;