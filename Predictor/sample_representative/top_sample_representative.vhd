--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		sample_representative
--
-- Description: Computes the sample_representative "s''z(t)"
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.types.all;
use work.param_image.all;

entity sample_representative is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;
		
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_s0_i	: in  std_logic_vector(D_C-1 downto 0);	-- "sz(t)"	  (original sample)
		data_s5_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s~''z(t)" (double-resolution sample representative)
		data_s2_o	: out std_logic_vector(D_C-1 downto 0)	-- "s''z(t)"  (sample representative)
	);
end sample_representative;

architecture behavioural of sample_representative is
	signal valid_s		: std_logic;
	signal img_coord_s	: img_coord_t;
	signal data_s2_s	: std_logic_vector(D_C-1 downto 0);
	
begin
	-- Sample representative (s''z(t)) calculation
	p_smpl_repr_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s2_s <= (others => '0');
			else
				if (valid_i = '1') then
					if (img_coord_i.t = 0) then
						data_s2_s <= data_s0_i;
					else
						data_s2_s <= round_down(real(data_s5_i+1)/2.0);
					end if;
				end if;
			end if;
		end if;
	end process p_smpl_repr_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_smpl_repr_delay : process(clock_i) is
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
	end process p_smpl_repr_delay;

	-- Outputs
	valid_o		<= valid_s;
	img_coord_o	<= img_coord_s;
	data_s2_o	<= data_s2_s;
end behavioural;