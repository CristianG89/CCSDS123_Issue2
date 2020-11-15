library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

-- Package Declaration Section
package comp_top is
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Image coordinates control module
	------------------------------------------------------------------------------------------------------------------------------	
	component img_coord_ctrl is
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;

			handshake_i	: in  std_logic;
			w_valid_i	: in  std_logic;
			ready_o		: out std_logic;

			img_coord_o : out img_coord_t
		);
	end component img_coord_ctrl;

end package comp_top;