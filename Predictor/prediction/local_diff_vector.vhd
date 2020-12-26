--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		25/10/2020
--------------------------------------------------------------------------------
-- IP name:		local_diff_vector
--
-- Description: Gives a vector with previous central local differences and
--				(if necessary) the current directional local differences.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.param_image.all;
use work.param_predictor.all;
use work.comp_predictor.all;
	
entity local_diff_vector is
	generic (
		PREDICT_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;
		
		ldiff_pos_i	: in  ldiff_pos_t;
		ldiff_vect_o: out array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0)	-- "Uz(t)" (local difference vector)
	);
end local_diff_vector;

architecture Behaviour of local_diff_vector is
	signal ldiff_vect_s	: array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));

begin
	-- The 3 first positions of output array depends on the prediction mode
	p_ldiff_vect_pred_mode : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				ldiff_vect_s(2 downto 0) <= (others => (others => '0'));
			else
				if (enable_i = '1') then
					if (PREDICT_MODE_G = '1') then
						ldiff_vect_s(0) <= ldiff_pos_i.n;
						ldiff_vect_s(1) <= ldiff_pos_i.w;
						ldiff_vect_s(2) <= ldiff_pos_i.nw;
					else
						ldiff_vect_s(0) <= (others => '0');
						ldiff_vect_s(1) <= (others => '0');
						ldiff_vect_s(2) <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process p_ldiff_vect_pred_mode;

	-- Previous central local differences from predefined number of previous spectral bands z
	-- The maximum number of spectral bands (per shift register) are calculated, but only some of them (PZ_C) will be used
	g_ldiff_shift_regs : for i in 3 to MAX_CZ_C-1 generate
		g_ldiff_shift_reg_0 : if (i = 3) generate
			i_shift_reg_0 : shift_register
			generic map(
				DATA_SIZE_G	=> D_C,
				REG_SIZE_G	=> (NX_C*NY_C-1)
			)
			port map(
				clock_i		=> clock_i,
				reset_i		=> reset_i,
				data_i		=> ldiff_pos_i.n,
				data_o		=> ldiff_vect_s(i)
			);
		end generate g_ldiff_shift_reg_0;
		
		g_ldiff_shift_reg_X : if (i > 3) generate
			i_shift_reg_X : shift_register
			generic map(
				DATA_SIZE_G	=> D_C,
				REG_SIZE_G	=> (NX_C*NY_C-1)
			)
			port map(
				clock_i		=> clock_i,
				reset_i		=> reset_i,
				data_i		=> ldiff_vect_s(i-1),
				data_o		=> ldiff_vect_s(i)
			);
		end generate g_ldiff_shift_reg_X;
	end generate g_ldiff_shift_regs;

	-- Outputs
	ldiff_vect_o <= ldiff_vect_s;
end Behaviour;