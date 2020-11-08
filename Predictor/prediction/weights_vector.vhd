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
use work.utils.all;
use work.types.all;
use work.param_image.all;
use work.param_predictor.all;

entity weights_vector is
	generic (
		W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		valid_i			: in  std_logic;
		
		img_coord_i		: in  img_coord_t;
		data_w_exp_i	: in  unsigned(D_C-1 downto 0);				-- "p(t)" (weight update scaling exponent)
		data_pred_err_i : in  unsigned(D_C-1 downto 0);				-- "ez(t)"	(double-resolution prediction error)
		ldiff_vect_i	: in  array_unsigned_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0);	  -- "Uz(t)" (local difference vector)
		weight_vect_o	: out array_unsigned_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) --  "Wz(t)" (weight vector)
	);
end weights_vector;

architecture behavioural of weights_vector is
	-- Default weight values initialization function
	pure function init_def_weight_vec return array_unsigned_t is
		variable def_weight_vect_v : array_unsigned_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0);
	begin
		-- Directional weight values (wN, wW, wNW) are all set to 0
		def_weight_vect_v(2 downto 0) := (others => to_unsigned(0, OMEGA_C+3));

		-- Normal weight values
		def_weight_vect_v(3) := to_unsigned(7/8 * 2**OMEGA_C, OMEGA_C+3);
		for i in 4 to (def_weight_vect_v'length-1) loop
			def_weight_vect_v(i) := to_unsigned(round_down(1/8 * real(to_integer(def_weight_vect_v(i-1)))), OMEGA_C+3);
		end loop;

		return def_weight_vect_v;
	end function init_def_weight_vec;

	-- Custom weight values initialization function
	pure function init_cust_weight_vec return array_unsigned_t is
		variable cust_weight_vect_v : array_unsigned_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0);
		variable all_1s_v : unsigned(OMEGA_C+3-1 downto 0) := (others => '1');
	begin
		for i in 0 to (cust_weight_vect_v'length-1) loop
			cust_weight_vect_v(i) := to_unsigned(2**(OMEGA_C+3-Q_C)*to_integer(LAMBDA_C(i)) + round_up(real(2**(OMEGA_C+2-Q_C)-1))*to_integer(all_1s_v), D_C);
		end loop;

		return cust_weight_vect_v;
	end function init_cust_weight_vec;

	signal curr_weight_vect_s : array_unsigned_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0);
	signal prev_weight_vect_s : array_unsigned_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0);
	
begin
	-- Weight vector value (Wz(t)) calculation	
	p_weight_vect_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				curr_weight_vect_s <= (others => (others => '0'));
			else
				if (valid_i = '1') then
					if (img_coord_i.t = 0) then
						if (W_INIT_TYPE_G = '1') then
							curr_weight_vect_s <= init_cust_weight_vec;
						else
							curr_weight_vect_s <= init_def_weight_vec;
						end if;
					else
						-- Next directional weight values (wN, wW, wNW)
						curr_weight_vect_s(0) <= to_unsigned(clip(to_integer(prev_weight_vect_s(0))+round_down(0.5*real(sgnp(to_integer(data_pred_err_i))*2**(-(to_integer(data_w_exp_i)+C_C))*to_integer(ldiff_vect_i(0)))+1.0), to_integer(W_MIN_C), to_integer(W_MAX_C)), D_C);
						curr_weight_vect_s(1) <= to_unsigned(clip(to_integer(prev_weight_vect_s(1))+round_down(0.5*real(sgnp(to_integer(data_pred_err_i))*2**(-(to_integer(data_w_exp_i)+C_C))*to_integer(ldiff_vect_i(1)))+1.0), to_integer(W_MIN_C), to_integer(W_MAX_C)), D_C);
						curr_weight_vect_s(2) <= to_unsigned(clip(to_integer(prev_weight_vect_s(2))+round_down(0.5*real(sgnp(to_integer(data_pred_err_i))*2**(-(to_integer(data_w_exp_i)+C_C))*to_integer(ldiff_vect_i(2)))+1.0), to_integer(W_MIN_C), to_integer(W_MAX_C)), D_C);
						-- Next normal weight values
						for i in 3 to (curr_weight_vect_s'length-1) loop
							curr_weight_vect_s(i) <= to_unsigned(clip(to_integer(prev_weight_vect_s(i))+round_down(0.5*real(sgnp(to_integer(data_pred_err_i))*2**(-(to_integer(data_w_exp_i)+Ci_C))*to_integer(ldiff_vect_i(i)))+1.0), to_integer(W_MIN_C), to_integer(W_MAX_C)), D_C);
						end loop;
					end if;
				end if;
			end if;
		end if;
	end process p_weight_vect_calc;

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

	-- Outputs
	weight_vect_o <= curr_weight_vect_s;
end behavioural;