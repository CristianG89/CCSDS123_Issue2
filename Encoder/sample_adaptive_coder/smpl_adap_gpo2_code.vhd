--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		05/04/2021
--------------------------------------------------------------------------------
-- IP name:		smpl_adap_gpo2_code
--
-- Description: Variable-length binary GPO2 codeword to encode with the
--				Sample Adaptive Entropy Coder.
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

entity smpl_adap_gpo2_code is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);		-- "?z(t)" (mapped quantizer index)
		accu_i			: in  integer;						-- "Σz(t)" (accumulator)
		counter_i		: in  integer;						-- "Γ(t)"  (counter)
		
		codeword_o		: out unsigned(Umax_C+D_C-1 downto 0) -- "Rk(j)" (codeword)
	);
end smpl_adap_gpo2_code;

architecture behavioural of smpl_adap_gpo2_code is
	signal kz_s			: integer;
	signal codeword_s	: unsigned(Umax_C+D_C-1 downto 0);
	
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
					kz_v := log2((accu_i + round_down(49*counter_i, 2**7)) / counter_i);
					-- The previous value must be within [0, D-2]
					kz_v := iif(kz_v < 0, 0, iif(kz_v > D_C-2, D_C-2, kz_v));
					kz_s <= kz_v;
				end if;
			end if;
		end if;
	end process p_calc_kz;

	-- Calculation of "Rk(j)" (Variable-length GPO2 Codeword of Mapped Quantizer Index)
	p_calc_codeword : process(clock_i) is
		variable var_length_v : integer;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				codeword_s <= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.t = 0) then		-- Sample for t=0 must not be encoded!
						codeword_s <= resize(data_mp_quan_i, Umax_C+D_C);
					else
						var_length_v := round_down(to_integer(data_mp_quan_i), 2**kz_s);
						if (var_length_v < Umax_C) then
							codeword_s <= resize((var_length_v-1 downto 0 => '0') & '1' & data_mp_quan_i(kz_s-1 downto 0), Umax_C+D_C);
						else
							codeword_s <= resize((Umax_C-1 downto 0 => '0') & data_mp_quan_i, Umax_C+D_C);
						end if;
					end if;
				end if;
			end if;
		end if;
	end process p_calc_codeword;

	-- Outputs
	codeword_o <= codeword_s;
end behavioural;