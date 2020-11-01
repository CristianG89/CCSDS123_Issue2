--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		07/11/2020
--------------------------------------------------------------------------------
-- IP name:		top_predictor
--
-- Description: Top entity for the "predictor" module
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
use work.comp_predictor.all;
	
entity top_predictor is
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		valid_i			: in  std_logic;
		valid_o			: out std_logic;
		
		data_s0_i		: in  std_logic_vector(D_C-1 downto 0);	-- "sz(t)" (original sample)
		data_mp_quan_o	: out std_logic_vector(D_C-1 downto 0)	-- "δz(t)" (mapped quantizer index)
	);
end top_predictor;

architecture behavioural of top_predictor is
	-- When samples are unsigned integers:
	constant S_MIN_C : integer := 0;
	constant S_MAX_C : integer := 2**D_C-1;
	constant S_MID_C : integer := 2**(D_C-1);
	-- When samples are signed integers:
	-- constant S_MIN_C : integer := -2**(D_C-1);
	-- constant S_MAX_C : integer := 2**(D_C-1)-1;
	-- constant S_MID_C : integer := 0;
	
begin
-- pz_s <= min(z_coord_i, P_C);

-- For the time being, CZ_G is fixed for full pred mode (but depending on this mode, initial indexes are skipped
-- cz_s <= pz_s + 3;

end behavioural;