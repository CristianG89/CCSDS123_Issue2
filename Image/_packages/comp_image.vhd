library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;

-- Package Declaration Section
package comp_image is

	component img_coord_ctrl is
		generic (
			-- 00: BSQ order, 01: BIP order, 10: BIL order
			SMPL_ORDER_G : std_logic_vector(1 downto 0)
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;

			handshake_i	: in  std_logic;
			w_valid_i	: in  std_logic;
			ready_o		: out std_logic;

			img_coord_o : out img_coord_t
		);
	end component img_coord_ctrl;
	
end package comp_image;