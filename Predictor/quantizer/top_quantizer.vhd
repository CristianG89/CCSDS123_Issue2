--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		30/10/2020
--------------------------------------------------------------------------------
-- IP name:		quantizer
--
-- Description: Quantizies the incoming input with a uniform step size
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
	
entity quantizer is
	port (
		clock_i		 : in  std_logic;
		reset_i		 : in  std_logic;
		
		valid_i 	 : in  std_logic;
		valid_o		 : out std_logic;
		
		img_coord_i	 : in  img_coord_t;
		img_coord_o	 : out img_coord_t;
		
		data_res_i	 : in  std_logic_vector(D_C-1 downto 0); -- "/\z(t)" (prediction residual)
		data_merr_i	 : in  std_logic_vector(D_C-1 downto 0); -- "mz(t)" (maximum error)
		data_quant_o : out std_logic_vector(D_C-1 downto 0)	 -- "qz(t)" (quantizer index)
	);
end quantizer;

architecture behavioural of quantizer is
	signal valid_s		: std_logic;
	signal img_coord_s	: img_coord_t;
	signal data_quant_s	: std_logic_vector(D_C-1 downto 0);

begin
	-- Quantizer index (qz(t)) calculation
	p_quant_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '0') then
				data_quant_s <= (others => '1');
			else
				if (valid_i = '1') then
					if (img_coord_i.t = 0) then
						data_quant_s <= data_res_i;
					else
						data_quant_s <= sgn(data_res_i)*round_down(real(abs_int(data_res_i)+data_merr_i)/real(2*data_merr_i+1));
					end if;
				end if;
			end if;
		end if;
	end process p_quant_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_quant_delay : process(clock_i) is
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
	end process p_quant_delay;
	
	-- Outputs
	valid_o		 <= valid_s;
	img_coord_o	 <= img_coord_s;
	data_quant_o <= data_quant_s;
end behavioural;