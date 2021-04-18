--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		18/04/2021
--------------------------------------------------------------------------------
-- IP name:		hybrid_wrapper
--
-- Description: Top entity for the Hybrid Entropy Coder
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

use work.param_encoder.all;
use work.types_encoder.all;
use work.utils_encoder.all;
use work.comp_encoder.all;

entity hybrid_wrapper is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)" (mapped quantizer index)		
		rvd_codeword_o	: out unsigned(Umax_C+D_C-1 downto 0)	-- "R'k(j)" (reversed codeword)
	);
end hybrid_wrapper;

architecture behavioural of hybrid_wrapper is
	signal enable_s				: std_logic;
	signal img_coord_s			: img_coord_t;
	signal data_mp_quan_s		: unsigned(D_C-1 downto 0);
	
	signal high_res_accu_s		: integer;
	signal counter_s			: integer;
	signal entropy_select_s		: std_logic;
	signal entropy_select_prev_s: std_logic;
	
	signal rvd_codeword_high_s	: unsigned(Umax_C+D_C-1 downto 0);
	signal rvd_codeword_low_s	: unsigned(Umax_C+D_C-1 downto 0);
	signal rvd_codeword_s		: unsigned(Umax_C+D_C-1 downto 0);
	
begin
	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_hybrid_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_s		<= '0';
				img_coord_s		<= reset_img_coord;
				data_mp_quan_s	<= (others => '0');
				entropy_select_prev_s <= '0';	-- Low-Entropy Entropy method by default
			else
				enable_s		<= enable_i;
				img_coord_s		<= img_coord_i;
				data_mp_quan_s	<= data_mp_quan_i;
				entropy_select_prev_s <= entropy_select_s;
			end if;
		end if;
	end process p_hybrid_delay;
	
	i_hybrid_statistic : hybrid_statistic
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_i,
		
		img_coord_i		=> img_coord_i,
		data_mp_quan_i	=> data_mp_quan_i,
		
		high_res_accu_o	=> high_res_accu_s,
		counter_o		=> counter_s,
		entropy_select_o=> entropy_select_s
	);
	
	i_hybrid_high_entr_code : hybrid_high_entr_code
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i or (not entropy_select_s),	-- IP disabled if Low-Entropy method selected
		enable_i		=> enable_s,
		
		img_coord_i		=> img_coord_s,
		data_mp_quan_i	=> data_mp_quan_s,
		high_res_accu_i	=> high_res_accu_s,
		counter_i		=> counter_s,
		
		rvd_codeword_o	=> rvd_codeword_high_s
	);

	i_hybrid_low_entr_code : hybrid_low_entr_code
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i or entropy_select_s,			-- IP disabled if High-Entropy method selected
		enable_i		=> enable_s,
		
		img_coord_i		=> img_coord_s,
		data_mp_quan_i	=> data_mp_quan_s,
		high_res_accu_i	=> high_res_accu_s,
		counter_i		=> counter_s,
		
		rvd_codeword_o	=> rvd_codeword_low_s
	);	
	
	rvd_codeword_s <= rvd_codeword_high_s when entropy_select_prev_s = '1' else rvd_codeword_low_s;
	
	-- Outputs
	rvd_codeword_o <= rvd_codeword_s;
end behavioural;