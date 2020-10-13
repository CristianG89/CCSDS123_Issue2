library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
	
entity double_res_pred_smpl is
	generic (
		S_MID_G			: integer
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "sz(t)" (clipped quantizer bin center)
		s_valid_s0z_i	: in  std_logic;
		s_ready_s0z_o	: out std_logic;
		s_data_s0z_i	: in  image_t;

		-- Slave interface for signal "s)z(t)" (high-resolution predicted sample)
		s_valid_s5z_i	: in  std_logic;
		s_ready_s5z_o	: out std_logic;
		s_data_s5z_i	: in  image_t;
		
		-- Master interface for signal "s~z(t)" (double-resolution predicted sample)
		m_valid_s6z_o	: out std_logic;
		m_ready_s6z_i	: in  std_logic;
		m_data_s6z_o	: out image_t
	);
end double_res_pred_smpl;

architecture behavioural of double_res_pred_smpl is
	signal s_ready_s0z_s : std_logic;
	signal s_ready_s5z_s : std_logic;
	signal m_valid_s6z_s : std_logic;
	signal m_data_s6z_s	 : image_t;

begin
	-- Double-resolution predicted sample (s~z(t)) calculation
	g_dbl_res_smpl_zaxis : for z in 0 to Nz_C-1 generate
		g_dbl_res_smpl_yaxis : for y in 0 to Ny_C-1 generate
			g_dbl_res_smpl_xaxis : for x in 0 to Nx_C-1 generate
				p_dbl_res_smpl : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_s6z_s(z)(y)(x) <= 0;
						else
							if (s_valid_s0z_i = '1' and s_ready_s0z_s = '1' and s_valid_s5z_i = '1' and s_ready_s5z_s = '1' and m_valid_s6z_s = '0') then
								if (y > 0 or x > 0) then
									m_data_s6z_s(z)(y)(x) <= round_down(real(s_data_s5z_i(z)(y)(x))/real(2**(OMEGA_C+1)))
								elsif ((y = 0 and x = 0) or P_C > 0 or z > 0) then
									m_data_s6z_s(z)(y)(x) <= 2*s_data_s0z_i(z-1)(y)(x);
								elsif ((y = 0 and x = 0) and (P_C = 0 or z = 0)) then
									m_data_s6z_s(z)(y)(x) <= 2*S_MID_G;
								end if;
							end if;
						end if;
					end if;
				end process p_dbl_res_smpl;
			end generate g_dbl_res_smpl_xaxis;
		end generate g_dbl_res_smpl_yaxis;
	end generate g_dbl_res_smpl_zaxis;

	-- Process for the hand-shaking signals
	p_dbl_res_smpl_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s0z_s <= '0';
				s_ready_s5z_s <= '0';
				m_valid_s6z_s <= '0';
			else
				if (s_valid_s0z_i = '1' and s_ready_s0z_s = '1' and s_valid_s5z_i = '1' and s_ready_s5z_s = '1') then
					s_ready_s0z_s <= '0';
					s_ready_s5z_s <= '0';
					m_valid_s6z_s <= '1';
				else
					s_ready_s0z_s <= '1';
					s_ready_s5z_s <= '1';
				end if;
				
				if (m_valid_s6z_s = '1' and m_ready_s6z_i = '1') then
					m_valid_s6z_s <= '0';
				end if;
			end if;
		end if;
	end process p_dbl_res_smpl_hand_shak;
	
	s_ready_s0z_o <= s_ready_s0z_s;
	s_ready_s5z_o <= s_ready_s5z_s;
	m_valid_s6z_o <= m_valid_s6z_s;
	m_data_s6z_o  <= m_data_s6z_s;
end behavioural;