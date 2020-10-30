--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		24/10/2020
--------------------------------------------------------------------------------
-- IP name:		local_sum
--
-- Description: Computes the local sum
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.param_image.all;

entity local_sum is
	generic (
		S_MID_G		: integer;
		LSUM_TYPE_G	: std_logic_vector(1 downto 0)	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		
		s2_pos_i	: in  s2_pos_t;
		s2_pos_o	: out s2_pos_t;
		lsum_o		: out std_logic_vector(D_C-1 downto 0);
		
		valid_i 	: in  std_logic;
		img_coord_i	: in  img_coord_t;

		valid_o		: out std_logic;
		img_coord_o	: out img_coord_t
	);
end local_sum;

architecture Behavioural of local_sum is
	signal s2_pos_s		: s2_pos_t;
	signal lsum_s		: std_logic_vector(D_C-1 downto 0);
	signal valid_s		: std_logic;
	signal img_coord_s	: img_coord_t;

begin
	-- Local sum (sigma z(t)) calculation
	g_lsum_type : case LSUM_TYPE_G generate
		when "00" =>	-- Wide neighbour-oriented case
			p_lsum_wi_ne : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						lsum_s <= 0;
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0 and img_coord_i.x > 0 and img_coord_i.x < NX_C-1) then
								lsum_s <= s2_pos_i.w + s2_pos_i.nw + s2_pos_i.n + s2_pos_i.ne;
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0) then
								lsum_s <= 4*s2_pos_i.w;
							elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
								lsum_s <= 2*(s2_pos_i.n + s2_pos_i.ne);
							elsif (img_coord_i.y > 0 and img_coord_i.x = NX_C-1) then
								lsum_s <= s2_pos_i.w + s2_pos_i.nw + 2*s2_pos_i.n;
							else	-- Just in case to avoid latches
								lsum_s <= 0;
							end if;
						end if;
					end if;
				end if;
			end process p_lsum_wi_ne;

		when "01" =>	-- Narrow neighbour-oriented case
			p_lsum_na_ne : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						lsum_s <= 0;
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0 and img_coord_i.x > 0 and img_coord_i.x < NX_C-1) then
								lsum_s <= s2_pos_i.nw + 2*s2_pos_i.n + s2_pos_i.ne;
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z > 0) then
								lsum_s <= 4*s2_pos_i.wz;
							elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
								lsum_s <= 2*(s2_pos_i.n + s2_pos_i.ne);
							elsif (img_coord_i.y > 0 and img_coord_i.x = NX_C-1) then
								lsum_s <= 2*(s2_pos_i.nw + s2_pos_i.n);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z = 0) then
								lsum_s <= 4*S_MID_G;
							else	-- Just in case to avoid latches
								lsum_s <= 0;
							end if;
						end if;
					end if;
				end if;
			end process p_lsum_na_ne;

		when "10" =>	-- Wide column-oriented case
			p_lsum_wi_co : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						lsum_s <= 0;
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0) then
								lsum_s <= 4*s2_pos_i.n;
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0) then
								lsum_s <= 4*s2_pos_i.w;
							else	-- Just in case to avoid latches
								lsum_s <= 0;
							end if;
						end if;
					end if;
				end if;
			end process p_lsum_wi_co;
			
		when others =>	-- Narrow column-oriented case (when "11")
			p_lsum_na_co : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						lsum_s <= 0;
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0) then
								lsum_s <= 4*s2_pos_i.n;
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z > 0) then
								lsum_s <= 4*s2_pos_i.wz;
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z = 0) then
								lsum_s <= 4*S_MID_G;
							else	-- Just in case to avoid latches
								lsum_s <= 0;
							end if;
						end if;
					end if;
				end if;
			end process p_lsum_na_co;
	end generate g_lsum_type;

	-- Input values delayed one clock cycle (through "process" to synchronize them with the new output values
	p_lsum_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				s2_pos_s	<= (others => (others => '0'));
				valid_s		<= '0';
				img_coord_s	<= (others => (others => 0));
			else
				s2_pos_s	<= s2_pos_i;
				valid_s		<= valid_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_lsum_delay;

	-- Outputs
	s2_pos_o	<= s2_pos_s;
	lsum_o		<= lsum_s;
	valid_o		<= valid_s;
	img_coord_o	<= img_coord_s;
end Behavioural;