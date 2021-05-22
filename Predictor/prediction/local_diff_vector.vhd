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
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.param_predictor.all;
use work.types_predictor.all;
use work.comp_predictor.all;
	
entity local_diff_vector is
	generic (
		SMPL_ORDER_G	: std_logic_vector(1 downto 0);	-- 00: BSQ order, 01: BIP order, 10: BIL order
		PREDICT_MODE_G  : std_logic						-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		ldiff_pos_i	: in  ldiff_pos_t;
		ldiff_vect_o: out array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0)	-- "Uz(t)" (local difference vector)
	);
end local_diff_vector;

architecture Behaviour of local_diff_vector is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal ldiff_vect_s	: array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	
	constant NEXT_Z_C	: integer := locate_position(SMPL_ORDER_G, NX_C*NY_C, 1, NX_C);

begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_ldiff_vect_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_s	<= '0';
				img_coord_s <= reset_img_coord;
			else
				enable_s	<= enable_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_ldiff_vect_delay;
	
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
					else	-- Under "Reduced prediction mode", the direct. local differences are set to 0
						ldiff_vect_s(0) <= (others => '0');
						ldiff_vect_s(1) <= (others => '0');
						ldiff_vect_s(2) <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process p_ldiff_vect_pred_mode;

	-- Previous central local differences from predefined number of previous spectral bands z
	-- The maximum number of spectral bands per shift register (MAX_CZ_C) are calculated, but only some of them (PZ_C) will be used
	g_ldiff_shift_regs : for i in 3 to MAX_CZ_C-1 generate
		g_ldiff_shift_reg_0 : if (i = 3) generate
			i_shift_reg_0 : shift_register
			generic map(
				DATA_SIZE_G	=> D_C,
				REG_SIZE_G	=> NEXT_Z_C
			)
			port map(
				clock_i		=> clock_i,
				reset_i		=> reset_i,
				data_i		=> ldiff_pos_i.c,
				data_o		=> ldiff_vect_s(i)
			);
		end generate g_ldiff_shift_reg_0;
		
		g_ldiff_shift_reg_X : if (i > 3) generate
			i_shift_reg_X : shift_register
			generic map(
				DATA_SIZE_G	=> D_C,
				REG_SIZE_G	=> NEXT_Z_C
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
	enable_o	 <= enable_s;
	img_coord_o	 <= img_coord_s;
	ldiff_vect_o <= ldiff_vect_s;
end Behaviour;