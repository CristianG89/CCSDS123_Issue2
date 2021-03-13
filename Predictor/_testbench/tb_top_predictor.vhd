--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		15/11/2020
--------------------------------------------------------------------------------
-- IP name:		tb_top_predictor
--
-- Description: Testbench for the "predictor" module (top entity)
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

-- Components and packages related to the Predictor IP
use vunit_lib.types_predictor.all;
use vunit_lib.utils_predictor.all;
use vunit_lib.param_image.all;
use vunit_lib.comp_top.all;
use vunit_lib.comp_predictor.all;

entity tb_top_predictor is
    generic (
        encoded_tb_cfg	: string;
        runner_cfg		: string
    );
end tb_top_predictor;

architecture behavioural of tb_top_predictor is
-- Record type to pack all signals (from Python script) together
	type tb_cfg_t is record
		EX1_G : std_logic;
		EX2_G : std_logic;
	end record tb_cfg_t;

	-- Function to decode the Python signals and connect them into the VHDL testbench
	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
		EX1_G => std_logic'value(get(encoded_tb_cfg, "EX1_PY")),
		EX2_G => std_logic'value(get(encoded_tb_cfg, "EX2_PY")));
	end function decode;

	-- Constant of type "tb_cfg_t" and initialized by "decode()" function
	constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);
	
	signal clock_s			: std_logic := '0';
	signal reset_s			: std_logic := '1';

	signal img_coord_in_s	: img_coord_t := reset_img_coord;
	signal img_coord_out_s	: img_coord_t := reset_img_coord;
	signal data_s0_s		: signed(D_C-1 downto 0)	:= (others => '0'); -- "sz(t)" (original sample)
	signal data_mp_quan_s	: unsigned(D_C-1 downto 0)	:= (others => '0');	-- "?z(t)" (mapped quantizer index)
	
	signal flag_start, flag_stop : std_logic := '0';

begin
	reset_s	 <= '0' after 50 ns;
	clock_s	 <= not clock_s after 6.4 ns;	 -- Main clock frequency: 78125000 Hz
	
	-- Simulation MAIN process (if this one finishes, the whole simulation too)
	test_runner : process is
	begin
		-- Process starts by setting up VUnit using test_runner_setup procedure
		test_runner_setup(runner, runner_cfg);

		while test_suite loop	-- Pay very attention to the name of the testcase, arrows or accents prevent the system to work...
			if run("Top Predictor Block") then
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

	-- Central local difference calculation
	p_s0_update : process(clock_s) is
		variable all_1_v	: signed(D_C-1 downto 0) := (others => '1');
		variable img_cnt_v	: integer := 0;
	begin
		if (rising_edge(clock_s)) then
			if (reset_s = '1') then
				data_s0_s <= (others => '0');
			else
				if (flag_start = '1') then	-- A 3D image with random values is provided (after this, nothing else)
					if (img_cnt_v < NX_C*NY_C*NZ_C-1) then
						img_cnt_v := img_cnt_v + 1;
						if (data_s0_s = all_1_v) then
							data_s0_s <= (others => '0');		
						else
							data_s0_s <= to_signed(to_integer(data_s0_s) + 1, D_C);
						end if;
					end if;
				end if;
			end if;	
		end if;
	end process p_s0_update;
	
	-- Process to stop the simulation when finished (to use 'wait' statements, the process cannot be clocked)
	p_stop_sim : process is
	begin	
		wait until ((img_coord_out_s.x = NX_C-1) and (img_coord_out_s.y = NY_C-1) and (img_coord_out_s.z = NZ_C-1));
		wait for 50 ns;
		
		-- Request to finish the simulation
		flag_stop <= '1';
		
		-- Two possibilities to stop the simulation without VUnit framework (only the "assert" line really works, anyway)
		-- assert FALSE Report "Simulation Finished" severity FAILURE;
		-- std.env.finish;
	end process p_stop_sim;
	
	-- Entity to control the image coordinates
	i_img_coord : img_coord_ctrl
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,

		handshake_i		=> flag_start,
		w_valid_i		=> '0',
		ready_o			=> open,

		img_coord_o		=> img_coord_in_s
	);

	-- Predictor top entity
	i_top_predictor : top_predictor
	generic map(
		FIDEL_CTRL_TYPE_G => "01",
		LSUM_TYPE_G		=> "00",
		PREDICT_MODE_G	=> '1',
		W_INIT_TYPE_G	=> '0'
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,

		enable_i		=> flag_start,
		enable_o		=> open,
		
		img_coord_i		=> img_coord_in_s,
		img_coord_o		=> img_coord_out_s,
		
		data_s0_i		=> data_s0_s,
		data_mp_quan_o	=> data_mp_quan_s
	);

end behavioural;