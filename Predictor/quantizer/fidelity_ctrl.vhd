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
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;

entity fidelity_ctrl is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i 	: in  std_logic;
		valid_o		: out std_logic;
		
		data_s3_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_o	: out std_logic_vector(D_C-1 downto 0)	-- "mz(t)" (maximum error)
	);
end fidelity_ctrl;

architecture behavioural of fidelity_ctrl is
	signal valid_s		: std_logic;
	signal data_merr_s	: std_logic_vector(D_C-1 downto 0);
	
begin
	-- Maximum error value (mz(t)) calculation	
	p_merr_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_merr_s <= (others => '0');
			else
				if (valid_i = '1') then
					if (FIDEL_CTRL_TYPE_G = "00") then		-- Lossless method
						data_merr_s <= (others => '0');
					elsif (FIDEL_CTRL_TYPE_G = "01") then	-- ONLY absolute error limit method
						data_merr_s <= Az_C;
					elsif (FIDEL_CTRL_TYPE_G = "10") then	-- ONLY relative error limit method
						data_merr_s <= round_down(real(Rz_C)*real(abs_int(data_s3_i))/real(2**D_C));
					else	-- FIDEL_CTRL_TYPE_G = "11"		-- BOTH absolute and relative error limits
						data_merr_s <= min(Az_C, round_down(real(Rz_C)*real(abs_int(data_s3_i))/real(2**D_C)));
					end if;
				end if;
			end if;
		end if;
	end process p_merr_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_merr_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s	<= '0';
			else
				valid_s	<= valid_i;
			end if;
		end if;
	end process p_merr_delay;

	-- Outputs
	valid_o		<= valid_s;
	data_merr_o	<= data_merr_s;
end behavioural;