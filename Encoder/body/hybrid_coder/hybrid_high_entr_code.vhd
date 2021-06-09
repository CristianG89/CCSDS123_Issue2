--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		10/04/2021
--------------------------------------------------------------------------------
-- IP name:		hybrid_high_entr_code
--
-- Description: The high-entropy (reversed length-limited GPO2) codeword to
--				encode with the Hybrid Entropy Coder.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;

entity hybrid_high_entr_code is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)"  (mapped quantizer index)
		high_res_accu_i	: in  integer;							-- "Σ~z(t)" (high resolution accumulator)
		counter_i		: in  integer;							-- "Γ(t)"   (counter)
		
		rvd_codeword_o	: out unsigned(Umax_C+D_C-1 downto 0)	-- "R'k(j)" (reversed codeword)
	);
end hybrid_high_entr_code;

architecture behavioural of hybrid_high_entr_code is
	signal kz_s			  : integer;
	signal rvd_codeword_s : unsigned(Umax_C+D_C-1 downto 0);
	
begin
	-- Calculation of "kz(t)" (Variable length code parameter)
	p_calc_kz : process(clock_i) is
		variable kz_v : integer;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				kz_v := 0;
				kz_s <= 0;
			else
				if (enable_i = '1') then
					kz_v := log2((high_res_accu_i + round_down(49*counter_i, 2**5)) / counter_i) - 2;
					-- The previous value must be within [0, max(D-2, 2)]
					kz_v := iif(kz_v < 0, 0, iif(kz_v > max(D_C-2, 2), max(D_C-2, 2), kz_v));
					kz_s <= kz_v;
				end if;
			end if;
		end if;
	end process p_calc_kz;

	-- Calculation of "R'k(j)" (Reversed Length-Limited GPO2 Codeword of Mapped Quantizer Index)
	p_calc_codeword : process(clock_i) is
		variable var_length_v : integer;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				rvd_codeword_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.t = 0) then		-- Sample for t=0 must not be encoded!
						rvd_codeword_s <= resize(data_mp_quan_i, Umax_C+D_C);
					else
						var_length_v := round_down(to_integer(data_mp_quan_i), 2**kz_s);
						if (var_length_v < Umax_C) then
							rvd_codeword_s <= resize(data_mp_quan_i(kz_s-1 downto 0) & '1' & (var_length_v-1 downto 0 => '0'), Umax_C+D_C);
						else
							rvd_codeword_s <= resize(data_mp_quan_i & (Umax_C-1 downto 0 => '0'), Umax_C+D_C);
						end if;
					end if;
				end if;
			end if;
		end if;
	end process p_calc_codeword;

	-- Outputs
	rvd_codeword_o <= rvd_codeword_s;
end behavioural;