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
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.types_predictor.all;
use work.comp_predictor.all;

entity mapper is
	generic (
		SMPL_LIMIT_G	: smpl_lim_t
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		
		enable_i		: in  std_logic;
		enable_o		: out std_logic;
		img_coord_i		: in  img_coord_t;
		img_coord_o		: out img_coord_t;
		
		data_s3_i		: in  signed(D_C-1 downto 0);	-- "s^z(t)" (predicted sample)
		data_merr_i		: in  signed(D_C-1 downto 0);	-- "mz(t)" (maximum error)
		data_quant_i	: in  signed(D_C-1 downto 0);	-- "qz(t)" (quantizer index)
		data_mp_quan_o	: out unsigned(D_C-1 downto 0)	-- "δz(t)" (mapped quantizer index)
	);
end mapper;

architecture behavioural of mapper is	
	signal enable_s		  : std_logic := '0';
	signal img_coord_s	  : img_coord_t := reset_img_coord;

	signal data_quant_s	  : signed(D_C-1 downto 0) := (others => '0');
	signal data_sc_diff_s : signed(D_C-1 downto 0) := (others => '0');
	signal data_mp_quan_s : signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Scaled difference (θz(t)) calculation
	i_scaled_diff : scaled_diff
	generic map(
		SMPL_LIMIT_G	=> SMPL_LIMIT_G
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		
		enable_i		=> enable_i,
		enable_o		=> enable_s,
		img_coord_i		=> img_coord_i,
		img_coord_o		=> img_coord_s,
		
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
					if (abs(data_quant_s) > data_sc_diff_s) then
						data_mp_quan_s <= resize(abs(data_quant_s) + data_sc_diff_s, D_C);
					elsif (data_quant_s <= data_sc_diff_s) then						-- REVISAR ESTA CONDICION!!!!!!
						data_mp_quan_s <= resize(n2_C*abs(data_quant_s), D_C);
					else
						data_mp_quan_s <= resize(n2_C*abs(data_quant_s)-n1_C, D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_mp_quan_calc;

	-- Outputs
	enable_o		<= enable_s;
	img_coord_o		<= img_coord_s;
	data_mp_quan_o	<= unsigned(data_mp_quan_s);
end behavioural;