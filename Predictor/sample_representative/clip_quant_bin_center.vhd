--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		clip_quant_bin_center
--
-- Description: Computes the clipped version of the quantizer bin center "s'z(t)"
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

use work.utils_predictor.all;

entity clip_quant_bin_center is
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
		
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"  (maximum error)
		data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"  (quantizer index)
		data_s1_o	: out signed(D_C-1 downto 0)	-- "s'z(t)" (clipped quantizer bin center)
	);
end clip_quant_bin_center;

architecture behavioural of clip_quant_bin_center is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_s1_s	: signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_clip_quant_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_s	<= '0';
				img_coord_s <= reset_img_coord;
			else
				enable_s	<= enable_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_clip_quant_delay;
	
	-- Clipped quantizer bin center value (s'z(t)) calculation	
	p_cl_quan_bin_cnt_calc : process(clock_i) is
		variable comp1_v : signed(D_C-1 downto 0) := (others => '0');
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v	  := (others => '0');
				data_s1_s <= (others => '0');
			else
				if (enable_i = '1') then
					comp1_v	  := resize(n2_C * data_merr_i + n1_C, D_C);
					data_s1_s <= clip(data_s3_i + resize(data_quant_i*comp1_v, D_C), to_signed(SMPL_LIMIT_G.min, D_C), to_signed(SMPL_LIMIT_G.max, D_C));
				end if;
			end if;
		end if;
	end process p_cl_quan_bin_cnt_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_s1_o	<= data_s1_s;
end behavioural;