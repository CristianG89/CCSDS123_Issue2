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
use work.comp_gen.all;

entity sample_store is
	port (
		clock_i	 : in  std_logic;
		reset_i	 : in  std_logic;

		valid_i	 : in  std_logic;
		data_i	 : in  std_logic_vector(D_C-1 downto 0);

		s2_pos_o : out s2_pos_t
	);
end sample_store;

architecture Behaviour of sample_store is
	signal data_s	: std_logic_vector(D_C-1 downto 0);
	signal s2_w_s	: std_logic_vector(D_C-1 downto 0);
	signal s2_wz_s	: std_logic_vector(D_C-1 downto 0);
	signal s2_n_s	: std_logic_vector(D_C-1 downto 0);
	signal s2_nw_s	: std_logic_vector(D_C-1 downto 0);
	signal s2_ne_s	: std_logic_vector(D_C-1 downto 0);

begin
	-- Position "W" calculation
	i_fifo_w : entity work.fifo
	generic map(
		DATA_SIZE_G	=> D_C,
		FIFO_SIZE_G	=> (NX_C*NY_C-1)
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_i,
		valid_i		=> valid_i,
		data_o		=> s2_w_s
	);

	-- Position "W" calculation (delayed one spectral band z)
	i_fifo_wz : entity work.fifo
	generic map(
		DATA_SIZE_G	=> D_C,
		FIFO_SIZE_G	=> (NX_C*NY_C*(NZ_C-1)-1)
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_i,
		valid_i		=> valid_i,
		data_o		=> s2_wz_s
	);

	-- Position "N" calculation
	i_fifo_n : entity work.fifo
	generic map(
		DATA_SIZE_G	=> D_C,
		FIFO_SIZE_G	=> (NX_C*(NY_C-1))
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_i,
		valid_i		=> valid_i,
		data_o		=> s2_n_s
	);

	-- Position "NW" calculation
	i_fifo_nw : entity work.fifo
	generic map(
		DATA_SIZE_G	=> D_C,
		FIFO_SIZE_G	=> ((NX_C-1)*(NY_C-1))
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_i,
		valid_i		=> valid_i,
		data_o		=> s2_nw_s
	);

	-- Position "NE" calculation
	i_fifo_ne : entity work.fifo
	generic map(
		DATA_SIZE_G	=> D_C,
		FIFO_SIZE_G	=> ((NX_C+1)*(NY_C-1))
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_i,
		valid_i		=> valid_i,
		data_o		=> s2_ne_s
	);

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_store_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s <= (others => '0');
			else
				data_s <= data_i;
			end if;
		end if;
	end process p_store_delay;
	
	-- Outputs
	s2_pos_o => (
		cur <= data_s,
		w	<= s2_w_s,
		wz	<= s2_wz_s,
		n	<= s2_n_s,
		nw	<= s2_nw_s,
		ne	<= s2_ne_s
	);
end Behaviour;