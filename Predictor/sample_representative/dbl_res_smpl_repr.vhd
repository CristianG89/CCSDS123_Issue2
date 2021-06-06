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
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.param_predictor.all;
use work.utils_predictor.all;

entity dbl_res_smpl_repr is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;

		data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"	  (maximum error)
		data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"	  (quantizer index)		
		data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)"	  (high-resolution predicted sample)
		data_s1_i	: in  signed(D_C-1 downto 0);	-- "s'z(t)"	  (clipped quantizer bin center)
		
		data_s5_o	: out signed(D_C-1 downto 0)	-- "s~''z(t)" (double-resolution sample representative)
	);
end dbl_res_smpl_repr;

architecture behavioural of dbl_res_smpl_repr is
	constant PW_OM0_C	: signed(Re_C-1 downto 0) := (OMEGA_C+0 => '1', others => '0');
	constant PW_OM1_C	: signed(Re_C-1 downto 0) := (OMEGA_C+1 => '1', others => '0');
	constant PW_OMTH_C	: signed(Re_C-1 downto 0) := (OMEGA_C-THETA_C => '1', others => '0');
	constant PW_OMTH1_C	: signed(Re_C-1 downto 0) := (OMEGA_C+THETA_C+1 => '1', others => '0');

	signal fi_s			: integer range 0 to (2**THETA_C-1) := 0;
	signal psi_s		: integer range 0 to (2**THETA_C-1) := 0;
	
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	signal data_s5_s	: signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_dbl_res_smpl_delay : process(clock_i) is
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
	end process p_dbl_res_smpl_delay;
	
	-- Current sample representative damping and offset values, updated according to the spectral band Z
	fi_s  <= FI_AR_C(img_coord_i.z);
	psi_s <= PSI_AR_C(img_coord_i.z);
	
	-- Double-resolution sample representative (s~''z(t)) calculation
	p_dbl_res_smpl_repr_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v, comp4_v : signed(Re_C-1 downto 0) := (others => '0');
		variable comp5_v : signed(2 downto 0) := (others => '0');	-- No need to be longer!
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v	  := (others => '0');
				comp2_v	  := (others => '0');
				comp3_v	  := (others => '0');
				comp4_v	  := (others => '0');
				comp5_v	  := (others => '0');
				data_s5_s <= (others => '0');
			else
				if (enable_i = '1') then
					comp1_v := to_signed(4 * (2**THETA_C - fi_s), Re_C);
					comp2_v := resize(data_s1_i * PW_OM0_C, Re_C);
					comp5_v := to_signed(sgn(data_quant_i), comp5_v'length);
					comp3_v := resize(comp5_v * data_merr_i * to_signed(psi_s, D_C) * PW_OMTH_C, Re_C);
					comp4_v := resize(to_signed(fi_s, D_C) * (data_s6_i - PW_OM1_C), Re_C);
					data_s5_s <= resize(round_down(comp1_v * (comp2_v-comp3_v) + comp4_v, PW_OMTH1_C), D_C);
				end if;
			end if;
		end if;
	end process p_dbl_res_smpl_repr_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_s5_o	<= data_s5_s;
end behavioural;