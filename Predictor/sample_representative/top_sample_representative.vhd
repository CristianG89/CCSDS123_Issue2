--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		sample_representative
--
-- Description: Computes the sample_representative "s''z(t)"
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

use work.param_predictor.all;
use work.types_predictor.all;
use work.utils_predictor.all;
use work.comp_predictor.all;

entity sample_representative is
	generic (
		SMPL_LIMIT_G : smpl_lim_t
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"	 (maximum error)
		data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"   (quantizer index)
		data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)"	 (original sample)
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)"  (predicted sample)
		data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)"	 (high-resolution predicted sample)

		data_s1_o	: out signed(D_C-1 downto 0);	-- "s'z(t)"  (clipped quantizer bin center)
		data_s2_o	: out signed(D_C-1 downto 0)	-- "s''z(t)" (sample representative)
	);
end sample_representative;

architecture behavioural of sample_representative is
	signal enable1_s		: std_logic := '0';
	signal enable2_s		: std_logic := '0';
	signal img_coord1_s		: img_coord_t := reset_img_coord;
	signal img_coord2_s		: img_coord_t := reset_img_coord;
	
	signal data_merr_prv_s	: signed(D_C-1 downto 0) := (others => '0');
	signal data_quant_prv_s	: signed(D_C-1 downto 0) := (others => '0');
	signal data_s1_s		: signed(D_C-1 downto 0) := (others => '0');
	signal data_s2_s		: signed(D_C-1 downto 0) := (others => '0');
	signal data_s5_s		: signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_smpl_repr_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_merr_prv_s	 <= (others => '0');
				data_quant_prv_s <= (others => '0');
			else
				data_merr_prv_s	 <= data_merr_i;
				data_quant_prv_s <= data_quant_i;
			end if;
		end if;
	end process p_smpl_repr_delay;
	
	i_clip_qua_bin_cnt : clip_quant_bin_center
	generic map(
		SMPL_LIMIT_G => SMPL_LIMIT_G
	)
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		
		enable_i	 => enable_i,
		enable_o	 => enable1_s,
		img_coord_i	 => img_coord_i,
		img_coord_o	 => img_coord1_s,
		
		data_s3_i	 => data_s3_i,
		data_merr_i	 => data_merr_i,
		data_quant_i => data_quant_i,
		data_s1_o	 => data_s1_s
	);

	i_dbl_res_smpl_repr : dbl_res_smpl_repr
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		
		enable_i	 => enable1_s,
		enable_o	 => enable2_s,
		img_coord_i	 => img_coord1_s,
		img_coord_o	 => img_coord2_s,

		data_merr_i	 => data_merr_prv_s,
		data_quant_i => data_quant_prv_s,
		data_s6_i	 => data_s6_i,
		data_s1_i	 => data_s1_s,
		data_s5_o	 => data_s5_s
	);

	-- Sample representative (s''z(t)) calculation
	p_smpl_repr_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s2_s <= (others => '0');
			else
				if (enable2_s = '1') then
					if (img_coord2_s.t = 0) then
						data_s2_s <= data_s0_i;
					else
						data_s2_s <= round_down(resize(data_s5_s+n1_C, D_C), resize(n2_C, D_C));
					end if;
				end if;
			end if;
		end if;
	end process p_smpl_repr_calc;

	-- Outputs
	enable_o	<= enable2_s;
	img_coord_o	<= img_coord2_s;
	data_s1_o	<= data_s1_s;
	data_s2_o	<= data_s2_s;
end behavioural;