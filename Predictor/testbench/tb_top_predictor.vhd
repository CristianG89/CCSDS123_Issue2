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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.comp_top.all;
use work.comp_predictor.all;

entity tb_top_predictor is
end tb_top_predictor;

architecture behavioural of tb_top_predictor is
	signal clock_s			: std_logic := '0';
	signal reset_s			: std_logic := '1';
	signal enable_s			: std_logic := '1';

	signal img_coord_in_s	: img_coord_t := reset_img_coord;
	signal img_coord_out_s	: img_coord_t := reset_img_coord;
	signal data_s0_s		: signed(D_C-1 downto 0)	:= (others => '0'); -- "sz(t)" (original sample)
	signal data_mp_quan_s	: unsigned(D_C-1 downto 0)	:= (others => '0');	-- "?z(t)" (mapped quantizer index)

begin
	reset_s	 <= '0' after 50 ns;
	clock_s	 <= not clock_s after 6.4 ns;	 -- Main clock frequency: 78125000 Hz
	-- enable_s <= not enable_s after 20 ns; -- Enable signal toggles "randomly" to ensure it is properly delayed...
	
	-- Central local difference calculation
	p_s0_update : process(clock_s) is
		variable all_1_v	: signed(D_C-1 downto 0) := (others => '1');
		variable img_cnt_v	: integer := 0;
	begin
		if rising_edge(clock_s) then
			if (reset_s = '1') then
				data_s0_s <= (others => '0');
			else
				if (enable_s = '1') then	-- A 3D image with random values is provided (after this, nothing else)
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
		wait for 150 ns;
		assert FALSE Report "Simulation Finished" severity FAILURE;
		-- To stop simulation, and asked if to close too
		-- std.env.finish;
	end process p_stop_sim;
	
	-- Entity to control the image coordinates
	i_img_coord : img_coord_ctrl
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,

		handshake_i		=> enable_s,
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

		enable_i		=> enable_s,
		enable_o		=> open,
		
		img_coord_i		=> img_coord_in_s,
		img_coord_o		=> img_coord_out_s,
		
		data_s0_i		=> data_s0_s,
		data_mp_quan_o	=> data_mp_quan_s
	);

end behavioural;