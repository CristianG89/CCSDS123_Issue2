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
use work.types.all;
use work.utils.all;
use work.param_image.all;

entity predicted_sample is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;

		data_s4_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s~z(t)" (double-resolution predicted sample)
		data_s3_o	: out std_logic_vector(D_C-1 downto 0)	-- "s^z(t)"	(predicted sample)
	);
end predicted_sample;

architecture behavioural of predicted_sample is
	signal valid_s	 : std_logic;
	signal data_s3_s : std_logic_vector(D_C-1 downto 0);
	
begin
	-- Predicted sample (s^z(t)) calculation	
	p_pred_smpl_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s3_s <= (others => '0');
			else
				if (valid_i = '1') then
					data_s3_s <= round_down(real(data_s4_i)/2.0);
				end if;
			end if;
		end if;
	end process p_pred_smpl_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_pred_smpl_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s <= '0';
			else
				valid_s <= valid_i;
			end if;
		end if;
	end process p_pred_smpl_delay;

	-- Outputs
	valid_o		<= valid_s;
	data_s3_o	<= data_s3_s;
end behavioural;