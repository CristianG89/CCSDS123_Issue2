--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		24/10/2020
--------------------------------------------------------------------------------
-- IP name:		shift_register
--
-- Description: Array to delay output values a certain time.
--				Delay time = array size, and with a new value per clock cycle.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;

entity shift_register is
	generic (
		DATA_SIZE_G	: integer;
		REG_SIZE_G	: integer
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		data_i		: in  signed(DATA_SIZE_G-1 downto 0);
		data_o		: out signed(DATA_SIZE_G-1 downto 0)
	);
end shift_register;

architecture Behaviour of shift_register is
	signal shift_reg_ar_s : array_signed_t(REG_SIZE_G-1 downto 0)(DATA_SIZE_G-1 downto 0) := (others => (others => '0'));

	signal rd_idx_s	: integer range 0 to REG_SIZE_G-1;
	signal wr_idx_s : integer range 0 to REG_SIZE_G-1;

begin
	p_shift_reg : process(clock_i)
	begin
		if (rising_edge(clock_i)) then
			if (reset_i = '1') then
				-- Initial read index = lowest position / Initial write index = highest position
				rd_idx_s		<= 0;
				wr_idx_s		<= REG_SIZE_G-1;
				shift_reg_ar_s	<= (others => (others => '0'));
			else
				-- Read and write indexes of the array increased +1
				rd_idx_s <= pointer_inc(rd_idx_s, REG_SIZE_G-1);
				wr_idx_s <= pointer_inc(wr_idx_s, REG_SIZE_G-1);

				-- Incoming value added at the (current) highest position of the array
				shift_reg_ar_s(wr_idx_s) <= data_i;
				-- Value from the (current) lowest position of the array outputted
				data_o <= shift_reg_ar_s(rd_idx_s);
			end if;
		end if;
	end process p_shift_reg;
end Behaviour;