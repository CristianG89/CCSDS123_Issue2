--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		dbl_res_pred_smpl
--
-- Description: Double-resolution predicted sample value "s~z(t)" calculation
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
use work.comp_predictor.all;

entity dbl_res_pred_smpl is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;
		
		img_coord_i	: in  img_coord_t;
		data_s0_i	: in  unsigned(D_C-1 downto 0);	-- "sz(t)"	(original sample)
		data_s6_i	: in  unsigned(D_C-1 downto 0);	-- "s)z(t)" (high-resolution predicted sample)
		data_s4_o	: out unsigned(D_C-1 downto 0)	-- "s~z(t)" (double-resolution predicted sample)
	);
end dbl_res_pred_smpl;

architecture behavioural of dbl_res_pred_smpl is
	signal data_s0z1_s	: unsigned(D_C-1 downto 0);
	signal data_s4_s	: unsigned(D_C-1 downto 0);

begin	
	-- Delay of one complete spectral band to get value (z-1)
	i_shift_reg_s0z1 : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> (NX_C*NY_C-1)
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s0_i,
		data_o		=> data_s0z1_s	-- s0_z-1(t)
	);
	
	-- Double-resolution predicted sample (s~z(t)) calculation	
	p_dbl_res_pred_smpl_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s4_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.t = 0) then
						if (img_coord_i.z > 0 and P_C > 0) then
							data_s4_s <= 2*data_s0z1_s;
						else
							data_s4_s <= to_unsigned(2*S_MID_C, D_C);
						end if;
					else
						data_s4_s <= to_unsigned(round_down(real(to_integer(data_s6_i))/real(2**(OMEGA_C+1))), D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_dbl_res_pred_smpl_calc;

	-- Outputs
	data_s4_o <= data_s4_s;
end behavioural;