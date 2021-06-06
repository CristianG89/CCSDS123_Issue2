library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;

use work.types_predictor.all;

-- Package Declaration Section
package comp_image is

	component img_coord_err_ctrl is
		generic (
			-- 00: BSQ order, 01: BIP order, 10: BIL order
			SMPL_ORDER_G		: std_logic_vector(1 downto 0);
			-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
			FIDEL_CTRL_TYPE_G	: std_logic_vector(1 downto 0);
			-- 1: band-dependent, 0: band-independent (for both absolute and relative error limit assignments)
			ABS_ERR_BAND_TYPE_G	: std_logic;
			REL_ERR_BAND_TYPE_G	: std_logic;
			-- 1: enabled, 0: disabled
			PER_ERR_LIM_UPD_G	: std_logic
		);
		port (
			clock_i		: in  std_logic;
			reset_i		: in  std_logic;

			handshake_i	: in  std_logic;
			w_valid_i	: in  std_logic;
			ready_o		: out std_logic;
			
			err_lim_i	: in  err_lim_t;
			err_lim_o	: out err_lim_t;
			img_coord_o : out img_coord_t
		);
	end component img_coord_err_ctrl;
	
end package comp_image;