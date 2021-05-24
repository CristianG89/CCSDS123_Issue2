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
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.types_predictor.all;
use work.utils_predictor.all;
use work.comp_predictor.all;
	
entity quantizer is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G	: std_logic_vector(1 downto 0);
		-- 1: band-dependent, 0: band-independent (for both absolute and relative error limit assignments)
		ABS_ERR_BAND_TYPE_G	: std_logic;
		REL_ERR_BAND_TYPE_G	: std_logic
	);
	port (
		clock_i		 : in  std_logic;
		reset_i		 : in  std_logic;
		
		enable_i	 : in  std_logic;
		enable_o	 : out std_logic;
		img_coord_i	 : in  img_coord_t;
		img_coord_o	 : out img_coord_t;
		
		data_s3_i	 : in  signed(D_C-1 downto 0); -- "s^z(t)" (predicted sample)
		data_res_i	 : in  signed(D_C-1 downto 0); -- "/\z(t)" (prediction residual)
		
		data_merr_o	 : out signed(D_C-1 downto 0); -- "mz(t)" (maximum error)
		data_quant_o : out signed(D_C-1 downto 0)  -- "qz(t)" (quantizer index)
	);
end quantizer;

architecture behavioural of quantizer is
	signal enable_s			: std_logic := '0';
	signal img_coord_s		: img_coord_t := reset_img_coord;
	
	signal data_merr_s		: signed(D_C-1 downto 0) := (others => '0');
	signal data_res_prev_s	: signed(D_C-1 downto 0) := (others => '0');
	signal data_quant_s		: signed(D_C-1 downto 0) := (others => '0');

begin
	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_quant_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_res_prev_s	<= (others => '0');
			else
				data_res_prev_s	<= data_res_i;
			end if;
		end if;
	end process p_quant_delay;

	-- Maximum error (mz(t)) calculation
	i_fidel_ctrl : fidelity_ctrl
	generic map(
		FIDEL_CTRL_TYPE_G	=> FIDEL_CTRL_TYPE_G,
		ABS_ERR_BAND_TYPE_G	=> ABS_ERR_BAND_TYPE_G,
		REL_ERR_BAND_TYPE_G	=> REL_ERR_BAND_TYPE_G
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		
		enable_i	=> enable_i,
		enable_o	=> enable_s,
		img_coord_i	=> img_coord_i,
		img_coord_o	=> img_coord_s,
		
		data_s3_i	=> data_s3_i,
		data_merr_o	=> data_merr_s
	);

	-- Quantizer index (qz(t)) calculation
	p_quant_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v, comp4_v : signed(D_C-1 downto 0) := (others => '0');
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_quant_s <= (others => '0');
				comp1_v := (others => '0');
				comp2_v := (others => '0');
				comp3_v := (others => '0');
				comp4_v := (others => '0');
			else
				if (enable_s = '1') then
					if (img_coord_s.t = 0) then
						data_quant_s <= data_res_prev_s;
					else
						comp1_v := to_signed(sgn(data_res_prev_s), D_C);
						comp2_v := resize(abs(data_res_prev_s) + data_merr_s, D_C);
						comp3_v := resize(n2_C * data_merr_s + n1_C, D_C);
						comp4_v := round_down(comp2_v, comp3_v);
						data_quant_s <= resize(comp1_v * comp4_v, D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_quant_calc;
	
	-- Outputs
	enable_o	 <= enable_s;
	img_coord_o	 <= img_coord_s;
	data_merr_o	 <= data_merr_s;
	data_quant_o <= data_quant_s;
end behavioural;