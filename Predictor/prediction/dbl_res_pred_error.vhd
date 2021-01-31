--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		dbl_res_pred_error
--
-- Description: Computes the double-resolution prediction error "ez(t)"
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.param_image.all;

entity dbl_res_pred_error is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;
		
		data_s1_i	: in  signed(D_C-1 downto 0);		-- "s'z(t)"	(clipped quantizer bin center)
		data_s4_i	: in  signed(D_C-1 downto 0);		-- "s~z(t)"	(double-resolution predicted sample)
		data_pred_err_o : out signed(D_C-1 downto 0)	-- "ez(t)"	(double-resolution prediction error)
	);
end dbl_res_pred_error;

architecture behavioural of dbl_res_pred_error is
	signal data_pred_err_s : signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Double-resolution prediction error value (ez(t)) calculation	
	p_dbl_res_pred_er_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_pred_err_s <= (others => '0');
			else
				if (enable_i = '1') then
					data_pred_err_s <= resize(n2_C*data_s1_i - data_s4_i, D_C);
				end if;
			end if;
		end if;
	end process p_dbl_res_pred_er_calc;

	-- Outputs
	data_pred_err_o <= data_pred_err_s;
end behavioural;