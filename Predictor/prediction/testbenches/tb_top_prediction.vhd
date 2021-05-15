--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		15/05/2021
--------------------------------------------------------------------------------
-- IP name:		tb_top_prediction
--
-- Description: Testbench for the "prediction" module
--
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

entity tb_top_prediction is
    generic (
        encoded_tb_cfg	: string;
        runner_cfg		: string
    );
end tb_top_prediction;

architecture behavioural of tb_top_prediction is
	-- Record type to pack all signals (from Python script) together
	type tb_cfg_t is record
		SMPL_ORDER_G	: std_logic_vector(1 downto 0);
		LSUM_TYPE_G		: std_logic_vector(1 downto 0);
		PREDICT_MODE_G	: std_logic;
		W_INIT_TYPE_G	: std_logic;
	end record tb_cfg_t;

	-- Function to decode the Python signals and connect them into the VHDL testbench
	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
		SMPL_ORDER_G	=> std_logic_vector(to_unsigned(integer'value(get(encoded_tb_cfg, "SMPL_ORDER_PY")), 2)),
		LSUM_TYPE_G		=> std_logic_vector(to_unsigned(integer'value(get(encoded_tb_cfg, "LSUM_TYPE_PY")), 2)),
		PREDICT_MODE_G	=> std_logic'value(get(encoded_tb_cfg, "PREDICT_MODE_PY")),
		W_INIT_TYPE_G	=> std_logic'value(get(encoded_tb_cfg, "W_INIT_TYPE_PY"))
	);
	end function decode;

	-- Constant of type "tb_cfg_t" and initialized by "decode()" function
	constant tb_cfg		: tb_cfg_t := decode(encoded_tb_cfg);
	
	signal clock_s		: std_logic := '0';
	signal reset_s		: std_logic := '1';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_s0_s	: signed(D_C-1 downto 0) := (others => '0');  -- "sz(t)"   (original sample)
	signal data_s1_s	: signed(D_C-1 downto 0) := (others => '0');  -- "s'z(t)"  (clipped quantizer bin center)
	signal data_s2_s	: signed(D_C-1 downto 0) := (others => '0');  -- "s''z(t)" (sample representative)
	signal data_s3_s	: signed(D_C-1 downto 0) := (others => '0');  -- "s^z(t)"  (predicted sample)
	signal data_s6_s	: signed(Re_C-1 downto 0):= (others => '0');  -- "s)z(t)"  (high-resolution predicted sample)

	signal img_cnt_s 	: integer := 0;
	signal flag_start, flag_stop : std_logic := '0';

	constant SMPL_ORDER_C : std_logic_vector(1 downto 0) := BSQ_C;

begin
	reset_s <= '0' after 20 ns;
	clock_s <= not clock_s after 6.4 ns;	 -- Main clock frequency: 78125000 Hz
	
	-- Simulation MAIN process (if this one finishes, the whole simulation too)
	test_runner : process is
	begin
		-- Process starts by setting up VUnit using test_runner_setup procedure
		test_runner_setup(runner, runner_cfg);

		while test_suite loop	-- Pay very attention to the testcase name, arrows or accents prevent the system to work...
			if run("Top Prediction Block") then
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
	p_sX_update : process(clock_s) is
	begin
		if (rising_edge(clock_s)) then
			if (reset_s = '1') then
				data_s0_s  <= (others => '0');
				data_s1_s  <= (others => '0');
				data_s2_s  <= (others => '0');
				img_cnt_s  <= 0;
			else
				if (flag_start = '1') then
					if (img_cnt_s < NX_C*NY_C*NZ_C-1) then
						img_cnt_s <= img_cnt_s + 1;
						
						if (data_s0_s = (data_s0_s'length-1 downto 0 => '1')) then
							data_s0_s <= (others => '0');		
						else
							data_s0_s <= to_signed(to_integer(data_s0_s) + 1, data_s0_s'length);
						end if;

						if (data_s1_s = (data_s1_s'length-1 downto 0 => '1')) then
							data_s1_s <= (others => '0');		
						else
							data_s1_s <= to_signed(to_integer(data_s1_s) + 2, data_s1_s'length);
						end if;
						
						if (data_s2_s = (data_s2_s'length-1 downto 0 => '1')) then
							data_s2_s <= (others => '0');		
						else
							data_s2_s <= to_signed(to_integer(data_s2_s) + 3, data_s2_s'length);
						end if;
					end if;
				end if;
			end if;	
		end if;
	end process p_sX_update;
	
	-- Process to stop the simulation when finished (to use 'wait' statements, the process cannot be clocked)
	p_stop_sim : process is
	begin
		-- After one complete image, wait statement and request to finish the simulation
		wait until (img_cnt_s >= NX_C*NY_C*NZ_C-1);
		wait for 10 ns;
		flag_stop <= '1';
		
		-- Two possibilities to stop the simulation without VUnit framework (only the "assert" line really works, anyway)
		-- assert FALSE Report "Simulation Finished" severity FAILURE;
		-- std.env.finish;
	end process p_stop_sim;	
	
	-- Entity to control the image coordinates
	i_img_coord : img_coord_ctrl
	generic map(
		SMPL_ORDER_G	=> SMPL_ORDER_C
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,

		handshake_i		=> flag_start,
		w_valid_i		=> '0',
		ready_o			=> open,

		img_coord_o		=> img_coord_s
	);

	-- Prediction top entity
	i_prediction : prediction
	generic map(
		SMPL_ORDER_G	=> tb_cfg.SMPL_ORDER_G,
		LSUM_TYPE_G		=> tb_cfg.LSUM_TYPE_G,
		PREDICT_MODE_G	=> tb_cfg.PREDICT_MODE_G,
		W_INIT_TYPE_G	=> tb_cfg.W_INIT_TYPE_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		enable_i		=> flag_start,
		
		img_coord_i		=> img_coord_s,
		data_s0_i		=> data_s0_s,
		data_s1_i		=> data_s1_s,
		data_s2_i		=> data_s2_s,
		
		data_s3_o		=> data_s3_s,
		data_s6_o		=> data_s6_s
	);

end behavioural;