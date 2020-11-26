--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		24/10/2020
--------------------------------------------------------------------------------
-- IP name:		sample_store
--
-- Description: Given the current sample, it uses FIFOs to provide
--				some specifc older samples.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ... | ... | ... | ... | ...
-- ----+-----+-----+-----+-----
-- ... | NW  |  N  | NE  | ...
-- ----+-----+-----+-----+-----
-- ... |  W  | CUR | ... | ...		WZ = W, but in the previous spectral band
-- ----+-----+-----+-----+-----
-- ... | ... | ... | ... | ...
--
-- in ---+--------------------------------> CUR
--       |    +----------------+
--       +--->| NX*NY-1        |----------> W
--       |    +----------------+
--       +--->| NX*NY*(NZ-1)-1 |----------> WZ
--       |    +----------------+
--       +--->| NX*(NY-1)      |----------> N
--       |    +----------------+
--       +--->| (NX-1)*(NY-1)  |----------> NW
--       |    +----------------+
--       +--->| (NX+1)*(NY-1)  |----------> NE
--            +----------------+
--
-- (Boxes indicate the sample delays to reach the desired (old) sample
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.param_image.all;
use work.comp_predictor.all;

entity sample_store is
	port (
		clock_i	  : in  std_logic;
		reset_i	  : in  std_logic;

		enable_i  : in  std_logic;
		data_s2_i : in  signed(D_C-1 downto 0);

		data_s2_pos_o : out s2_pos_t
	);
end sample_store;

architecture Behaviour of sample_store is
	signal s2_data_s : signed(D_C-1 downto 0) := (others => '0');
	signal s2_w_s	 : signed(D_C-1 downto 0) := (others => '0');
	signal s2_wz_s	 : signed(D_C-1 downto 0) := (others => '0');
	signal s2_n_s	 : signed(D_C-1 downto 0) := (others => '0');
	signal s2_nw_s	 : signed(D_C-1 downto 0) := (others => '0');
	signal s2_ne_s	 : signed(D_C-1 downto 0) := (others => '0');

begin
	-- Position "W" calculation
	i_shift_reg_w : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> (NX_C*NY_C-1)
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s2_i,
		data_o		=> s2_w_s
	);

	-- Position "W" calculation (delayed one spectral band z)
	i_shift_reg_wz : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> (NX_C*NY_C*(NZ_C-1)-1)
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s2_i,
		data_o		=> s2_wz_s
	);

	-- Position "N" calculation
	i_shift_reg_n : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> (NX_C*(NY_C-1))
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s2_i,
		data_o		=> s2_n_s
	);

	-- Position "NW" calculation
	i_shift_reg_nw : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> ((NX_C-1)*(NY_C-1))
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s2_i,
		data_o		=> s2_nw_s
	);

	-- Position "NE" calculation
	i_shift_reg_ne : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> ((NX_C+1)*(NY_C-1))
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s2_i,
		data_o		=> s2_ne_s
	);

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_store_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				s2_data_s <= (others => '0');
			else
				s2_data_s <= data_s2_i;
			end if;
		end if;
	end process p_store_delay;
	
	-- Outputs
	data_s2_pos_o <= (
		cur => signed(s2_data_s),
		w	=> signed(s2_w_s),
		wz	=> signed(s2_wz_s),
		n	=> signed(s2_n_s),
		nw	=> signed(s2_nw_s),
		ne	=> signed(s2_ne_s)
	);
end Behaviour;