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
	generic (
		S_MIN_G		: integer;
		S_MID_G		: integer;
		S_MAX_G		: integer
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;

		data_pre_cldiff_i : in std_logic_vector(D_C-1 downto 0); -- "d^z(t)" (predicted central local difference)
		data_lsum_i	: in  std_logic_vector(D_C-1 downto 0);	-- "σz(t)" (Local sum)
		data_s6_o	: out std_logic_vector(D_C-1 downto 0)	-- "s)z(t)" (high-resolution predicted sample)
	);
end high_res_pred_smpl;

architecture behavioural of high_res_pred_smpl is
	constant OMG_0_C : integer := 2**OMEGA_C;
	constant OMG_1_C : integer := 2**(OMEGA_C+1);
	constant OMG_2_C : integer := 2**(OMEGA_C+2);
	
	signal valid_s	 : std_logic;
	signal data_s6_s : std_logic_vector(D_C-1 downto 0);
	
begin
	-- High-resolution predicted sample value (s)z(t)) calculation	
	p_high_res_pred_smpl_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s6_s <= (others => '0');
			else
				if (valid_i = '1') then
					data_s6_s <= clip(mod_R(data_pre_cldiff_i+OMG_0_C*(s_data_lsz_i-4*S_MID_G), Re_C)+OMG_2_C*S_MID_G+OMG_1_C, OMG_2_C*S_MIN_G, OMG_2_C*S_MAX_G+OMG_1_C);
				end if;
			end if;
		end if;
	end process p_high_res_pred_smpl_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_high_res_pred_smpl_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s <= '0';
			else
				valid_s <= valid_i;
			end if;
		end if;
	end process p_high_res_pred_smpl_delay;

	-- Outputs
	valid_o		<= valid_s;
	data_s6_o	<= data_s6_s;
end behavioural;