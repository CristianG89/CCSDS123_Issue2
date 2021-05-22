--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		predicted_sample
--
-- Description: Predicted sample value "s^z(t)" calculation
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

entity predicted_sample is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;

		data_s4_i	: in  signed(D_C-1 downto 0);	-- "s~z(t)" (double-resolution predicted sample)
		data_s3_o	: out signed(D_C-1 downto 0)	-- "s^z(t)"	(predicted sample)
	);
end predicted_sample;

architecture behavioural of predicted_sample is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	signal data_s3_s	: signed(D_C-1 downto 0) := (others => '0');

begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_pred_smpl_delay : process(clock_i) is
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
	end process p_pred_smpl_delay;
	
	-- Predicted sample (s^z(t)) calculation
	p_pred_smpl_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s3_s <= (others => '0');
			else
				if (enable_i = '1') then
					data_s3_s <= resize(round_down(data_s4_i, n2_C), D_C);
				end if;
			end if;
		end if;
	end process p_pred_smpl_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_s3_o	<= data_s3_s;
end behavioural;