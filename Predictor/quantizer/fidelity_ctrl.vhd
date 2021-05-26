--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		fidelity_ctrl
--
-- Description: Controls the step size via an absolute and/or a relative error
--				limit (so samples can be reconstructed later with some tolerance)
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

entity fidelity_ctrl is
	generic (
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G		: std_logic_vector(1 downto 0);
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G	: std_logic_vector(1 downto 0);
		-- 1: band-dependent, 0: band-independent (for both absolute and relative error limit assignments)
		ABS_ERR_BAND_TYPE_G	: std_logic;
		REL_ERR_BAND_TYPE_G	: std_logic;
		-- 1: enabled, 0: disabled
		PER_ERR_LIM_UPD_G	: std_logic
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		enable_i	: in  std_logic;
		enable_o	: out std_logic;
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_o	: out signed(D_C-1 downto 0)	-- "mz(t)"  (maximum error)
	);
end fidelity_ctrl;

architecture behavioural of fidelity_ctrl is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	signal upd_cnt_s	: integer := 0;
	
	signal data_merr_s	: signed(D_C-1 downto 0) := (others => '0');
	signal Az_s			: integer range 0 to (2**DA_C-1) := A_C;
	signal Rz_s			: integer range 0 to (2**DA_C-1) := R_C;
	
	constant PW_D_C		: signed(Re_C-1 downto 0) := (D_C => '1', others => '0');
	
begin
	-- (If necessary) absolute and relative error limit values calculation, either:
	-- 1. Periodically updated, with continuous incoming values
	-- 2. Fixed values, depending on the band-(in)dependency configuration.
	-- NOTE: When absolute and relative error limits used, their band-(in)dependency config does not need to be the same.
	g_err_lim_def : if (FIDEL_CTRL_TYPE_G /= "00") generate
		g_err_lim_calc : if (PER_ERR_LIM_UPD_G = '1') generate
		
			p_err_lim_calc : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						upd_cnt_s <= 0;
						Az_s	  <= A_C;
						Rz_s	  <= R_C;
					else
						if (enable_i = '1') then
							if (upd_cnt_s >= 2**U_C) then
								upd_cnt_s <= 0;
								-- TO BE UPDATED ONCE I UNDERSTAND WHAT TO PUT HERE!!
								Az_s <= Az_s + 1;
								Rz_s <= Rz_s + 1;
							else
								upd_cnt_s <= upd_cnt_s + 1;
							end if;
						end if;
					end if;
				end if;
			end process p_err_lim_calc;
			
		else generate
			Az_s <= Az_AR_C(img_coord_i.z) when ABS_ERR_BAND_TYPE_G='1' else A_C;
			Rz_s <= Rz_AR_C(img_coord_i.z) when REL_ERR_BAND_TYPE_G='1' else R_C;
		end generate g_err_lim_calc;
	end generate g_err_lim_def;

	-- Input values delayed to synchronize them with the next modules in chain
	p_fidelity_delay : process(clock_i) is
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
	end process p_fidelity_delay;
	
	-- Maximum error value (mz(t)) calculation	
	p_merr_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_merr_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (FIDEL_CTRL_TYPE_G = "00") then		-- Lossless method
						data_merr_s <= (others => '0');
					elsif (FIDEL_CTRL_TYPE_G = "01") then	-- ONLY absolute error limit method
						data_merr_s <= to_signed(Az_s, D_C);
					elsif (FIDEL_CTRL_TYPE_G = "10") then	-- ONLY relative error limit method
						data_merr_s <= resize(round_down(resize(to_signed(Rz_s, D_C) * abs(data_s3_i), Re_C), PW_D_C), D_C);
					else	-- FIDEL_CTRL_TYPE_G = "11"		-- BOTH absolute and relative error limits
						data_merr_s <= work.utils_image.min(to_signed(Az_s, D_C), resize(round_down(resize(to_signed(Rz_s, D_C) * abs(data_s3_i), Re_C), PW_D_C), D_C));
					end if;
				end if;
			end if;
		end if;
	end process p_merr_calc;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_merr_o	<= data_merr_s;
end behavioural;