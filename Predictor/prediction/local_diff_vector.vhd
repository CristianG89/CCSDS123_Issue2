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
use work.comp_gen.all;
	
entity local_diff_vector is
	generic (
		CZ_G           : integer;
		PREDICT_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;
		
		ldiff_pos_i	: in  ldiff_pos_t;
		ldiff_vect_o: out array_int_t(CZ_G-1 downto 0)	-- "Uz(t)" (local difference vector)
	);
end local_diff_vector;

architecture Behaviour of local_diff_vector is
	signal valid_s		: std_logic;
	signal ldiff_vect_s	: array_int_t(CZ_G-1 downto 0);

begin
	-- The 3 first positions of output array depends on the prediction mode
	p_ldiff_vect_pred_mode : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				ldiff_vect_s(2 downto 0) <= (others => (others => 0));
			else
				if (valid_i = '1') then
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
	-- The maximum number of spectral bands (per fifo) are calculated, but only some of them (PZ_C) will be used
	g_ldiff_fifos : for i in 0 to P_C-1 generate
		g_ldiff_fifo_0 : if (i = 0) generate
			i_fifo_0 : entity work.fifo
			generic map(
				DATA_SIZE_G	=> D_C,
				FIFO_SIZE_G	=> (NX_C*NY_C-1)
			)
			port map(
				clock_i		=> clock_i,
				reset_i		=> reset_i,
				data_i		=> ldiff_pos_i.n,
				valid_i		=> valid_i,
				data_o		=> ldiff_vect_s(i+3)
			);
		end generate g_ldiff_fifo_0;
		
		g_ldiff_fifo_X : if (i > 0) generate
			i_fifo_X : entity work.fifo
			generic map(
				DATA_SIZE_G	=> D_C,
				FIFO_SIZE_G	=> (NX_C*NY_C-1)
			)
			port map(
				clock_i		=> clock_i,
				reset_i		=> reset_i,
				data_i		=> ldiff_vect_s((i-1)+3),
				valid_i		=> valid_i,
				data_o		=> ldiff_vect_s(i+3)
			);
		end generate g_ldiff_fifo_X;
	end generate g_ldiff_fifos;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_ldiff_vect_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s <= '0';
			else
				valid_s <= valid_i;
			end if;
		end if;
	end process p_ldiff_vect_delay;

	-- Outputs
	valid_o		 <= valid_s;
	ldiff_vect_o <= ldiff_vect_s;
end Behaviour;