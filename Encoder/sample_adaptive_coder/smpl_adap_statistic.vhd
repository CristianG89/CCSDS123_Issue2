--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		05/04/2021
--------------------------------------------------------------------------------
-- IP name:		smpl_adap_statistic
--
-- Description: The adaptive code selection statistics used to select the
--				codeword for each mapped quantizer index.
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

entity smpl_adap_statistic is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);		-- "?z(t)" (mapped quantizer index)
		accu_o			: out integer;						-- Accumulator Σz(t)
		counter_o		: out integer						-- Counter Γ(t)
	);
end smpl_adap_statistic;

architecture behavioural of smpl_adap_statistic is
	signal data_mp_quan_prev_s	: unsigned(D_C-1 downto 0);
	
	signal accu_s				: integer := 0;
	signal counter_s			: integer := 0;
	signal accu_prev_s			: integer;
	signal counter_prev_s		: integer;
	
	constant K1_C				: integer := iif(K2_C <= 30-D_C, K2_C, 2*K2_C+D_C-30);
	
begin
	-- Previous incoming values
	p_prev_values : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_mp_quan_prev_s	<= (others => '0');
				accu_prev_s			<= 0;
				counter_prev_s		<= 0;
			else
				data_mp_quan_prev_s	<= data_mp_quan_i;
				accu_prev_s			<= accu_s;
				counter_prev_s		<= counter_s;
			end if;
		end if;
	end process p_prev_values;

	-- Calculation of accumulator Σz(t) and counter Γ(t)
	p_calc_accu_count : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				accu_s	  <= 0;
				counter_s <= 0;
			else
				if (enable_i = '1') then
					if (img_coord_i.t > 0) then
						if (counter_prev_s < 2**Y_C-1) then
							accu_s	  <= accu_prev_s + to_integer(data_mp_quan_prev_s);
							counter_s <= counter_prev_s + 1;
						else	-- In theory that can only mean: counter_prev_s = 2**Y_C-1
							accu_s	  <= round_down(accu_prev_s + to_integer(data_mp_quan_prev_s) + 1, 2);
							counter_s <= round_down(counter_prev_s + 1, 2);
						end if;
					else		-- img_coord_i.t = 0 --> Initial values!
						accu_s	  <= round_down(2**Yo_C * (3 * 2**(K1_C + 6) - 49), 2**7);
						counter_s <= 2**Yo_C;
					end if;
				end if;
			end if;
		end if;
	end process p_calc_accu_count;

	-- Outputs
	accu_o	  <= accu_s;
	counter_o <= counter_s;
end behavioural;