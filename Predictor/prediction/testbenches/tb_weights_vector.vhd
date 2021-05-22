--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		22/05/2021
--------------------------------------------------------------------------------
-- IP name:		tb_weights_vector
--
-- Description: Testbench for the modules "weights_vector",
--				"weight_upd_scal_exp" and "dbl_res_pred_error"
--
--------------------------------------------------------------------------------

-- Library instantiated, then declaration of files/functions to use
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- A reference to VUnit (and related) set of libraries and packages
library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.data_types_context;

-- Components and packages related to the Image IP
use vunit_lib.param_image.all;
use vunit_lib.types_image.all;
use vunit_lib.utils_image.all;
use vunit_lib.comp_image.all;

-- Components and packages related to the Predictor IP
use vunit_lib.param_predictor.all;
use vunit_lib.types_predictor.all;
use vunit_lib.utils_predictor.all;
use vunit_lib.comp_predictor.all;

entity tb_weights_vector is
    generic (
        encoded_tb_cfg	: string;
        runner_cfg		: string
    );
end tb_weights_vector;

architecture behavioural of tb_weights_vector is
	-- Record type to pack all signals (from Python script) together
	type tb_cfg_t is record
		SMPL_ORDER_G   : std_logic_vector(1 downto 0);
		PREDICT_MODE_G : std_logic;
		W_INIT_TYPE_G  : std_logic;
	end record tb_cfg_t;

	-- Function to decode the Python signals and connect them into the VHDL testbench
	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
		SMPL_ORDER_G   => std_logic_vector(to_unsigned(integer'value(get(encoded_tb_cfg, "SMPL_ORDER_PY")), 2)),
		PREDICT_MODE_G => std_logic'value(get(encoded_tb_cfg, "PREDICT_MODE_PY")),
		W_INIT_TYPE_G  => std_logic'value(get(encoded_tb_cfg, "W_INIT_TYPE_PY"))
	);
	end function decode;

	-- Constant of type "tb_cfg_t" and initialized by "decode()" function
	constant tb_cfg			: tb_cfg_t := decode(encoded_tb_cfg);
	
	signal clock_s			: std_logic := '0';
	signal reset_s			: std_logic := '1';
	signal img_coord_in_s	: img_coord_t := reset_img_coord;
	signal img_coord_mid_s	: img_coord_t := reset_img_coord;
	signal img_coord_out_s	: img_coord_t := reset_img_coord;
	
	signal data_w_exp_s		: signed(D_C-1 downto 0) := (others => '0');	-- "p(t)"   (weight update scaling exponent)
	signal data_pred_err_s	: signed(D_C-1 downto 0) := (others => '0');	-- "ez(t)"	(double-resolution prediction error)
	signal weight_vect_s	: array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0')); -- "Wz(t)" (weight vector)
	
	signal data_s1_s		: signed(D_C-1 downto 0) := (others => '0');	-- "s'z(t)"	(clipped quantizer bin center)
	signal data_s4_s		: signed(D_C-1 downto 0) := (others => '0');	-- "s~z(t)" (double-resolution predicted sample)
	signal ldiff_vect_s		: array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));	-- "Uz(t)" (local difference vector)

	signal flag_start, flag_middle, flag_stop : std_logic := '0';
	
	constant SMPL_LIMIT_C : smpl_lim_t := (
		min => -2**(D_C-1),
		mid => 0,
		max => 2**(D_C-1)-1
	);

