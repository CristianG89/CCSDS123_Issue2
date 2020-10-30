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
use work.types.all;
use work.utils.all;
use work.param_image.all;
	
entity adder is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		valid_i 	: in  std_logic;
		valid_o		: out std_logic;

		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_s0_i	: in  std_logic_vector(D_C-1 downto 0);	-- "sz(t)" (clipped quantizer bin center)
		data_s3_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_res_o	: out std_logic_vector(D_C-1 downto 0)	-- "/\z(t)" (prediction residual)
	);
end adder;

architecture behavioural of adder is
	signal valid_s		: std_logic;
	signal img_coord_s	: img_coord_t;
	signal data_res_s	: std_logic_vector(D_C-1 downto 0);

begin
	-- Prediction residual (/\z(t)) calculation
	p_adder_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '0') then
				data_res_s <= 0;
			else
				if (valid_i = '1') then
					data_res_s <= data_s0_i - data_s3_i;
				end if;
			end if;
		end if;
	end process p_adder_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_adder_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s		<= '0';
				img_coord_s	<= (others => (others => 0));
			else
				valid_s		<= valid_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_adder_delay;

	-- Outputs
	valid_o		<= valid_s;
	img_coord_o	<= img_coord_s;
	data_res_o	<= data_res_s;
end behavioural;