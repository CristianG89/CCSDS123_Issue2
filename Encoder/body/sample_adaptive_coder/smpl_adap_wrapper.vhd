--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		05/04/2021
--------------------------------------------------------------------------------
-- IP name:		smpl_adap_wrapper
--
-- Description: Top entity for the Sample-Adaptive Entropy Coder
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

entity smpl_adap_wrapper is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_mp_quan_i	: in  unsigned(D_C-1 downto 0);			-- "?z(t)" (mapped quantizer index)		
		codeword_o		: out unsigned(Umax_C+D_C-1 downto 0)	-- "Rk(j)" (codeword)
	);
end smpl_adap_wrapper;

architecture behavioural of smpl_adap_wrapper is
	signal enable_s		  : std_logic;
	signal img_coord_s	  : img_coord_t;
	signal data_mp_quan_s : unsigned(D_C-1 downto 0);
	
	signal accu_s		  : integer;
	signal counter_s	  : integer;
	signal codeword_s	  : unsigned(Umax_C+D_C-1 downto 0);
	
begin
	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_smpl_adap_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_s		<= '0';
				img_coord_s		<= reset_img_coord;
				data_mp_quan_s	<= (others => '0');
			else
				enable_s		<= enable_i;
				img_coord_s		<= img_coord_i;
				data_mp_quan_s	<= data_mp_quan_i;
			end if;
		end if;
	end process p_smpl_adap_delay;

	i_smpl_adap_statistic : smpl_adap_statistic
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_i,
		
		img_coord_i		=> img_coord_i,
		data_mp_quan_i	=> data_mp_quan_i,
		accu_o			=> accu_s,
		counter_o		=> counter_s
	);

	i_smpl_adap_coding : smpl_adap_gpo2_code
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_s,
		
		img_coord_i		=> img_coord_s,
		data_mp_quan_i	=> data_mp_quan_s,
		accu_i			=> accu_s,
		counter_i		=> counter_s,
		
		codeword_o		=> codeword_s
	);

	-- Outputs
	codeword_o <= codeword_s;
end behavioural;