begin
	reset_s <= '0' after 20 ns;
	clock_s <= not clock_s after 6.4 ns;	 -- Main clock frequency: 78125000 Hz
	
	-- Simulation MAIN process (if this one finishes, the whole simulation too)
	test_runner : process is
	begin
		-- Process starts by setting up VUnit using test_runner_setup procedure
		test_runner_setup(runner, runner_cfg);

		while test_suite loop	-- Pay very attention to the testcase name, arrows or accents prevent the system to work...
			if run("Weights Vector sub-blocks") then
				info("Running test case = " & to_string(running_test_case));

				flag_start <= '1';
			end if;
			
			wait until (flag_stop = '1');
		end loop;

		-- The process ends with the test_runner_cleanup procedure which will force the simulation to stop
		test_runner_cleanup(runner);
	end process;

	-- Set Watchdog with limited time (this number must be higher as any "wait for" statement used in the testbench)
	test_runner_watchdog(runner, 1 ms);

	-- Input signals stimulus calculation
	p_s0_lsum_cldiff_update : process(clock_s) is
	begin
		if (rising_edge(clock_s)) then
			if (reset_s = '1') then
				data_s1_s	 <= (others => '0');
				data_s4_s	 <= (others => '0');
				ldiff_vect_s <= (others => (others => '0'));
			else
				if (flag_start = '1') then
					if ((img_coord_out_s.x < NX_C-1) or (img_coord_out_s.y < NY_C-1) or (img_coord_out_s.z < NZ_C-1)) then												
						if (data_s1_s = (data_s1_s'length-1 downto 0 => '1')) then
							data_s1_s <= (others => '0');		
						else	-- According to design, it is important here that: data_s1_s > data_s4_s
							data_s1_s <= to_signed(to_integer(data_s1_s) + 4, data_s1_s'length);
						end if;
						
						if (data_s4_s = (data_s4_s'length-1 downto 0 => '1')) then
							data_s4_s <= (others => '0');		
						else
							data_s4_s <= to_signed(to_integer(data_s4_s) + 2, data_s4_s'length);
						end if;
						
						for i in 0 to (ldiff_vect_s'length-1) loop
							if (ldiff_vect_s(i) = (ldiff_vect_s(i)'length-1 downto 0 => '1')) then
								ldiff_vect_s(i) <= (others => '0');		
							else
								ldiff_vect_s(i) <= to_signed(to_integer(ldiff_vect_s(i)) + 2*i+1, ldiff_vect_s(i)'length);
							end if;
						end loop;
					end if;
				end if;
			end if;	
		end if;
	end process p_s0_lsum_cldiff_update;
	
	-- Process to stop the simulation when finished (to use 'wait' statements, the process cannot be clocked)
	p_stop_sim : process is
	begin
		-- After one complete image, wait statement and request to finish the simulation
		wait until ((img_coord_out_s.x >= NX_C-1) and (img_coord_out_s.y >= NY_C-1) and (img_coord_out_s.z >= NZ_C-1));
		wait for 10 ns;
		flag_stop <= '1';
		
		-- Two possibilities to stop the simulation without VUnit framework (only the "assert" line really works, anyway)
		-- assert FALSE Report "Simulation Finished" severity FAILURE;
		-- std.env.finish;
	end process p_stop_sim;	
	
	-- Entity to control the image coordinates
	i_img_coord : img_coord_ctrl
	generic map(
		SMPL_ORDER_G	=> tb_cfg.SMPL_ORDER_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,

		handshake_i		=> flag_start,
		w_valid_i		=> '0',
		ready_o			=> open,

		img_coord_o		=> img_coord_in_s
	);

	i_weight_upd_scal_exp : weight_upd_scal_exp
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_start,
		enable_o		=> flag_middle,
		img_coord_i		=> img_coord_in_s,
		img_coord_o		=> img_coord_mid_s,
		
		data_w_exp_o	=> data_w_exp_s
	);

	i_dbl_res_pred_error : dbl_res_pred_error
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_start,
		enable_o		=> open,
		img_coord_i		=> img_coord_in_s,
		img_coord_o		=> open,
		
		data_s1_i		=> data_s1_s,
		data_s4_i		=> data_s4_s,
		data_pred_err_o	=> data_pred_err_s
	);

	i_weights_vector : weights_vector
	generic map(
		PREDICT_MODE_G	=> tb_cfg.PREDICT_MODE_G,
		W_INIT_TYPE_G	=> tb_cfg.W_INIT_TYPE_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_middle,
		enable_o		=> open,
		img_coord_i		=> img_coord_mid_s,
		img_coord_o		=> img_coord_out_s,
		
		data_w_exp_i	=> data_w_exp_s,
		data_pred_err_i	=> data_pred_err_s,
		ldiff_vect_i	=> ldiff_vect_s,
		weight_vect_o	=> weight_vect_s
	);

end behavioural;