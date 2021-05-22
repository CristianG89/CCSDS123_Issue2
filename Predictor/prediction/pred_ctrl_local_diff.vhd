--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		pred_ctrl_local_diff
--
-- Description: Computes the predicted central local difference "d^z(t)"
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

entity pred_ctrl_local_diff is
	generic (
		PREDICT_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clock_i		 : in std_logic;
		reset_i		 : in std_logic;
		
		enable_i	 : in  std_logic;
		enable_o	 : out std_logic;
		img_coord_i	 : in  img_coord_t;
		img_coord_o	 : out img_coord_t;
		
		weight_vect_i: in array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0); -- "Wz(t)" (weight vector)
		ldiff_vect_i : in array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0);		 -- "Uz(t)" (local difference vector)
		
		data_pred_cldiff_o : out signed(D_C-1 downto 0)		-- "d^z(t)" (predicted central local difference)
	);
end pred_ctrl_local_diff;

architecture behavioural of pred_ctrl_local_diff is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_pred_cldiff_s : signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_pred_cldiff_delay : process(clock_i) is
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
	end process p_pred_cldiff_delay;
	
	-- Predicted central local difference (d^z(t)) calculation	
	p_pred_cldiff_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_pred_cldiff_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.z = 0 and PREDICT_MODE_G = '0') then
						data_pred_cldiff_s <= (others => '0');
					else
						-- Direct. local differences (positions 0 to 2) are taken into account ONLY under "Full prediction mode",
						-- because such positions are set to 0 if working under "Reduced prediction mode"
						data_pred_cldiff_s <= vector_product(weight_vect_i, ldiff_vect_i);
					end if;
				end if;
			end if;
		end if;
	end process p_pred_cldiff_calc;

	-- Outputs
	enable_o			<= enable_s;
	img_coord_o			<= img_coord_s;
	data_pred_cldiff_o	<= data_pred_cldiff_s;
end behavioural;