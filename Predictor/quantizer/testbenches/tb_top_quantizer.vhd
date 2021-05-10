--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		10/05/2021
--------------------------------------------------------------------------------
-- IP name:		tb_top_quantizer
--
-- Description: Testbench for the "quantizer" module
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

entity tb_top_quantizer is
    generic (
        encoded_tb_cfg	: string;
        runner_cfg		: string
    );
end tb_top_quantizer;

architecture behavioural of tb_top_quantizer is
	-- Record type to pack all signals (from Python script) together
	type tb_cfg_t is record
		FIDEL_TYPE_G	: integer;
		ABS_ERR_TYPE_G	: std_logic;
		REL_ERR_TYPE_G	: std_logic;
	end record tb_cfg_t;

	-- Function to decode the Python signals and connect them into the VHDL testbench
	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
		FIDEL_TYPE_G	=> integer'value(get(encoded_tb_cfg, "FIDEL_TYPE_PY")),
		ABS_ERR_TYPE_G	=> std_logic'value(get(encoded_tb_cfg, "ABS_ERR_TYPE_PY")),
		REL_ERR_TYPE_G	=> std_logic'value(get(encoded_tb_cfg, "REL_ERR_TYPE_PY"))
	);
	end function decode;

	-- Constant of type "tb_cfg_t" and initialized by "decode()" function
	constant tb_cfg		: tb_cfg_t := decode(encoded_tb_cfg);
	
	signal clock_s		: std_logic := '0';
	signal reset_s		: std_logic := '1';

	signal img_coord_s	: img_coord_t := reset_img_coord;
	signal data_s3_s	: signed(D_C-1 downto 0) := (others => '0');	-- "s^z(t)" (predicted sample)
	signal data_res_s	: signed(D_C-1 downto 0) := (others => '0');	-- "/\z(t)" (prediction residual)
	signal data_merr_s	: signed(D_C-1 downto 0) := (others => '0');	-- "mz(t)" (maximum error)
	signal data_quan_s	: signed(D_C-1 downto 0) := (others => '0');	-- "qz(t)" (quantizer index)

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
			if run("Top Quantizer Block") then
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
	p_s3_res_update : process(clock_s) is
	begin
		if (rising_edge(clock_s)) then
			if (reset_s = '1') then
				data_s3_s  <= (others => '0');
				data_res_s <= (others => '0');
				img_cnt_s  <= 0;
			else
				if (flag_start = '1') then
					if (img_cnt_s < NX_C*NY_C*NZ_C-1) then
						img_cnt_s <= img_cnt_s + 1;
						
						if (data_s3_s = (data_s3_s'length-1 downto 0 => '1')) then
							data_s3_s <= (others => '0');		
						else
							data_s3_s <= to_signed(to_integer(data_s3_s) + 1, data_s3_s'length);
						end if;
						
						if (data_res_s = (data_res_s'length-1 downto 0 => '1')) then
							data_res_s <= (others => '0');		
						else
							data_res_s <= to_signed(to_integer(data_res_s) + 3, data_res_s'length);
						end if;
					end if;
				end if;
			end if;	
		end if;
	end process p_s3_res_update;
	
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

	-- Quantizer top entity
	i_top_quantizer : quantizer
	generic map(
		FIDEL_CTRL_TYPE_G	=> std_logic_vector(to_unsigned(tb_cfg.FIDEL_TYPE_G, 2)),
		ABS_ERR_BAND_TYPE_G	=> tb_cfg.ABS_ERR_TYPE_G,
		REL_ERR_BAND_TYPE_G	=> tb_cfg.REL_ERR_TYPE_G
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		enable_i		=> flag_start,
		
		img_coord_i		=> img_coord_s,
		data_s3_i		=> data_s3_s,
		data_res_i		=> data_res_s,
		
		data_merr_o		=> data_merr_s,
		data_quant_o	=> data_quan_s
	);

end behavioural;