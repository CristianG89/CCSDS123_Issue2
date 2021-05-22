--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		adder
--
-- Description: Returns the difference between two elements
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
	
entity adder is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)"  (original sample)
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_res_o	: out signed(D_C-1 downto 0)	-- "/\z(t)" (prediction residual)
	);
end adder;

architecture behavioural of adder is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_res_s	: signed(D_C-1 downto 0) := (others => '0');

begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_adder_delay : process(clock_i) is
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
	end process p_adder_delay;
	
	-- Prediction residual (/\z(t)) calculation
	p_adder_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_res_s <= (others => '0');
			else
				if (enable_i = '1') then
					data_res_s <= resize(data_s0_i - data_s3_i, D_C);
				end if;
			end if;
		end if;
	end process p_adder_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_res_o	<= data_res_s;
end behavioural;