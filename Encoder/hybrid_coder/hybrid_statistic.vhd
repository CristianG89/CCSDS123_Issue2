--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		18/04/2021
--------------------------------------------------------------------------------
-- IP name:		hybrid_statistic
--
-- Description: The adaptive code selection statistics (for Hybrid Entropy) used
--				to select the codeword type for each mapped quantizer index.
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

entity hybrid_statistic is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);		-- "?z(t)" (mapped quantizer index)
		
		high_res_accu_o	: out integer;						-- High resolution accumulator Σ~z(t)
		counter_o		: out integer;						-- Counter Γ(t)
		entropy_select_o: out std_logic						-- Selected Entropy method (1=high-entropy, 0=low-entropy)
	);
end hybrid_statistic;

architecture behavioural of hybrid_statistic is
	signal data_mp_quan_prev_s	: unsigned(D_C-1 downto 0);
	
	signal high_res_accu_s		: integer := 0;
	signal counter_s			: integer := 0;
	signal high_res_accu_prev_s	: integer;
	signal counter_prev_s		: integer;
	
	signal entropy_select_s		: std_logic;
	
	-- High-resolution accumulator initial value
	constant HR_ACCU_INIT_C : integer range 0 to 2**(D_C+Yo_C) := 50;
	-- Shortcut to Low-Entropy code table, subfield Threshold, position 0
	constant T0_C : integer := LOW_ENTR_CODES_C.threshold(0);
	
begin
	-- Previous incoming values
	p_prev_values : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_mp_quan_prev_s	<= (others => '0');
				high_res_accu_prev_s<= 0;
				counter_prev_s		<= 0;
			else
				data_mp_quan_prev_s	<= data_mp_quan_i;
				high_res_accu_prev_s<= high_res_accu_s;
				counter_prev_s		<= counter_s;
			end if;
		end if;
	end process p_prev_values;

	-- Calculation of high resolution accumulator Σ~z(t) and counter Γ(t)
	p_calc_hres_accu_count : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				high_res_accu_s <= 0;
				counter_s		<= 0;
			else
				if (enable_i = '1') then
					if (img_coord_i.t > 0) then
						if (counter_prev_s < 2**Y_C-1) then
							high_res_accu_s <= high_res_accu_prev_s + 4*to_integer(data_mp_quan_prev_s);
							counter_s		<= counter_prev_s + 1;
						else	-- In theory that can only mean: counter_prev_s = 2**Y_C-1
							high_res_accu_s <= round_down(high_res_accu_prev_s + 4*to_integer(data_mp_quan_prev_s) + 1, 2);
							counter_s		<= round_down(counter_prev_s + 1, 2);
						end if;
					else		-- img_coord_i.t = 0 --> Initial values!
						high_res_accu_s <= HR_ACCU_INIT_C;
						counter_s		<= 2**Yo_C;
					end if;
				end if;
			end if;
		end if;
	end process p_calc_hres_accu_count;

	-- High/Low-Entropy processing selection
	p_entropy_select : process(clock_i) is
		variable threshold_v : integer;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				entropy_select_s <= '0';
				threshold_v		 := 0;
			else
				if (enable_i = '1') then
					if (img_coord_i.t > 0) then
						threshold_v := high_res_accu_s * (2**14) / counter_s;
						if (threshold_v < T0_C or D_C = 2) then
							entropy_select_s <= '0';	-- Low-Entropy processing selected
						else
							entropy_select_s <= '1';	-- High-Entropy processing selected
						end if;
					else
						-- Low-Entrope selected vhen t=0, but actually it does not matter, as the
						-- mapped quantized index will not be encoded in the next IP when t=0
						entropy_select_s <= '0';
					end if;
				end if;
			end if;
		end if;
	end process p_entropy_select;

	-- Outputs
	high_res_accu_o  <= high_res_accu_s;
	counter_o		 <= counter_s;
	entropy_select_o <= entropy_select_s;
end behavioural;