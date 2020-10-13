library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;

entity weight_differences is
	generic (
		W_MIN_G				: integer;
		W_MAX_G				: integer;
		PREDICT_MODE_G		: std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;
		
		-- Slave interface for "s''z(t)" (sample representative)
		s_valid_cldiff_i	: in  std_logic;
		s_ready_cldiff_o	: out std_logic;
		s_data_cldiff_i		: in  image_t;
		
		-- Slave interface for "sigma z(t)" (local sum)
		s_valid_nldiff_i	: in  std_logic;
		s_ready_nldiff_o	: out std_logic;
		s_data_nldiff_i		: in  image_t;
		
		-- Slave interface for "sigma z(t)" (local sum)
		s_valid_wldiff_i	: in  std_logic;
		s_ready_wldiff_o	: out std_logic;
		s_data_wldiff_i		: in  image_t;
		
		-- Slave interface for "sigma z(t)" (local sum)
		s_valid_nwldiff_i	: in  std_logic;
		s_ready_nwldiff_o	: out std_logic;
		s_data_nwldiff_i	: in  image_t;
	
		-- Slave interface for "e(t)" (double-resolution prediction error)
		s_valid_ez_i		: in  std_logic;
		s_ready_ez_o		: out std_logic;
		s_data_ez_i			: in  image_t;
		
		-- Master interface for "Uz(t)" (local difference vector)
		m_valid_cwdiff_o	: out std_logic;
		m_ready_cwdiff_i	: in  std_logic;
		m_data_cwdiff_o		: out image_t;
		
		-- Master interface for "Uz(t)" (local difference vector)
		m_valid_nwdiff_o	: out std_logic;
		m_ready_nwdiff_i	: in  std_logic;
		m_data_nwdiff_o		: out image_t;
		
		-- Master interface for "Uz(t)" (local difference vector)
		m_valid_wwdiff_o	: out std_logic;
		m_ready_wwdiff_i	: in  std_logic;
		m_data_wwdiff_o		: out image_t;
		
		-- Master interface for "Uz(t)" (local difference vector)
		m_valid_nwwdiff_o	: out std_logic;
		m_ready_nwwdiff_i	: in  std_logic;
		m_data_nwwdiff_o	: out image_t
	);
end weight_differences;

architecture behavioural of weight_differences is
	signal s_ready_cldiff_s		: std_logic;
	signal s_ready_nldiff_s		: std_logic;
	signal s_ready_wldiff_s		: std_logic;
	signal s_ready_nwldiff_s	: std_logic;
	signal s_ready_ez_s			: std_logic;
	signal m_valid_cwdiff_s		: std_logic;
	signal m_data_cwdiff_s		: image_t;
	signal m_valid_nwdiff_s		: std_logic;
	signal m_data_nwdiff_s		: image_t;
	signal m_valid_wwdiff_s		: std_logic;
	signal m_data_wwdiff_s		: image_t;
	signal m_valid_nwwdiff_s	: std_logic;
	signal m_data_nwwdiff_s		: image_t;

begin
	-- Central weight difference calculation
	g_cwdiff_zaxis : for z in 0 to Nz_C-1 generate
		g_cwdiff_yaxis : for y in 0 to Ny_C-1 generate
			g_cwdiff_xaxis : for x in 0 to Nx_C-1 generate
				p_cwdiff : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_cwdiff_s(z)(y)(x) <= 0;
						else
							if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1' and m_valid_uz_s = '0') then
								m_data_cwdiff_s(z)(y)(x)	<= clip(m_data_cwdiff_s(z)(y)(x)+round_down(0.5*real(sgnp(s_data_ez_i(z)(y)(x))*2**(-(p(z)(y)(x)+Ç_C))*data_cldiff_s(z)(y)(x))+1.0)), W_MIN_G, W_MAX_G);
							end if;
						end if;
					end if;
				end process p_cwdiff;
			end generate g_cwdiff_xaxis;
		end generate g_cwdiff_yaxis;
	end generate g_cwdiff_zaxis;

	-- Directional weight difference are only used under full prediction mode
	g_dwdiff_fullpredict : if (PREDICT_MODE_G = '1') generate
		-- Directional local difference calculation
		g_dwdiff_zaxis : for z in 0 to Nz_C-1 generate
			g_dwdiff_yaxis : for y in 0 to Ny_C-1 generate
				g_dwdiff_xaxis : for x in 0 to Nx_C-1 generate
					-- North, West and North-West weigth difference calculation
					p_wdiff : process(clk_i) is
					begin
						if rising_edge(clk_i) then
							if (rst_i = '0') then
								m_data_nwdiff_s(z)(y)(x) <= 0;
								m_data_wwdiff_s(z)(y)(x) <= 0;
								m_data_nwwdiff_s(z)(y)(x) <= 0;
							else
								if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1' and m_valid_uz_s = '0') then
									m_data_nwdiff_s(z)(y)(x)	<= clip(m_data_nwdiff_s(z)(y)(x)+round_down(0.5*real(sgnp(s_data_ez_i(z)(y)(x))*2**(-(p(z)(y)(x)+Ç_C))*data_nldiff_s(z)(y)(x))+1.0)), W_MIN_G, W_MAX_G);
									m_data_wwdiff_s(z)(y)(x)	<= clip(m_data_nwdiff_s(z)(y)(x)+round_down(0.5*real(sgnp(s_data_ez_i(z)(y)(x))*2**(-(p(z)(y)(x)+Ç_C))*data_wldiff_s(z)(y)(x))+1.0)), W_MIN_G, W_MAX_G);
									m_data_nwwdiff_s(z)(y)(x)	<= clip(m_data_nwdiff_s(z)(y)(x)+round_down(0.5*real(sgnp(s_data_ez_i(z)(y)(x))*2**(-(p(z)(y)(x)+Ç_C))*data_nwldiff_s(z)(y)(x))+1.0)), W_MIN_G, W_MAX_G);
								end if;
							end if;
						end if;
					end process p_wdiff;
				end generate g_dwdiff_xaxis;
			end generate g_dwdiff_yaxis;
		end generate g_dwdiff_zaxis;
	end generate g_dwdiff_fullpredict;

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

	s_ready_cldiff_o	<= s_ready_cldiff_s;
	s_ready_nldiff_o	<= s_ready_nldiff_s;
	s_ready_wldiff_o	<= s_ready_wldiff_s;
	s_ready_nwldiff_o	<= s_ready_nwldiff_s;
	s_ready_ez_o		<= s_ready_ez_s;
	m_valid_cwdiff_o	<= m_valid_cwdiff_s;
	m_data_cwdiff_o		<= m_data_cwdiff_s;
	m_valid_nwdiff_o	<= m_valid_nwdiff_s;
	m_data_nwdiff_o		<= m_data_nwdiff_s;
	m_valid_wwdiff_o	<= m_valid_wwdiff_s;
	m_data_wwdiff_o		<= m_data_wwdiff_s;
	m_valid_nwwdiff_o	<= m_valid_nwwdiff_s;
	m_data_nwwdiff_o	<= m_data_nwwdiff_s;

end behavioural;