--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		scaled_diff
--
-- Description: Computes the scaled difference between sˆz(t) and the nearest
--				endpoint (s_min, s_max)
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
	generic (
		S_MIN_G			: integer;
		S_MAX_G			: integer
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		valid_i			: in  std_logic;
		valid_o			: out std_logic;
		
		img_coord_i		: in  img_coord_t;
		img_coord_o		: out img_coord_t;
		
		data_s3_i		: in  std_logic_vector(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i		: in  std_logic_vector(D_C-1 downto 0);	-- "mz(t)" (maximum error)
		data_sc_diff_o	: out std_logic_vector(D_C-1 downto 0)	-- "θz(t)" (scaled difference)
	);
end scaled_diff;

architecture behavioural of scaled_diff is
	signal valid_s			: std_logic;
	signal img_coord_s		: img_coord_t;
	signal data_sc_diff_s	: std_logic_vector(D_C-1 downto 0);
	
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
				if (valid_i = '1') then
					if (img_coord_s.t = 0) then
						data_sc_diff_s <= min(data_s3_i - S_MIN_G, S_MAX_G - data_s3_i);
					else
						comp1_v := round_down(real(data_s3_i-S_MIN_G+data_merr_i)/real(2*data_merr_i+1));
						comp2_v := round_down(real(S_MAX_G-data_s3_i+data_merr_i)/real(2*data_merr_i+1));
						data_sc_diff_s <= min(comp1_v, comp2_v);
					end if;
				end if;
			end if;
		end if;
	end process p_sc_diff_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_sc_diff_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s		<= '0';
				img_coord_s	<= (others => (others => 0));
			else
				valid_s		<= valid_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_sc_diff_delay;

	-- Outputs
	valid_o			<= valid_s;
	img_coord_o		<= img_coord_s;
	data_sc_diff_o	<= data_sc_diff_s;
end behavioural;