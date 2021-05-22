--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		high_res_pred_smpl
--
-- Description: High-resolution predicted sample value "s)z(t)" calculation
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

use work.types_predictor.all;
use work.utils_predictor.all;
use work.param_predictor.all;

entity high_res_pred_smpl is
	generic (
		SMPL_LIMIT_G: smpl_lim_t
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;

		data_pred_cldiff_i : in signed(D_C-1 downto 0);	-- "d^z(t)" (predicted central local difference)
		data_lsum_i	: in  signed(D_C-1 downto 0);		-- "σz(t)"  (local sum)
		data_s6_o	: out signed(Re_C-1 downto 0)		-- "s)z(t)" (high-resolution predicted sample)
	);
end high_res_pred_smpl;

architecture behavioural of high_res_pred_smpl is
	constant OMG_0_C : signed((OMEGA_C+0)-1 downto 0) := (others => '1');
	constant OMG_1_C : signed((OMEGA_C+1)-1 downto 0) := (others => '1');
	constant OMG_2_C : signed((OMEGA_C+2)-1 downto 0) := (others => '1');
	
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_s6_s : signed(Re_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_high_res_pred_delay : process(clock_i) is
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
	end process p_high_res_pred_delay;
	
	-- High-resolution predicted sample value (s)z(t)) calculation	
	p_high_res_pred_smpl_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v, comp4_v : signed(Re_C-1 downto 0);
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v   := (others => '0');
				comp2_v   := (others => '0');
				comp3_v   := (others => '0');
				comp4_v   := (others => '0');
				data_s6_s <= (others => '0');
			else
				if (enable_i = '1') then
					comp1_v   := mod_R(resize(data_pred_cldiff_i + OMG_0_C * (data_lsum_i - to_signed(4*SMPL_LIMIT_G.mid, Re_C)), Re_C), Re_C);
					comp2_v   := resize(comp1_v + OMG_2_C * to_signed(SMPL_LIMIT_G.mid, Re_C) + OMG_1_C, Re_C);
					comp3_v	  := resize(OMG_2_C * to_signed(SMPL_LIMIT_G.min, Re_C), Re_C);
					comp4_v	  := resize(OMG_2_C * to_signed(SMPL_LIMIT_G.max, Re_C) + OMG_1_C, Re_C);
					data_s6_s <= clip(comp2_v, comp3_v, comp4_v);
				end if;
			end if;
		end if;
	end process p_high_res_pred_smpl_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_s6_o	<= data_s6_s;
end behavioural;