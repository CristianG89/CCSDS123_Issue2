--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		24/10/2020
--------------------------------------------------------------------------------
-- IP name:		Control signal generation
--
-- Description: Keeps track and outputs the current image position of the cube.
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.param_image.all;
use work.param_predictor.all;

entity img_coord_ctrl is
	generic (
		CZ_G		: integer
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		handshake_i	: in  std_logic;
		w_valid_i	: in  std_logic;
		ready_o		: out std_logic;

		img_coord_o : out img_coord_t
	);
end img_coord_ctrl;

architecture Behaviour of img_coord_ctrl is
	-- Image coordinates
	signal x_s : integer range 0 to NX_C-1 := 0;
	signal y_s : integer range 0 to NY_C-1 := 0;
	signal z_s : integer range 0 to NZ_C-1 := 0;
	
	signal ready_s : std_logic;

	-- constant INCL_PIPE_CTRL_C : boolean := NZ_C < 3 + integer(ceil(log2(real(CZ_G)))) + 2 + 3;
	constant INCL_PIPE_CTRL_C : boolean := false;

begin
	-- Stall input if pipeline deeper than NZ_C, and we have filled up NZ_C components already
	-- (Local diff calc: 3 | Dot product: CZ_G | Predictor: 2 | Weight update: 3)
	g_pipe_ctrl : if (INCL_PIPE_CTRL_C) generate
		signal count_s : integer range 0 to NZ_C;
	begin
		p_pipe_ctrl : process(clock_i)
		begin
			if (rising_edge(clock_i)) then
				if (reset_i = '1') then
					count_s <= 0;
				else
					if (handshake_i = '1' and w_valid_i = '0') then
						count_s <= count_s + 1;
					elsif (handshake_i = '0' and w_valid_i = '1') then
						count_s <= count_s - 1;
					end if;
				end if;
			end if;
		end process p_pipe_ctrl;

		ready_s <= '1' when count_s < NZ_C else '0';
	end generate g_pipe_ctrl;
	g_nopipe_ctrl : if (not INCL_PIPE_CTRL_C) generate
		ready_s <= '1';
	end generate g_nopipe_ctrl;

	-- Process to know the incoming image coordinates
	p_img_coord : process (clock_i)
	begin
		if (rising_edge(clock_i)) then
			if (reset_i = '1') then
				x_s <= 0;
				y_s <= 0;
				z_s <= 0;
			else
				if (handshake_i = '1') then
					if (x_s < NX_C-1) then
						x_s <= x_s + 1;
					else	
						x_s <= 0;
						if (y_s < NY_C-1) then
							y_s <= y_s + 1;
						else
							y_s <= 0;
							if (z_s < NZ_C-1) then
								z_s <= z_s + 1;
							else
								z_s <= 0;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process p_img_coord;
	
	-- Output signals
	img_coord_o <= (
		x => x_s,
		y => y_s,
		z => z_s,
		t => y_s * NX_C + x_s
	);
	ready_o <= ready_s;
	
end Behaviour;