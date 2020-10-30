--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		24/10/2020
--------------------------------------------------------------------------------
-- IP name:		FIFO (First In First Out)
--
-- Description: Array to delay output values a certain time.
--				Delay time = array size, and with a new value per clock cycle.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

entity fifo is
	generic (
		DATA_SIZE_G	: integer;
		FIFO_SIZE_G	: integer
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		data_i		: in  std_logic_vector(DATA_SIZE_G-1 downto 0);
		data_o		: out std_logic_vector(DATA_SIZE_G-1 downto 0)
	);
end fifo;

architecture Behaviour of fifo is
	type fifo_t is array(FIFO_SIZE_G-1 downto 0) of std_logic_vector(DATA_SIZE_G-1 downto 0);
	signal fifo_ar_s : fifo_t => (others => (others => '0'));

	signal rd_idx_s	: integer range 0 to FIFO_SIZE_G-1;
	signal wr_idx_s : integer range 0 to FIFO_SIZE_G-1;

begin
	p_fifo : process(clock_i)
	begin
		if (rising_edge(clock_i)) then
			if (reset_i = '1') then
				-- Initial read index = lowest position / Initial write index = highest position
				rd_idx_s <= 0;
				wr_idx_s <= FIFO_SIZE_G-1;
			else
				if (valid_i = '1') then
					-- Read and write indexes of the array increased +1
					rd_idx_s <= wrap_inc(rd_idx_s, FIFO_SIZE_G-1);
					wr_idx_s <= wrap_inc(wr_idx_s, FIFO_SIZE_G-1);

					-- Incoming value added at the (current) highest position of the array
					fifo_ar_s(wr_idx_s) <= data_i;
					-- Value from the (current) lowest position of the array outputted
					data_o <= fifo_ar_s(rd_idx_s);
				end if;
			end if;
		end if;
	end process p_fifo;
end Behaviour;