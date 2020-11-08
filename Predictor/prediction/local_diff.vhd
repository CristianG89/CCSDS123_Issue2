--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		24/10/2020
--------------------------------------------------------------------------------
-- IP name:		local_diff
--
-- Description: Computes the local differences
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.param_image.all;

entity local_diff is
	generic (
		PREDICT_MODE_G : std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clock_i		  : in  std_logic;
		reset_i		  : in  std_logic;
		valid_i		  : in  std_logic;
		
		img_coord_i	  : in  img_coord_t;
		data_lsum_i	  : in  unsigned(D_C-1 downto 0);
		data_s2_pos_i : in  s2_pos_t;
		ldiff_pos_o	  : out ldiff_pos_t
	);
end local_diff;

architecture Behavioural of local_diff is
	signal cldiff_s	 : unsigned(D_C-1 downto 0);
	signal nldiff_s	 : unsigned(D_C-1 downto 0) := (others => '0');
	signal wldiff_s	 : unsigned(D_C-1 downto 0) := (others => '0');
	signal nwldiff_s : unsigned(D_C-1 downto 0) := (others => '0');

begin
	-- Central local difference calculation
	p_cldiff : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				cldiff_s <= (others => '0');
			else
				if (valid_i = '1') then
					cldiff_s <= to_unsigned(4*to_integer(data_s2_pos_i.cur) - to_integer(data_lsum_i), D_C);
				end if;
			end if;
		end if;
	end process p_cldiff;

	-- Directional local difference are only used under full prediction mode
	g_dldiff_fullpredict : if (PREDICT_MODE_G = '1') generate
		-- Directional local difference calculation
		p_dldiff : process(clock_i) is
		begin
			if rising_edge(clock_i) then
				if (reset_i = '1') then
					nldiff_s <= (others => '0');
				else
					if (valid_i = '1') then
						-- North local difference calculation
						if (img_coord_i.y > 0) then
							nldiff_s <= to_unsigned(4*to_integer(data_s2_pos_i.n) - to_integer(data_lsum_i), D_C);
						else
							nldiff_s <= (others => '0');
						end if;
						
						-- West local difference calculation
						if (img_coord_i.y > 0 and img_coord_i.x > 0) then
							wldiff_s <= to_unsigned(4*to_integer(data_s2_pos_i.w) - to_integer(data_lsum_i), D_C);
						elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
							wldiff_s <= to_unsigned(4*to_integer(data_s2_pos_i.n) - to_integer(data_lsum_i), D_C);
						else
							wldiff_s <= (others => '0');
						end if;
						
						-- North-West local difference calculation
						if (img_coord_i.y > 0 and img_coord_i.x > 0) then
							nwldiff_s <= to_unsigned(4*to_integer(data_s2_pos_i.nw) - to_integer(data_lsum_i), D_C);
						elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
							nwldiff_s <= to_unsigned(4*to_integer(data_s2_pos_i.n) - to_integer(data_lsum_i), D_C);
						else
							nwldiff_s <= (others => '0');
						end if;
					end if;
				end if;
			end if;
		end process p_dldiff;
	end generate g_dldiff_fullpredict;

	-- Outputs
	ldiff_pos_o <= (
		c	=> signed(cldiff_s),
		n	=> signed(nldiff_s),
		w	=> signed(wldiff_s),
		nw	=> signed(nwldiff_s)
	);
end Behavioural;