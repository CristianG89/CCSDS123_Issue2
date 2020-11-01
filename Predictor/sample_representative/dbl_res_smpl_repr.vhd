--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		dbl_res_smpl_repr
--
-- Description: Computes the double-resolution sample representative "s~''z(t)"
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;

entity dbl_res_smpl_repr is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;		

		data_merr_i	: in  std_logic_vector(D_C-1 downto 0);	-- "mz(t)"	(maximum error)
		data_quant_i: in  std_logic_vector(D_C-1 downto 0);	-- "qz(t)"	(quantizer index)		
		data_s6_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s)z(t)"	(high-resolution predicted sample)
		data_s1_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s'z(t)"	(clipped quantizer bin center)
		data_s5_o	: out std_logic_vector(D_C-1 downto 0)	-- "s~''z(t)" (double-resolution sample representative)
	);
end dbl_res_smpl_repr;

architecture behavioural of dbl_res_smpl_repr is
	signal valid_s	 : std_logic;
	signal data_s5_s : std_logic_vector(D_C-1 downto 0);
	
begin
	-- Double-resolution sample representative (s~''z(t)) calculation
	p_dbl_res_smpl_repr_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v, comp4_v, comp5_v : real := 0.0;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v := 0.0;
				comp2_v := 0.0;
				comp3_v := 0.0;
				comp4_v := 0.0;
				comp5_v := 0.0;
				data_s5_s <= (others => '0');
			else
				if (valid_i = '1') then
					comp1_v := 4*(2**THETA_C-FI_C);
					comp2_v := data_s1_i * 2**OMEGA_C;
					comp3_v := sgn(data_quant_i) * data_merr_i * PSI_C * 2**(OMEGA_C-THETA_C);
					comp4_v := FI_C*(data_s6_i - 2**(OMEGA_C+1));
					comp5_v := 2**(OMEGA_C+THETA_C+1);
					data_s5_s <= round_down((comp1_v*(comp2_v-comp3_v)+comp4_v)/comp5_v);
				end if;
			end if;
		end if;
	end process p_dbl_res_smpl_repr_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_dbl_res_smpl_repr_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s	<= '0';
			else
				valid_s	<= valid_i;
			end if;
		end if;
	end process p_dbl_res_smpl_repr_delay;

	-- Outputs
	valid_o		<= valid_s;
	data_s5_o	<= data_s5_s;
end behavioural;