--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		weight_upd_scal_exp
--
-- Description: Computes the weight update scaling exponent "Ï?(t)"
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

entity weight_upd_scal_exp is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;
		
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;
		
		data_w_exp_o: out std_logic_vector(D_C-1 downto 0)	-- "Ï?(t)" (weight update scaling exponent)
	);
end weight_upd_scal_exp;

architecture behavioural of weight_upd_scal_exp is
	signal valid_s		: std_logic;
	signal img_coord_s	: img_coord_t;
	signal data_w_exp_s	: std_logic_vector(D_C-1 downto 0);
	
begin
	-- Weight update scaling exponent value (Ï?(t)) calculation	
	p_w_upd_scal_exp_calc : process(clock_i) is
		variable comp1_v : integer := 0;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v := 0;
				data_w_exp_s <= (others => '0');
			else
				if (valid_i = '1') then
					if (img_coord_i.t > 0) then
						comp1_v := round_down(real(img_coord_i.t-NX_C)/real(T_INC_C));
						data_w_exp_s <= clip(V_MIN_C+comp1_v, V_MIN_C, V_MAX_C) + D_C - OMEGA_C;
					else
						data_w_exp_s <= (others => '0');	-- SEGURO????
					end if;
				end if;
			end if;
		end if;
	end process p_w_upd_scal_exp_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_w_upd_scal_exp_delay : process(clock_i) is
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
	end process p_w_upd_scal_exp_delay;

	-- Outputs
	valid_o		 <= valid_s;
	img_coord_o	 <= img_coord_s;
	data_w_exp_o <= data_w_exp_s;
end behavioural;