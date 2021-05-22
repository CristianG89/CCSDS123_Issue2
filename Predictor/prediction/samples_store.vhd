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
-- ... | ... | ... | ... | ...			 +--> +x
-- ----+-----+-----+-----+-----			/|
-- ... | NW  |  N  | NE  | ...		   / |
-- ----+-----+-----+-----+-----		  v	 v
-- ... |  W  | CUR | ... | ...		 +z	 +y
-- ----+-----+-----+-----+-----
-- ... | ... | ... | ... | ...			WZ = W, but in the previous spectral band
--
-- Depending on the input order (BSQ/BIP/BIL), the delay (reg. size) to get the different neighbour samples
--
-- Order | NW			 | N		 | NE			 | W	| Z-1		| Z-2		  | z-3
-- ------+---------------+-----------+---------------+------+-----------+-------------+-------------
-- BSQ	 | NX_C+1		 | NX_C		 | NX_C-1		 | 1	| NX_C*NY_C | 2*NX_C*NY_C | 3*NX_C*NY_C
-- BIP	 | (NX_C+1)*NZ_C | NX_C*NZ_C | (NX_C-1)*NZ_C | NZ_C	| 1			| 2			  | 3
-- BIL	 | NX_C*NZ_C+1	 | NX_C*NZ_C | NX_C*NZ_C-1	 | 1	| NX_C		| 2*NX_C	  | 3*NX_C
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.types_predictor.all;
use work.comp_predictor.all;

entity sample_store is
	generic (
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G : std_logic_vector(1 downto 0)
	);
	port (
		clock_i		 : in  std_logic;
		reset_i		 : in  std_logic;

		enable_i	 : in  std_logic;
		enable_o	 : out std_logic;
		img_coord_i	 : in  img_coord_t;
		img_coord_o	 : out img_coord_t;
		
		data_s2_i	 : in  signed(D_C-1 downto 0);
		data_s2_pos_o: out s2_pos_t
	);
end sample_store;

architecture Behaviour of sample_store is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal s2_cur_s		: signed(D_C-1 downto 0) := (others => '0');
	signal s2_w_s		: signed(D_C-1 downto 0) := (others => '0');
	signal s2_wz_s		: signed(D_C-1 downto 0) := (others => '0');
	signal s2_n_s		: signed(D_C-1 downto 0) := (others => '0');
	signal s2_nw_s		: signed(D_C-1 downto 0) := (others => '0');
	signal s2_ne_s		: signed(D_C-1 downto 0) := (others => '0');
	
	-- Delay for neighbour samples depending on the input order
	constant POS_W_C	: integer := locate_position(SMPL_ORDER_G, 1, NZ_C, 1);
	constant POS_WZ_C	: integer := locate_position(SMPL_ORDER_G, 1*NX_C*NY_C, NZ_C*1, 1*NX_C);
	constant POS_N_C	: integer := locate_position(SMPL_ORDER_G, NX_C, NX_C*NZ_C, NX_C*NZ_C);
	constant POS_NW_C	: integer := locate_position(SMPL_ORDER_G, NX_C+1, (NX_C+1)*NZ_C, NX_C*NZ_C+1);
	constant POS_NE_C	: integer := locate_position(SMPL_ORDER_G, NX_C-1, (NX_C-1)*NZ_C, NX_C*NZ_C-1);

begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_sample_store_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_s	<= '0';
				img_coord_s <= reset_img_coord;
			else
				enable_s	<= enable_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_sample_store_delay;
	
	-- Position "W" calculation
	i_shift_reg_w : shift_register
	generic map(
		DATA_SIZE_G	=> D_C,
		REG_SIZE_G	=> POS_W_C
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
		REG_SIZE_G	=> POS_WZ_C
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
		REG_SIZE_G	=> POS_N_C
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
		REG_SIZE_G	=> POS_NW_C
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
		REG_SIZE_G	=> POS_NE_C
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
				s2_cur_s <= (others => '0');
			else
				s2_cur_s <= data_s2_i;
			end if;
		end if;
	end process p_store_delay;
	
	-- Outputs
	enable_o	  <= enable_s;
	img_coord_o	  <= img_coord_s;
	data_s2_pos_o <= (
		cur => signed(s2_cur_s),
		w	=> signed(s2_w_s),
		wz	=> signed(s2_wz_s),
		n	=> signed(s2_n_s),
		nw	=> signed(s2_nw_s),
		ne	=> signed(s2_ne_s)
	);
end Behaviour;