--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		scaled_diff
--
-- Description: Computes the scaled difference between sˆz(t) and the nearest
--				endpoint
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

entity scaled_diff is
	generic (
		SMPL_LIMIT_G	: smpl_lim_t
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		
		enable_i		: in  std_logic;
		enable_o		: out std_logic;
		img_coord_i		: in  img_coord_t;
		img_coord_o		: out img_coord_t;
		
		data_s3_i		: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i		: in  signed(D_C-1 downto 0);	-- "mz(t)" (maximum error)
		data_sc_diff_o	: out signed(D_C-1 downto 0)	-- "θz(t)" (scaled difference)
	);
end scaled_diff;

architecture behavioural of scaled_diff is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_sc_diff_s : signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_scaled_diff_delay : process(clock_i) is
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
	end process p_scaled_diff_delay;
	
	-- Scaled difference value (θz(t)) calculation	
	p_sc_diff_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v : signed(D_C-1 downto 0) := (others => '0');
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v := (others => '0');
				comp2_v := (others => '0');
				comp3_v := (others => '0');
				data_sc_diff_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.t = 0) then
						data_sc_diff_s <= work.utils_image.min(resize(data_s3_i - to_signed(SMPL_LIMIT_G.min, D_C), D_C), resize(to_signed(SMPL_LIMIT_G.max, D_C) - data_s3_i, D_C));
					else
						comp1_v := resize(data_s3_i - to_signed(SMPL_LIMIT_G.min, D_C) + data_merr_i, D_C);
						comp2_v := resize(to_signed(SMPL_LIMIT_G.max, D_C) - data_s3_i + data_merr_i, D_C);
						comp3_v := resize(n2_C * data_merr_i + n1_C, D_C);
						data_sc_diff_s <= work.utils_image.min(round_down(comp1_v, comp3_v), round_down(comp2_v, comp3_v));
					end if;
				end if;
			end if;
		end if;
	end process p_sc_diff_calc;

	-- Outputs
	enable_o		<= enable_s;
	img_coord_o		<= img_coord_s;
	data_sc_diff_o	<= data_sc_diff_s;
end behavioural;