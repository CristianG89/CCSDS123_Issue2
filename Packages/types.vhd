library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;

-- Package Declaration Section
package types is
	
	-- Integer array type (for 1D, 2D and 3D)
	type array_int_t is array(natural range <>) of integer;
	type plane_int_t is array(natural range <>) of array_int_t;
	type matrix_int_t is array(natural range <>) of plane_int_t;

	-- Real array type (for 1D, 2D and 3D)
	type array_real_t is array(natural range <>) of real;
	type plane_real_t is array(natural range <>) of array_real_t;
	type matrix_real_t is array(natural range <>) of plane_real_t;
	
	-- Record with all signals within the AXI-Stream interface
	type axi_stream_t is record
		aclk	: std_logic;
		arst	: std_logic;
		
		tvalid	: std_logic;
		tready	: std_logic;
		tlast	: std_logic;
		tdata	: std_logic_vector;
		tkeep	: std_logic_vector;
		tid		: std_logic_vector;
		tdest	: std_logic_vector;
		tuser	: std_logic_vector;
	end record axi_stream_t;
	
	-- Record for the image coordinates
	type img_coord_t is record
		x : integer range 0 to NX_C-1;
		y : integer range 0 to NY_C-1;
		z : integer range 0 to NZ_C-1;
		t : integer range 0 to NX_C*NY_C-1;
	end record img_coord_t;
	
	type s2_pos_t is record
		cur : std_logic_vector(D_C-1 downto 0);
		w	: std_logic_vector(D_C-1 downto 0);
		wz	: std_logic_vector(D_C-1 downto 0);
		n	: std_logic_vector(D_C-1 downto 0);
		nw	: std_logic_vector(D_C-1 downto 0);
		ne	: std_logic_vector(D_C-1 downto 0);
	end record s2_pos_t;

	type ldiff_pos_t is record
		c	: std_logic_vector(D_C-1 downto 0);
		n	: std_logic_vector(D_C-1 downto 0);
		w	: std_logic_vector(D_C-1 downto 0);
		nw	: std_logic_vector(D_C-1 downto 0);
	end record ldiff_pos_t;

end package types;