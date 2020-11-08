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
		LSUM_TYPE_G	 : std_logic_vector(1 downto 0)	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
	);
	port (
		clock_i		 : in  std_logic;
		reset_i		 : in  std_logic;
		valid_i 	 : in  std_logic;
		
		img_coord_i	 : in  img_coord_t;
		data_s2_pos_i: in  s2_pos_t;
		data_lsum_o	 : out unsigned(D_C-1 downto 0)		-- "σz(t)" (Local sum)
	);
end local_sum;

architecture Behavioural of local_sum is
	signal data_lsum_s	: unsigned(D_C-1 downto 0);

begin
	-- Local sum (σz(t)) calculation
	g_lsum_type : case LSUM_TYPE_G generate
		when "00" =>	-- Wide neighbour-oriented case
			p_lsum_wi_ne : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						data_lsum_s <= (others => '0');
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0 and img_coord_i.x > 0 and img_coord_i.x < NX_C-1) then
								data_lsum_s <= to_unsigned(to_integer(data_s2_pos_i.w) + to_integer(data_s2_pos_i.nw) + to_integer(data_s2_pos_i.n) + to_integer(data_s2_pos_i.ne), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0) then
								data_lsum_s <= to_unsigned(4*to_integer(data_s2_pos_i.w), D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
								data_lsum_s <= to_unsigned(2*(to_integer(data_s2_pos_i.n) + to_integer(data_s2_pos_i.ne)), D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = NX_C-1) then
								data_lsum_s <= to_unsigned(to_integer(data_s2_pos_i.w) + to_integer(data_s2_pos_i.nw) + 2*to_integer(data_s2_pos_i.n), D_C);
							else	-- Just in case to avoid latches
								data_lsum_s <= (others => '0');
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
						data_lsum_s <= (others => '0');
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0 and img_coord_i.x > 0 and img_coord_i.x < NX_C-1) then
								data_lsum_s <= to_unsigned(to_integer(data_s2_pos_i.nw) + 2*to_integer(data_s2_pos_i.n) + to_integer(data_s2_pos_i.ne), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z > 0) then
								data_lsum_s <= to_unsigned(4*to_integer(data_s2_pos_i.wz), D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
								data_lsum_s <= to_unsigned(2*(to_integer(data_s2_pos_i.n) + to_integer(data_s2_pos_i.ne)), D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = NX_C-1) then
								data_lsum_s <= to_unsigned(2*(to_integer(data_s2_pos_i.nw) + to_integer(data_s2_pos_i.n)), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z = 0) then
								data_lsum_s <= to_unsigned(4*S_MID_C, D_C);
							else	-- Just in case to avoid latches
								data_lsum_s <= (others => '0');
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
						data_lsum_s <= (others => '0');
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0) then
								data_lsum_s <= to_unsigned(4*to_integer(data_s2_pos_i.n), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0) then
								data_lsum_s <= to_unsigned(4*to_integer(data_s2_pos_i.w), D_C);
							else	-- Just in case to avoid latches
								data_lsum_s <= (others => '0');
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
						data_lsum_s <= (others => '0');
					else
						if (valid_i = '1') then
							if (img_coord_i.y > 0) then
								data_lsum_s <= to_unsigned(4*to_integer(data_s2_pos_i.n), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z > 0) then
								data_lsum_s <= to_unsigned(4*to_integer(data_s2_pos_i.wz), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z = 0) then
								data_lsum_s <= to_unsigned(4*S_MID_C, D_C);
							else	-- Just in case to avoid latches
								data_lsum_s <= (others => '0');
							end if;
						end if;
					end if;
				end if;
			end process p_lsum_na_co;
	end generate g_lsum_type;

	-- Outputs
	data_lsum_o	<= data_lsum_s;
end Behavioural;