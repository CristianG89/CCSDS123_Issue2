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
use work.utils_image.all;

use work.param_predictor.all;
use work.types_predictor.all;
use work.utils_predictor.all;

entity fidelity_ctrl is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G	: std_logic_vector(1 downto 0);
		-- 1: band-dependent, 0: band-independent (for both absolute and relative error limit assignments)
		ABS_ERR_BAND_TYPE_G	: std_logic;
		REL_ERR_BAND_TYPE_G	: std_logic
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i 	: in  std_logic;
		coord_z_i	: in  integer;
		
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_o	: out signed(D_C-1 downto 0)	-- "mz(t)"  (maximum error)
	);
end fidelity_ctrl;

architecture behavioural of fidelity_ctrl is
	signal data_merr_s	: signed(D_C-1 downto 0) := (others => '0');
	signal Az_s			: integer range 0 to (2**DA_C-1) := A_C;
	signal Rz_s			: integer range 0 to (2**DA_C-1) := R_C;
	
begin
	-- Absolute and relative error limit values calculation
	Az_s <= Az_AR_C(coord_z_i) when ABS_ERR_BAND_TYPE_G='1' else A_C;
	Rz_s <= Rz_AR_C(coord_z_i) when REL_ERR_BAND_TYPE_G='1' else R_C;
	
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
						data_merr_s <= round_down(resize(to_signed(Rz_s, D_C) * abs(data_s3_i), D_C), to_signed((2**D_C)-1, D_C));
					else	-- FIDEL_CTRL_TYPE_G = "11"		-- BOTH absolute and relative error limits
						data_merr_s <= resize(work.utils_image.min(to_signed(Az_s, D_C), round_down(resize(to_signed(Rz_s, D_C) * abs(data_s3_i), D_C), to_signed((2**D_C)-1, D_C))), D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_merr_calc;

	-- Outputs
	data_merr_o	<= data_merr_s;
end behavioural;