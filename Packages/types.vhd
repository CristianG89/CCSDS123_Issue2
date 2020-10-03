library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

end package types;