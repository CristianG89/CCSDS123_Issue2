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
use work.comp_predictor.all;

entity mapper is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_s3_i		: in  unsigned(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i		: in  unsigned(D_C-1 downto 0);	-- "mz(t)" (maximum error)
		data_quant_i	: in  signed(D_C-1 downto 0);	-- "qz(t)" (quantizer index)
		data_mp_quan_o	: out unsigned(D_C-1 downto 0)	-- "δz(t)" (mapped quantizer index)
	);
end mapper;

architecture behavioural of mapper is	
	signal enable_s		  : std_logic;

	signal data_quant_s	  : signed(D_C-1 downto 0);
	signal data_sc_diff_s : unsigned(D_C-1 downto 0);
	signal data_mp_quan_s : unsigned(D_C-1 downto 0);
	
begin
	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_mp_quan_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_s	 <= '0';
				data_quant_s <= (others => '0');
			else
				enable_s	 <= enable_i;
				data_quant_s <= data_quant_i;
			end if;
		end if;
	end process p_mp_quan_delay;

	i_scaled_diff : scaled_diff
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_i,
		
		img_coord_i		=> img_coord_i,
		
		data_s3_i		=> data_s3_i,
		data_merr_i		=> data_merr_i,
		data_sc_diff_o	=> data_sc_diff_s
	);

	-- Mapped quantizer index value (δz(t)) calculation	
	p_mp_quan_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_mp_quan_s <= (others => '0');
			else
				if (enable_s = '1') then
					if (abs_int(to_integer(data_quant_s)) > to_integer(data_sc_diff_s)) then
						data_mp_quan_s <= to_unsigned(abs_int(to_integer(data_quant_s)) + to_integer(data_sc_diff_s), D_C);
					elsif (to_integer(data_quant_s) <= to_integer(data_sc_diff_s)) then		-- CORREGIR ESTA CONDICION!!!!!!!!!!!!
						data_mp_quan_s <= to_unsigned(2*abs_int(to_integer(data_quant_s)), D_C);
					else
						data_mp_quan_s <= to_unsigned(2*abs_int(to_integer(data_quant_s))-1, D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_mp_quan_calc;

	-- Outputs
	data_mp_quan_o <= data_mp_quan_s;
end behavioural;