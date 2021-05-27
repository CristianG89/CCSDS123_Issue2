--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		weight_upd_scal_exp
--
-- Description: Computes the weight update scaling exponent "p(t)"
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

entity weight_upd_scal_exp is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_w_exp_o: out signed(D_C-1 downto 0)	-- "p(t)" (weight update scaling exponent)
	);
end weight_upd_scal_exp;

architecture behavioural of weight_upd_scal_exp is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_w_exp_s	: signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_w_upd_scal_delay : process(clock_i) is
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
	end process p_w_upd_scal_delay;
	
	-- Weight update scaling exponent value (p(t)) calculation	
	p_w_upd_scal_exp_calc : process(clock_i) is
		variable comp1_v, comp2_v : signed(D_C-1 downto 0) := (others => '0');
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v		 := (others => '0');
				comp2_v		 := (others => '0');
				data_w_exp_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.t > 0) then
						comp1_v := round_down(to_signed(img_coord_i.t-NX_C, D_C), to_signed(2**T_INC_C, D_C));
						comp2_v := clip(to_signed(V_MIN_C, D_C) + comp1_v, to_signed(V_MIN_C, D_C), to_signed(V_MAX_C, D_C));
						data_w_exp_s <= resize(comp2_v + to_signed(D_C, D_C) - to_signed(OMEGA_C, D_C), D_C);
					else		-- This case is not defined on documentation, so probably not used later on
						data_w_exp_s <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process p_w_upd_scal_exp_calc;

	-- Outputs
	enable_o	 <= enable_s;
	img_coord_o	 <= img_coord_s;
	data_w_exp_o <= data_w_exp_s;
end behavioural;