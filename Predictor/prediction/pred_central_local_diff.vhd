--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		pred_central_local_diff
--
-- Description: Computes the predicted central local difference "d^z(t)"
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

entity pred_central_local_diff is
    generic (
    	CZ_G           : integer
    );
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		valid_i			: in  std_logic;
		valid_o			: out std_logic;
		
		w_vect_i		: in  array_int_t(CZ_G-1 downto 0);	-- "Wz(t)" (weight vector)
		ldiff_vect_i	: in  array_int_t(CZ_G-1 downto 0);	-- "Uz(t)" (local difference vector)
		
		data_pred_cldiff_o	: out std_logic_vector(D_C-1 downto 0)	-- "d^z(t)" (predicted central local difference)
	);
end pred_central_local_diff;

architecture behavioural of pred_central_local_diff is
	signal valid_s			  : std_logic;
	signal data_pred_cldiff_s : std_logic_vector(D_C-1 downto 0);
	
begin
	-- Predicted central local difference (d^z(t)) calculation	
	p_pred_cldiff_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_pred_cldiff_s <= (others => '0');
			else
				if (valid_i = '1') then
					data_pred_cldiff_s <= vector_product(w_vect_i, ldiff_vect_i, D_C);
				end if;
			end if;
		end if;
	end process p_pred_cldiff_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_pred_cldiff_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s <= '0';
			else
				valid_s <= valid_i;
			end if;
		end if;
	end process p_pred_cldiff_delay;

	-- Outputs
	valid_o				<= valid_s;
	data_pred_cldiff_o	<= data_pred_cldiff_s;
end behavioural;