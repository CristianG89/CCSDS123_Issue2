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
use work.utils_predictor.all;
use work.param_image.all;
use work.param_predictor.all;

entity dbl_res_smpl_repr is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;	

		data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"	  (maximum error)
		data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"	  (quantizer index)		
		data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)"	  (high-resolution predicted sample)
		data_s1_i	: in  signed(D_C-1 downto 0);	-- "s'z(t)"	  (clipped quantizer bin center)
		
		data_s5_o	: out signed(D_C-1 downto 0)	-- "s~''z(t)" (double-resolution sample representative)
	);
end dbl_res_smpl_repr;

architecture behavioural of dbl_res_smpl_repr is
	signal data_s5_s : signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Double-resolution sample representative (s~''z(t)) calculation
	p_dbl_res_smpl_repr_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v, comp4_v, comp5_v : signed(Re_C-1 downto 0) := (others => '0');
		variable comp6_v : signed(2 downto 0) := (others => '0');	-- No need to be longer!
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v	  := (others => '0');
				comp2_v	  := (others => '0');
				comp3_v	  := (others => '0');
				comp4_v	  := (others => '0');
				comp5_v	  := (others => '0');
				comp6_v	  := (others => '0');
				data_s5_s <= (others => '0');
			else
				if (enable_i = '1') then
					comp1_v := to_signed(4 * (2**THETA_C - FI_C), Re_C);
					comp2_v := resize(data_s1_i * to_signed(2**OMEGA_C, Re_C), Re_C);
					comp6_v := sgn(data_quant_i);
					comp3_v := resize(comp6_v * data_merr_i * to_signed(PSI_C, D_C) * to_signed(2**(OMEGA_C-THETA_C), Re_C), Re_C);
					comp4_v := resize(to_signed(FI_C, D_C) * (data_s6_i - to_signed(2**(OMEGA_C+1), Re_C)), Re_C);
					comp5_v := to_signed(2**(OMEGA_C+THETA_C+1), Re_C);
					data_s5_s <= round_down(resize((comp1_v*(comp2_v-comp3_v)+comp4_v)/comp5_v, D_C));
				end if;
			end if;
		end if;
	end process p_dbl_res_smpl_repr_calc;

	-- Outputs
	data_s5_o	<= data_s5_s;
end behavioural;