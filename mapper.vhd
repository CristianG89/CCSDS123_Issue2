--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		mapper
--
-- Description: Maps the incoming quantized prediction residual 
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;

entity mapper is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		valid_i			: in  std_logic;
		valid_o			: out std_logic;
		
		data_quant_i	: in  std_logic_vector(D_C-1 downto 0);	-- "qz(t)" (quantizer index)
		data_sc_diff_i	: in  std_logic_vector(D_C-1 downto 0);	-- "θz(t)" (scaled difference)
		data_mp_quan_o	: in  std_logic_vector(D_C-1 downto 0)	-- "δz(t)" (mapped quantizer index)
	);
end mapper;

architecture behavioural of mapper is
	signal valid_s			: std_logic;
	signal data_mp_quan_s	: std_logic_vector(D_C-1 downto 0);
	
begin
	-- Mapped quantizer index value (δz(t)) calculation	
	p_mp_quan_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_mp_quan_s <= (others => '0');
			else
				if (valid_i = '1') then
					if (abs_int(data_quant_i) > data_sc_diff_i) then
						data_mp_quan_s <= abs_int(data_quant_i) + data_sc_diff_i;
					elsif (data_quant_i <= data_sc_diff_i) then		-- CORREGIR ESTA CONDICION!!!!!!!!!!!!
						data_mp_quan_s <= 2*abs_int(data_quant_i);
					else
						data_mp_quan_s <= 2*abs_int(data_quant_i)-1;
					end if;
				end if;
			end if;
		end if;
	end process p_mp_quan_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_mp_quan_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s <= '0';
			else
				valid_s <= valid_i;
			end if;
		end if;
	end process p_mp_quan_delay;

	-- Outputs
	valid_o			<= valid_s;
	data_mp_quan_o	<= data_mp_quan_s;
end behavioural;