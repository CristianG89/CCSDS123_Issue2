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
use work.comp_predictor.all;
	
entity quantizer is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
	);
	port (
		clock_i		 : in  std_logic;
		reset_i		 : in  std_logic;
		valid_i 	 : in  std_logic;
		
		img_coord_i	 : in  img_coord_t;		
		data_s3_i	 : in  unsigned(D_C-1 downto 0); -- "s^z(t)" (predicted sample)
		data_res_i	 : in  unsigned(D_C-1 downto 0); -- "/\z(t)" (prediction residual)
		
		data_merr_o	 : out unsigned(D_C-1 downto 0); -- "mz(t)" (maximum error)
		data_quant_o : out signed(D_C-1 downto 0)	 -- "qz(t)" (quantizer index)
	);
end quantizer;

architecture behavioural of quantizer is
	constant PROC_TIME_C : integer := 2;	-- Clock cycles used to completely process "Quantizer"
	
	signal valid_ar_s	 : std_logic_vector(PROC_TIME_C-1 downto 0);
	signal img_coord_ar_s: img_coord_ar_t(PROC_TIME_C-1 downto 0);
	
	signal data_merr_s	 : unsigned(D_C-1 downto 0);
	signal data_res_s	 : unsigned(D_C-1 downto 0);
	signal data_quant_s	 : signed(D_C-1 downto 0);

begin
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_quant_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_ar_s		<= (others => '0');
				img_coord_ar_s	<= (others => reset_img_coord);
				data_res_s		<= (others => '0');
			else
				data_res_s		  <= data_res_i;
				valid_ar_s(0)	  <= valid_i;
				img_coord_ar_s(0) <= img_coord_i;
				for i in 1 to (PROC_TIME_C-1) loop
					valid_ar_s(i)	  <= valid_ar_s(i-1);
					img_coord_ar_s(i) <= img_coord_ar_s(i-1);
				end loop;
			end if;
		end if;
	end process p_quant_delay;
	
	i_fidel_ctrl : fidelity_ctrl
	generic map(
		FIDEL_CTRL_TYPE_G => FIDEL_CTRL_TYPE_G
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		valid_i		=> valid_i,
		
		data_s3_i	=> data_s3_i,
		data_merr_o	=> data_merr_s
	);

	-- Quantizer index (qz(t)) calculation
	p_quant_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_quant_s <= (others => '0');
			else
				if (valid_ar_s(0) = '1') then
					if (img_coord_ar_s(0).t = 0) then
						data_quant_s <= signed(data_res_s);
					else
						data_quant_s <= to_signed(sgn(to_integer(data_res_s))*round_down(real(abs_int(to_integer(data_res_s))+to_integer(data_merr_s))/real(2*to_integer(data_merr_s)+1)), D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_quant_calc;
	
	-- Outputs
	data_merr_o	 <= data_merr_s;
	data_quant_o <= data_quant_s;
end behavioural;