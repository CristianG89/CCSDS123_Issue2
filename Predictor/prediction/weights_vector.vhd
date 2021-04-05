--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		06/11/2020
--------------------------------------------------------------------------------
-- IP name:		weights_vector
--
-- Description: Computes the weight vector "Wz(t)"
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

use work.param_predictor.all;
use work.types_predictor.all;
use work.utils_predictor.all;

entity weights_vector is
	generic (
		W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		enable_i		: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_w_exp_i	: in  signed(D_C-1 downto 0);				-- "p(t)"  (weight update scaling exponent)
		data_pred_err_i : in  signed(D_C-1 downto 0);				-- "ez(t)" (double-resolution prediction error)
		ldiff_vect_i	: in  array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0);		-- "Uz(t)" (local difference vector)
		weight_vect_o	: out array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) -- "Wz(t)" (weight vector)
	);
end weights_vector;

architecture behavioural of weights_vector is
	-- Default weight values initialization function
	pure function init_def_weight_vec return array_signed_t is
		variable def_weight_vect_v : array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0'));
	begin
		-- Directional weight values (wN, wW, wNW) are all set to 0
		def_weight_vect_v(2 downto 0) := (others => (others => '0'));

		-- Normal weight values
		def_weight_vect_v(3) := to_signed(7/8 * 2**OMEGA_C, OMEGA_C+3);
		for i in 4 to (def_weight_vect_v'length-1) loop
			def_weight_vect_v(i) := round_down(def_weight_vect_v(i-1), to_signed(8, 4));
		end loop;

		return def_weight_vect_v;
	end function init_def_weight_vec;

	-- Custom weight values initialization function
	pure function init_cust_weight_vec return array_signed_t is
		variable cust_weight_vect_v : array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0'));
		variable all_1s_v : signed(OMEGA_C+3-1 downto 0) := (others => '1');
	begin
		for i in 0 to (cust_weight_vect_v'length-1) loop	-- Here there was an useless (no division) round_up, so it was removed
			cust_weight_vect_v(i) := resize(to_signed(2**(OMEGA_C+3-Q_C), OMEGA_C+3) * LAMBDA_C(i) + to_signed(2**(OMEGA_C+2-Q_C)-1, OMEGA_C+3) * all_1s_v, OMEGA_C+3);
		end loop;

		return cust_weight_vect_v;
	end function init_cust_weight_vec;

	signal curr_weight_vect_s : array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0'));
	signal prev_weight_vect_s : array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0'));

begin
	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_weight_vect_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				prev_weight_vect_s <= (others => (others => '0'));
			else
				prev_weight_vect_s <= curr_weight_vect_s;
			end if;
		end if;
	end process p_weight_vect_delay;

	-- Weight vector value (Wz(t)) calculation	
	p_weight_vect_calc : process(clock_i) is
		variable comp1_v, comp2_v, comp3_v : integer;
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				comp1_v := 0;
				comp2_v := 0;
				comp3_v := 0;
				curr_weight_vect_s <= (others => (others => '0'));
			else
				if (enable_i = '1') then
					if (img_coord_i.t = 0) then
						if (W_INIT_TYPE_G = '1') then
							curr_weight_vect_s <= init_cust_weight_vec;
						else
							curr_weight_vect_s <= init_def_weight_vec;
						end if;
					else
						comp1_v := to_integer(sgnp(data_pred_err_i));
						comp2_v := 2**((to_integer(data_w_exp_i)+C_C));
						comp3_v := 2**((to_integer(data_w_exp_i)+Ci_C));
						
						-- Next directional weight values (wN, wW, wNW)
						curr_weight_vect_s(0) <= clip(prev_weight_vect_s(0)+to_signed(round_down(comp1_v*comp2_v*to_integer(ldiff_vect_i(0))+1, 2), D_C), W_MIN_C, W_MAX_C);
						curr_weight_vect_s(1) <= clip(prev_weight_vect_s(1)+to_signed(round_down(comp1_v*comp2_v*to_integer(ldiff_vect_i(1))+1, 2), D_C), W_MIN_C, W_MAX_C);
						curr_weight_vect_s(2) <= clip(prev_weight_vect_s(2)+to_signed(round_down(comp1_v*comp2_v*to_integer(ldiff_vect_i(2))+1, 2), D_C), W_MIN_C, W_MAX_C);
						-- Next normal weight values
						for i in 3 to (curr_weight_vect_s'length-1) loop
							curr_weight_vect_s(i) <= clip(prev_weight_vect_s(i)+to_signed(round_down(comp1_v*comp3_v*to_integer(ldiff_vect_i(i))+1, 2), D_C), W_MIN_C, W_MAX_C);
						end loop;
					end if;
				end if;
			end if;
		end if;
	end process p_weight_vect_calc;

	-- Outputs
	weight_vect_o <= curr_weight_vect_s;
end behavioural;