library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;

entity local_differences is
	generic (
		PREDICT_MODE_G	: std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for "s''z(t)" (sample representative)
		s_valid_s2z_i	: in  std_logic;
		s_ready_s2z_o	: out std_logic;
		s_data_s2z_i	: in  image_t;
		
		-- Slave interface for "sigma z(t)" (local sum)
		s_valid_lsz_i	: in  std_logic;
		s_ready_lsz_o	: out std_logic;
		s_data_lsz_i	: in  image_t;
		
		-- Master interface for "Uz(t)" (local difference vector)
		m_valid_uz_o	: out std_logic;
		m_ready_uz_i	: in  std_logic;
		m_data_uz_o		: out image_t
	);
end local_differences;

architecture behavioural of local_differences is
	signal s_ready_s2z_s	: std_logic;
	signal s_ready_lsz_s	: std_logic;
	signal m_valid_uz_s		: std_logic;
	signal m_data_uz_s		: image_t;

	signal data_cldiff_s	: image_t;
	signal data_nldiff_s	: image_t;
	signal data_wldiff_s	: image_t;
	signal data_nwldiff_s	: image_t;

begin
	-- Central local difference calculation
	g_cldiff_zaxis : for z in 0 to Nz_C-1 generate
		g_cldiff_yaxis : for y in 0 to Ny_C-1 generate
			g_cldiff_xaxis : for x in 0 to Nx_C-1 generate
				p_cldiff : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							data_cldiff_s(z)(y)(x) <= 0;
						else
							if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1' and m_valid_uz_s = '0') then
								data_cldiff_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y)(x) - s_data_lsz_i(z)(y)(x);
							end if;
						end if;
					end if;
				end process p_cldiff;
			end generate g_cldiff_xaxis;
		end generate g_cldiff_yaxis;
	end generate g_cldiff_zaxis;

	-- Directional local difference are only used under full prediction mode
	g_dldiff_fullpredict : if (PREDICT_MODE_G = '1') generate
		-- Directional local difference calculation
		g_dldiff_zaxis : for z in 0 to Nz_C-1 generate
			g_dldiff_yaxis : for y in 0 to Ny_C-1 generate
				g_dldiff_xaxis : for x in 0 to Nx_C-1 generate
					-- North local difference calculation
					p_nldiff : process(clk_i) is
					begin
						if rising_edge(clk_i) then
							if (rst_i = '0') then
								data_nldiff_s(z)(y)(x) <= 0;
							else
								if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1' and m_valid_uz_s = '0') then
									if (y > 0) then
										data_nldiff_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y-1)(x) - s_data_lsz_i(z)(y)(x);
									else
										data_nldiff_s(z)(y)(x) <= 0;
									end if;
								end if;
							end if;
						end if;
					end process p_nldiff;
					
					-- West local difference calculation
					p_wldiff : process(clk_i) is
					begin
						if rising_edge(clk_i) then
							if (rst_i = '0') then
								data_wldiff_s(z)(y)(x) <= 0;
							else
								if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1') then
									if (y > 0 and x > 0) then
										data_wldiff_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y)(x-1) - s_data_lsz_i(z)(y)(x);
									elsif (y > 0 and x = 0) then
										data_wldiff_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y-1)(x) - s_data_lsz_i(z)(y)(x);
									else
										data_wldiff_s(z)(y)(x) <= 0;
									end if;
								end if;
							end if;
						end if;
					end process p_wldiff;
					
					-- North-West local difference calculation
					p_nwldiff : process(clk_i) is
					begin
						if rising_edge(clk_i) then
							if (rst_i = '0') then
								data_nwldiff_s(z)(y)(x) <= 0;
							else
								if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1') then
									if (y > 0 and x > 0) then
										data_nwldiff_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y-1)(x-1) - s_data_lsz_i(z)(y)(x);
									elsif (y > 0 and x = 0) then
										data_nwldiff_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y-1)(x) - s_data_lsz_i(z)(y)(x);
									else
										data_nwldiff_s(z)(y)(x) <= 0;
									end if;
								end if;
							end if;
						end if;
					end process p_nwldiff;
				end generate g_dldiff_xaxis;
			end generate g_dldiff_yaxis;
		end generate g_dldiff_zaxis;
	end generate g_dldiff_fullpredict;

	-- Process for the hand-shaking signals
	p_ldiff_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s2z_s <= '0';
				s_ready_lsz_s <= '0';
				m_valid_uz_s <= '0';
			else
				if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1') then
					s_ready_s2z_s <= '0';
					s_ready_lsz_s <= '0';
					m_valid_uz_s <= '1';
				else
					s_ready_s2z_s <= '1';
					s_ready_lsz_s <= '1';
				end if;
				
				if (m_valid_uz_s = '1' and m_ready_uz_i = '1') then
					m_valid_uz_s <= '0';
				end if;
			end if;
		end if;
	end process p_ldiff_hand_shak;

	-- Local difference vector (Uz(t)) calculation
	g_ldiffv_zaxis : for z in 0 to Nz_C-1 generate
		constant Pz_C : integer := min(z, P_C);
	begin
		g_ldiffv_yaxis : for y in 0 to Ny_C-1 generate
			g_ldiffv_xaxis : for x in 0 to Nx_C-1 generate
				p_ldiffv : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_uz_s(z)(y)(x) <= 0;
						else
							if (m_valid_uz_s = '1' and m_ready_uz_i = '1') then
								m_data_uz_s(z)(y)(x) <= data_cldiff_s(z-Pz_C)(y)(x);
							end if;
						end if;
					end if;
				end process p_ldiffv;
			end generate g_ldiffv_xaxis;
		end generate g_ldiffv_yaxis;
	end generate g_ldiffv_zaxis;

	s_ready_s2z_o <= s_ready_s2z_s;
	s_ready_lsz_o <= s_ready_lsz_s;
	m_valid_uz_o  <= m_valid_uz_s;
	m_data_uz_o	  <= m_data_uz_s;

end behavioural;