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
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.param_predictor.all;
use work.types_predictor.all;
use work.utils_predictor.all;
use work.comp_predictor.all;

entity dbl_res_pred_smpl is
	generic (
		SMPL_LIMIT_G : smpl_lim_t;
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G : std_logic_vector(1 downto 0)
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)"	(original sample)
		data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)" (high-resolution predicted sample)
		data_s4_o	: out signed(D_C-1 downto 0)	-- "s~z(t)" (double-resolution predicted sample)
	);
end dbl_res_pred_smpl;

architecture behavioural of dbl_res_pred_smpl is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_s0z1_s	: signed(D_C-1 downto 0) := (others => '0');
	signal data_s4_s	: signed(D_C-1 downto 0) := (others => '0');
	
	constant NEXT_Z_C	: integer := locate_position(SMPL_ORDER_G, NX_C*NY_C, 1, NX_C);
	constant PW_OM1_C	: signed(Re_C-1 downto 0) := (OMEGA_C+1 => '1', others => '0');

begin	
	-- Input values delayed to synchronize them with the next modules in chain
	p_dbl_res_pred_delay : process(clock_i) is
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
	end process p_dbl_res_pred_delay;
	
	-- Delay of one complete spectral band to get value (z-1)
	i_shift_reg_s0z1 : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> NEXT_Z_C
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
							data_s4_s <= resize(n2_C*data_s0z1_s, D_C);
						else
							data_s4_s <= to_signed(2*SMPL_LIMIT_G.mid, D_C);
						end if;
					else
						data_s4_s <= resize(round_down(data_s6_i, PW_OM1_C), D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_dbl_res_pred_smpl_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_s4_o	<= data_s4_s;
end behavioural;