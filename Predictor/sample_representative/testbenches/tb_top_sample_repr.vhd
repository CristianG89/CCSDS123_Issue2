--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		15/05/2021
--------------------------------------------------------------------------------
-- IP name:		tb_top_sample_repr
--
-- Description: Testbench for the "sample representative" module
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

entity tb_top_sample_repr is
    generic (
        encoded_tb_cfg	: string;
        runner_cfg		: string
    );
end tb_top_sample_repr;

architecture behavioural of tb_top_sample_repr is
	-- Record type to pack all signals (from Python script) together
	type tb_cfg_t is record
		VAR1_G : std_logic;
		VAR2_G : std_logic;
	end record tb_cfg_t;

	-- Function to decode the Python signals and connect them into the VHDL testbench
	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
		VAR1_G => std_logic'value(get(encoded_tb_cfg, "VAR1_PY")),
		VAR2_G => std_logic'value(get(encoded_tb_cfg, "VAR2_PY"))
	);
	end function decode;

	-- Constant of type "tb_cfg_t" and initialized by "decode()" function
	constant tb_cfg		  : tb_cfg_t := decode(encoded_tb_cfg);
	
	signal clock_s		  : std_logic := '0';
	signal reset_s		  : std_logic := '1';
	signal img_coord_in_s : img_coord_t := reset_img_coord;
	signal img_coord_out_s: img_coord_t := reset_img_coord;
	
	signal data_s0_s	  : signed(D_C-1 downto 0)  := (others => '0');	-- "sz(t)"	 (original sample)
	signal data_s1_s	  : signed(D_C-1 downto 0)  := (others => '0');	-- "s'z(t)"  (clipped quantizer bin center)
	signal data_s2_s	  : signed(D_C-1 downto 0)  := (others => '0');	-- "s''z(t)" (sample representative)
	signal data_s3_s	  : signed(D_C-1 downto 0)  := (others => '0');	-- "s^z(t)"  (predicted sample)
	signal data_s6_s	  : signed(Re_C-1 downto 0) := (others => '0');	-- "s)z(t)"	 (high-resolution predicted sample)
	signal data_merr_s	  : signed(D_C-1 downto 0)  := (others => '0');	-- "mz(t)"  (maximum error)
	signal data_quan_s	  : signed(D_C-1 downto 0)  := (others => '0');	-- "qz(t)"  (quantizer index)
	signal data_mp_quan_s : unsigned(D_C-1 downto 0):= (others => '0');	-- "δz(t)"  (mapped quantizer index)

	signal flag_start, flag_stop : std_logic := '0';

	constant SMPL_ORDER_C : std_logic_vector(1 downto 0) := BSQ_C;
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
			if run("Top Sample Representative Block") then
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
	p_sX_merr_quan_update : process(clock_s) is
	begin
		if (rising_edge(clock_s)) then
			if (reset_s = '1') then
				data_s0_s	<= (others => '0');
				data_s3_s	<= (others => '0');
				data_s6_s	<= (others => '0');
				data_quan_s <= (others => '0');
				data_merr_s <= (others => '1');
			else
				if (flag_start = '1') then
					if ((img_coord_out_s.x < NX_C-1) or (img_coord_out_s.y < NY_C-1) or (img_coord_out_s.z < NZ_C-1)) then						
						if (data_s0_s = (data_s0_s'length-1 downto 0 => '1')) then
							data_s0_s <= (others => '0');		
						else
							data_s0_s <= to_signed(to_integer(data_s0_s) + 1, data_s0_s'length);
						end if;
						
						if (data_s3_s = (data_s3_s'length-1 downto 0 => '1')) then
							data_s3_s <= (others => '0');		
						else
							data_s3_s <= to_signed(to_integer(data_s3_s) + 4, data_s3_s'length);
						end if;
						
						if (data_s6_s = (data_s6_s'length-1 downto 0 => '1')) then
							data_s6_s <= (others => '0');		
						else
							data_s6_s <= to_signed(to_integer(data_s6_s) + 5, data_s6_s'length);
						end if;
						
						if (data_quan_s = (data_quan_s'length-1 downto 0 => '1')) then
							data_quan_s <= (others => '0');		
						else
							data_quan_s <= to_signed(to_integer(data_quan_s) + 6, data_quan_s'length);
						end if;
					end if;
				end if;
			end if;	
		end if;
	end process p_sX_merr_quan_update;
	
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
		SMPL_ORDER_G	=> SMPL_ORDER_C
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,

		handshake_i		=> flag_start,
		w_valid_i		=> '0',
		ready_o			=> open,

		img_coord_o		=> img_coord_in_s
	);

	-- Sample Representative top entity
	i_top_sample_repr : sample_representative
	generic map(
		SMPL_LIMIT_G	=> SMPL_LIMIT_C
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		
		enable_i		=> flag_start,
		enable_o		=> open,
		img_coord_i		=> img_coord_in_s,
		img_coord_o		=> img_coord_out_s,
		
		data_merr_i		=> data_merr_s,
		data_quant_i	=> data_quan_s,
		data_s0_i		=> data_s0_s,
		data_s3_i		=> data_s3_s,
		data_s6_i		=> data_s6_s,

		data_s1_o		=> data_s1_s,
		data_s2_o		=> data_s2_s
	);

end behavioural;