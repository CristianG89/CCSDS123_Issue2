--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		scaled_diff
--
-- Description: Computes the scaled difference between sˆz(t) and the nearest
--				endpoint
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

entity scaled_diff is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_s3_i		: in  unsigned(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i		: in  unsigned(D_C-1 downto 0);	-- "mz(t)" (maximum error)
		data_sc_diff_o	: out unsigned(D_C-1 downto 0)	-- "θz(t)" (scaled difference)
	);
end scaled_diff;

architecture behavioural of scaled_diff is
	signal data_sc_diff_s : unsigned(D_C-1 downto 0);
	
begin
	-- Scaled difference value (θz(t)) calculation	
	p_sc_diff_calc : process(clock_i) is
		variable comp1_v : integer := 0;
		variable comp2_v : integer := 0;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v			:= 0;
				comp2_v			:= 0;
				data_sc_diff_s	<= (others => '0');
			else
				if (enable_i = '1') then
					if (img_coord_i.t = 0) then
						data_sc_diff_s <= to_unsigned(min(to_integer(data_s3_i) - S_MIN_C, S_MAX_C - to_integer(data_s3_i)), D_C);
					else
						comp1_v := round_down(real(to_integer(data_s3_i)-S_MIN_C+to_integer(data_merr_i))/real(2*to_integer(data_merr_i)+1));
						comp2_v := round_down(real(S_MAX_C-to_integer(data_s3_i)+to_integer(data_merr_i))/real(2*to_integer(data_merr_i)+1));
						data_sc_diff_s <= to_unsigned(min(comp1_v, comp2_v), D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_sc_diff_calc;

	-- Outputs
	data_sc_diff_o <= data_sc_diff_s;
end behavioural;