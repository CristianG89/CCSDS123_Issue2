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
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.types_predictor.all;

entity local_sum is
	generic (
		SMPL_LIMIT_G : smpl_lim_t;
		LSUM_TYPE_G	 : std_logic_vector(1 downto 0)	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
	);
	port (
		clock_i		 : in  std_logic;
		reset_i		 : in  std_logic;
		
		enable_i	 : in  std_logic;
		enable_o	 : out std_logic;
		img_coord_i	 : in  img_coord_t;
		img_coord_o	 : out img_coord_t;
		
		data_s2_pos_i: in  s2_pos_t;
		data_lsum_o	 : out signed(D_C-1 downto 0)	-- "σz(t)" (Local sum)
	);
end local_sum;

architecture Behavioural of local_sum is
	signal enable_s		: std_logic := '0';
	signal img_coord_s	: img_coord_t := reset_img_coord;
	
	signal data_lsum_s : signed(D_C-1 downto 0) := (others => '0');

begin
	-- Input values delayed to synchronize them with the next modules in chain
	p_lsum_delay : process(clock_i) is
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
	end process p_lsum_delay;
	
	-- Local sum (σz(t)) calculation
	g_lsum_type : case LSUM_TYPE_G generate
		when "00" =>	-- Wide neighbour-oriented case
			p_lsum_wi_ne : process(clock_i) is
			begin
				if rising_edge(clock_i) then
					if (reset_i = '1') then
						data_lsum_s <= (others => '0');
					else
						if (enable_i = '1') then
							if (img_coord_i.y > 0 and img_coord_i.x > 0 and img_coord_i.x < NX_C-1) then
								data_lsum_s <= resize(data_s2_pos_i.w + data_s2_pos_i.nw + data_s2_pos_i.n + data_s2_pos_i.ne, D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0) then
								data_lsum_s <= resize(n4_C*data_s2_pos_i.w, D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
								data_lsum_s <= resize(n2_C*(data_s2_pos_i.n + data_s2_pos_i.ne), D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = NX_C-1) then
								data_lsum_s <= resize(data_s2_pos_i.w + data_s2_pos_i.nw + n2_C*data_s2_pos_i.n, D_C);
							else		-- Case X=0 and Y=0 here defined, but anyway not used later on...
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
						if (enable_i = '1') then
							if (img_coord_i.y > 0 and img_coord_i.x > 0 and img_coord_i.x < NX_C-1) then
								data_lsum_s <= resize(data_s2_pos_i.nw + n2_C*data_s2_pos_i.n + data_s2_pos_i.ne, D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z > 0) then
								data_lsum_s <= resize(n4_C*data_s2_pos_i.wz, D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
								data_lsum_s <= resize(n2_C*(data_s2_pos_i.n + data_s2_pos_i.ne), D_C);
							elsif (img_coord_i.y > 0 and img_coord_i.x = NX_C-1) then
								data_lsum_s <= resize(n2_C*(data_s2_pos_i.nw + data_s2_pos_i.n), D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z = 0) then
								data_lsum_s <= resize(n4_C*to_signed(SMPL_LIMIT_G.mid, D_C), D_C);
							else		-- Case X=0 and Y=0 here defined, but anyway not used later on...
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
						if (enable_i = '1') then
							if (img_coord_i.y > 0) then
								data_lsum_s <= resize(n4_C*data_s2_pos_i.n, D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0) then
								data_lsum_s <= resize(n4_C*data_s2_pos_i.w, D_C);
							else		-- Case X=0 and Y=0 here defined, but anyway not used later on...
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
						if (enable_i = '1') then
							if (img_coord_i.y > 0) then
								data_lsum_s <= resize(n4_C*data_s2_pos_i.n, D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z > 0) then
								data_lsum_s <= resize(n4_C*data_s2_pos_i.wz, D_C);
							elsif (img_coord_i.y = 0 and img_coord_i.x > 0 and img_coord_i.z = 0) then
								data_lsum_s <= resize(n4_C*to_signed(SMPL_LIMIT_G.mid, D_C), D_C);
							else		-- Case X=0 and Y=0 here defined, but anyway not used later on...
								data_lsum_s <= (others => '0');
							end if;
						end if;
					end if;
				end if;
			end process p_lsum_na_co;
	end generate g_lsum_type;

	-- Outputs
	enable_o	<= enable_s;
	img_coord_o	<= img_coord_s;
	data_lsum_o	<= data_lsum_s;
end Behavioural;