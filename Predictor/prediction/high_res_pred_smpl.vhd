--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		high_res_pred_smpl
--
-- Description: High-resolution predicted sample value "s)z(t)" calculation
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
use work.param_predictor.all;

entity high_res_pred_smpl is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;

		data_pre_cldiff_i : in signed(D_C-1 downto 0);	-- "d^z(t)" (predicted central local difference)
		data_lsum_i	: in  signed(D_C-1 downto 0);		-- "σz(t)"  (local sum)
		data_s6_o	: out signed(Re_C-1 downto 0)		-- "s)z(t)" (high-resolution predicted sample)
	);
end high_res_pred_smpl;

architecture behavioural of high_res_pred_smpl is
	constant OMG_0_C : signed((OMEGA_C+0)-1 downto 0) := (others => '1');
	constant OMG_1_C : signed((OMEGA_C+1)-1 downto 0) := (others => '1');
	constant OMG_2_C : signed((OMEGA_C+2)-1 downto 0) := (others => '1');
	
	signal data_s6_s : signed(Re_C-1 downto 0) := (others => '0');
	
begin
	-- High-resolution predicted sample value (s)z(t)) calculation	
	p_high_res_pred_smpl_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v, comp4_v : signed(Re_C-1 downto 0);
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v   := (others => '0');
				comp2_v   := (others => '0');
				comp3_v   := (others => '0');
				comp4_v   := (others => '0');
				data_s6_s <= (others => '0');
			else
				if (enable_i = '1') then
					comp1_v   := mod_R(resize(data_pre_cldiff_i + OMG_0_C * (data_lsum_i - to_signed(4*S_MID_SGN_C, Re_C)), Re_C), Re_C);
					comp2_v   := resize(comp1_v + OMG_2_C * to_signed(S_MID_SGN_C, Re_C) + OMG_1_C, Re_C);
					comp3_v	  := resize(OMG_2_C * to_signed(S_MIN_SGN_C, Re_C), Re_C);
					comp4_v	  := resize(OMG_2_C * to_signed(S_MAX_SGN_C, Re_C) + OMG_1_C, Re_C);
					data_s6_s <= clip(comp2_v, comp3_v, comp4_v);
				end if;
			end if;
		end if;
	end process p_high_res_pred_smpl_calc;

	-- Outputs
	data_s6_o <= data_s6_s;
end behavioural;