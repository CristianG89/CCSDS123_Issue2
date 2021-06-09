--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		09/06/2021
--------------------------------------------------------------------------------
-- IP name:		top_enc_body
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
use work.types_image.all;

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;
use work.comp_encoder.all;

entity top_enc_body is
	generic (
		-- 00: Sample-Adaptive Entropy, 01: Hybrid Entropy, 10: Block-Adaptive Entropy
		ENCODER_TYPE_G	: std_logic_vector(1 downto 0)
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)" (mapped quantizer index)		
		codeword_o		: out unsigned(Umax_C+D_C-1 downto 0)	-- "Rk(j)" (codeword)
	);
end top_enc_body;

architecture Behaviour of top_enc_body is	
	signal codeword_s : unsigned(Umax_C+D_C-1 downto 0) := (others => '0');

begin
	g_enc_body_type : case ENCODER_TYPE_G generate
		when "00" =>
			i_smpl_adap_wrapper : smpl_adap_wrapper
			port map(
				clock_i			=> clock_i,
				reset_i			=> reset_i,
				enable_i		=> enable_i,
				
				img_coord_i		=> img_coord_i,
				data_mp_quan_i	=> data_mp_quan_i,
				codeword_o		=> codeword_s
			);

		when "01" =>
			i_hybrid_wrapper : hybrid_wrapper
			port map(
				clock_i			=> clock_i,
				reset_i			=> reset_i,
				enable_i		=> enable_i,
				
				img_coord_i		=> img_coord_i,
				data_mp_quan_i	=> data_mp_quan_i,
				rvd_codeword_o	=> codeword_s
			);
		
		-- when "10" =>		
		
		when others =>		-- No encoder type selected!
			codeword_s <= (others => '0');
			
	end generate g_enc_body_type;

	-- Output signals
	codeword_o <= codeword_s;
end Behaviour;