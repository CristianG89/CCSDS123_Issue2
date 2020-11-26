--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		clip_quant_bin_center
--
-- Description: Computes the clipped version of the quantizer bin center "s'z(t)"
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.param_image.all;

entity clip_quant_bin_center is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;
		
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"  (maximum error)
		data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"  (quantizer index)
		data_s1_o	: out signed(D_C-1 downto 0)	-- "s'z(t)" (clipped quantizer bin center)
	);
end clip_quant_bin_center;

architecture behavioural of clip_quant_bin_center is
	signal data_s1_s : signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Clipped quantizer bin center value (s'z(t)) calculation	
	p_cl_quan_bin_cnt_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s1_s <= (others => '0');
			else
				if (enable_i = '1') then
					data_s1_s <= clip(data_s3_i+resize(data_quant_i*to_signed(2*to_integer(data_merr_i)+1, D_C), D_C), to_signed(S_MIN_C, D_C), to_signed(S_MAX_C, D_C));
				end if;
			end if;
		end if;
	end process p_cl_quan_bin_cnt_calc;

	-- Outputs
	data_s1_o <= data_s1_s;
end behavioural;