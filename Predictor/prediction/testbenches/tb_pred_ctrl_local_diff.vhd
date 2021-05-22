--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		22/05/2021
--------------------------------------------------------------------------------
-- IP name:		tb_pred_ctrl_local_diff
--
-- Description: Testbench for the modules "pred_ctrl_local_diff",
--				"local_diff_vector" and "local_diff"
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

entity tb_pred_ctrl_local_diff is
    generic (
        encoded_tb_cfg	: string;
        runner_cfg		: string
    );
end tb_pred_ctrl_local_diff;

architecture behavioural of tb_pred_ctrl_local_diff is
	-- Record type to pack all signals (from Python script) together
	type tb_cfg_t is record
		SMPL_ORDER_G	: std_logic_vector(1 downto 0);
		PREDICT_MODE_G	: std_logic;
	end record tb_cfg_t;

	-- Function to decode the Python signals and connect them into the VHDL testbench
	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
		SMPL_ORDER_G	=> std_logic_vector(to_unsigned(integer'value(get(encoded_tb_cfg, "SMPL_ORDER_PY")), 2)),
		PREDICT_MODE_G	=> std_logic'value(get(encoded_tb_cfg, "PREDICT_MODE_PY"))
	);
	end function decode;

	-- Constant of type "tb_cfg_t" and initialized by "decode()" function
	constant tb_cfg			: tb_cfg_t := decode(encoded_tb_cfg);
	
	signal clock_s			: std_logic := '0';
	signal reset_s			: std_logic := '1';
	signal img_coord_in_s	: img_coord_t := reset_img_coord;
	signal img_coord_mid1_s	: img_coord_t := reset_img_coord;
	signal img_coord_mid2_s	: img_coord_t := reset_img_coord;
	signal img_coord_out_s	: img_coord_t := reset_img_coord;

	signal ldiff_pos_s		: ldiff_pos_t := reset_ldiff_pos;		-- Local differences positions
	signal ldiff_vect_s		: array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));	-- "Uz(t)" (local difference vector)
	signal data_pred_cldiff_s : signed(D_C-1 downto 0) := (others => '0');	-- "d^z(t)" (predicted central local difference)
	
	signal data_lsum_s		: signed(D_C-1 downto 0) := (others => '0');	-- "σz(t)" (Local sum)
	signal data_s2_pos_s	: s2_pos_t := reset_s2_pos;				-- Neighbour s2 positions
	signal weight_vect_s	: array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0')); -- "Wz(t)" (weight vector)

	signal flag_start, flag_middle1, flag_middle2, flag_stop : std_logic := '0';
	
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
			if run("Pred. Central Local Difference sub-blocks") then
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
	p_s2_lsum_weights_update : process(clock_s) is
	begin
		if (rising_edge(clock_s)) then
			if (reset_s = '1') then
				data_lsum_s	  <= (others => '0');
				data_s2_pos_s <= reset_s2_pos;
				weight_vect_s <= (others => (others => '0'));
			else
				if (flag_start = '1') then
					if ((img_coord_out_s.x < NX_C-1) or (img_coord_out_s.y < NY_C-1) or (img_coord_out_s.z < NZ_C-1)) then												
						if (data_lsum_s = (data_lsum_s'length-1 downto 0 => '1')) then
							data_lsum_s <= (others => '0');		
						else
							data_lsum_s <= to_signed(to_integer(data_lsum_s) + 4, data_lsum_s'length);
						end if;

						if (data_s2_pos_s.cur = integer'high-1) then
							data_s2_pos_s <= reset_s2_pos;
						else
							data_s2_pos_s.cur <= data_s2_pos_s.cur + 6;
							data_s2_pos_s.w   <= data_s2_pos_s.w   + 5;
							data_s2_pos_s.wz  <= data_s2_pos_s.wz  + 4;
							data_s2_pos_s.n   <= data_s2_pos_s.n   + 3;
							data_s2_pos_s.nw  <= data_s2_pos_s.nw  + 2;
							data_s2_pos_s.ne  <= data_s2_pos_s.ne  + 1;
						end if;
						
						for i in 0 to (weight_vect_s'length-1) loop
							if (weight_vect_s(i) = (weight_vect_s(i)'length-1 downto 0 => '1')) then
								weight_vect_s(i) <= (others => '0');		
							else
								weight_vect_s(i) <= to_signed(to_integer(weight_vect_s(i)) + 2*i+1, weight_vect_s(i)'length);
							end if;
						end loop;
					end if;
				end if;
			end if;	
		end if;
	end process p_s2_lsum_weights_update;
	
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

	i_local_diff : local_diff
	generic map(
		PREDICT_MODE_G	=> tb_cfg.PREDICT_MODE_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_start,
		enable_o		=> flag_middle1,
		img_coord_i		=> img_coord_in_s,
		img_coord_o		=> img_coord_mid1_s,
		
		data_lsum_i		=> data_lsum_s,
		data_s2_pos_i	=> data_s2_pos_s,
		ldiff_pos_o		=> ldiff_pos_s
	);

	i_ldiff_vector : local_diff_vector
	generic map(
		SMPL_ORDER_G	=> tb_cfg.SMPL_ORDER_G,
		PREDICT_MODE_G	=> tb_cfg.PREDICT_MODE_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_middle1,
		enable_o		=> flag_middle2,
		img_coord_i		=> img_coord_mid1_s,
		img_coord_o		=> img_coord_mid2_s,
		
		ldiff_pos_i		=> ldiff_pos_s,
		ldiff_vect_o	=> ldiff_vect_s
	);

	i_pred_ctrl_local_diff : pred_ctrl_local_diff
	generic map(
		PREDICT_MODE_G	=> tb_cfg.PREDICT_MODE_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_middle2,
		enable_o		=> open,
		img_coord_i		=> img_coord_mid2_s,
		img_coord_o		=> img_coord_out_s,
		
		weight_vect_i	=> weight_vect_s,
		ldiff_vect_i	=> ldiff_vect_s,
		
		data_pred_cldiff_o => data_pred_cldiff_s
	);

end behavioural;