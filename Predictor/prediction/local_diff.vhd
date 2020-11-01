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
		PREDICT_MODE_G	: std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		s2_pos_i	: in  s2_pos_t;
		data_lsum_i	: in  std_logic_vector(D_C-1 downto 0);
		
		ldiff_pos_o	: out ldiff_pos_t;

		img_coord_i	: in  img_coord_t;
		valid_i 	: in  std_logic;
		valid_o		: out std_logic
	);
end local_diff;

architecture Behavioural of local_diff is
	signal cldiff_s	 : std_logic_vector(D_C-1 downto 0);
	signal nldiff_s	 : std_logic_vector(D_C-1 downto 0) := (others => '0');
	signal wldiff_s	 : std_logic_vector(D_C-1 downto 0) := (others => '0');
	signal nwldiff_s : std_logic_vector(D_C-1 downto 0) := (others => '0');
	signal valid_s	 : std_logic;

begin
	-- Central local difference calculation
	p_cldiff : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				cldiff_s <= (others => '0');
			else
				if (valid_i = '1') then
					cldiff_s <= 4*s2_pos_i.cur - data_lsum_i;
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
							nldiff_s <= 4*s2_pos_i.n - data_lsum_i;
						else
							nldiff_s <= (others => '0');
						end if;
						
						-- West local difference calculation
						if (img_coord_i.y > 0 and img_coord_i.x > 0) then
							wldiff_s <= 4*s2_pos_i.w - data_lsum_i;
						elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
							wldiff_s <= 4*s2_pos_i.n - data_lsum_i;
						else
							wldiff_s <= (others => '0');
						end if;
						
						-- North-West local difference calculation
						if (img_coord_i.y > 0 and img_coord_i.x > 0) then
							nwldiff_s <= 4*s2_pos_i.nw - data_lsum_i;
						elsif (img_coord_i.y > 0 and img_coord_i.x = 0) then
							nwldiff_s <= 4*s2_pos_i.n - data_lsum_i;
						else
							nwldiff_s <= (others => '0');
						end if;
					end if;
				end if;
			end if;
		end process p_dldiff;
	end generate g_dldiff_fullpredict;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_ldiff_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s <= '0';
			else
				valid_s <= valid_i;
			end if;
		end if;
	end process p_ldiff_delay;

	-- Outputs
	ldiff_pos_o => (
		c	<= cldiff_s,
		n	<= nldiff_s,
		w	<= wldiff_s,
		nw	<= nwldiff_s
	);
	valid_o <= valid_s;
end Behavioural;