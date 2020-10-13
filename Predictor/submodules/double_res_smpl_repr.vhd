library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;
	
entity double_res_smpl_repr is
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;

		-- Slave interface for signal "s'z(t)" (clipped quantizer bin center)
		s_valid_s1z_i	: in  std_logic;
		s_ready_s1z_o	: out std_logic;
		s_data_s1z_i	: in  image_t;

		-- Slave interface for signal "qz(t)" (quantizer index)
		s_valid_qz_i	: in  std_logic;
		s_ready_qz_o	: out std_logic;
		s_data_qz_i		: in  image_t;

		-- Slave interface for signal "mz(t)" (maximum error)
		s_valid_mz_i	: in  std_logic;
		s_ready_mz_o	: out std_logic;
		s_data_mz_i		: in  image_t;
		
		-- Slave interface for signal "s)z(t)" (high-resolution predicted sample)
		s_valid_s5z_i	: in  std_logic;
		s_ready_s5z_o	: out std_logic;
		s_data_s5z_i	: in  image_t;
		
		-- Master interface for signal "s~''z(t)" (double-resolution sample representative)
		m_valid_s4z_o	: out std_logic;
		m_ready_s4z_i	: in  std_logic;
		m_data_s4z_o	: out image_t
	);
end double_res_smpl_repr;

architecture behavioural of double_res_smpl_repr is
	signal s_ready_s1z_s : std_logic;
	signal s_ready_qz_s	 : std_logic;
	signal s_ready_mz_s	 : std_logic;
	signal s_ready_s5z_s : std_logic;
	signal m_valid_s4z_s : std_logic;
	signal m_data_s4z_s	 : image_t;

begin
	-- Double-resolution sample representative (s~''z(t)) calculation
	g_dbl_res_smpl_zaxis : for z in 0 to Nz_C-1 generate
		g_dbl_res_smpl_yaxis : for y in 0 to Ny_C-1 generate
			g_dbl_res_smpl_xaxis : for x in 0 to Nx_C-1 generate
				p_dbl_res_smpl : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_s4z_s(z)(y)(x) <= 0;
						else
							if (s_valid_s1z_i = '1' and s_ready_s1z_s = '1' and s_valid_qz_i = '1' and s_ready_qz_s = '1' and s_valid_mz_i = '1' and s_ready_mz_s = '1' and s_valid_s5z_i = '1' and s_ready_s5z_s = '1' and m_valid_s4z_s = '0') then
								m_data_s4z_s(z)(y)(x) <= round_down((real(4*(2**THETA_C-FI_C))*real(s_data_s1z_i(z)(y)(x)*2**OMEGA_C-sgn(s_data_qz_i(z)(y)(x))*s_data_mz_i(z)(y)(x)*PSI_C*2**(OMEGA_C-THETA_C))+real(FI_C*s_data_s5z_i(z)(y)(x))-real(FI_C*2**(OMEGA_C+1)))/real(2**(OMEGA_C+THETA_C+1)));
							end if;
						end if;
					end if;
				end process p_dbl_res_smpl;
			end generate g_dbl_res_smpl_xaxis;
		end generate g_dbl_res_smpl_yaxis;
	end generate g_dbl_res_smpl_zaxis;

	-- Process for the hand-shaking signals
	p_highres_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s1z_s <= '0';
				s_ready_qz_s  <= '0';
				s_ready_mz_s  <= '0';
				s_ready_s5z_s <= '0';
				m_valid_s4z_s <= '0';
			else
				if (s_valid_s1z_i = '1' and s_ready_s1z_s = '1' and s_valid_qz_i = '1' and s_ready_qz_s = '1' and s_valid_mz_i = '1' and s_ready_mz_s = '1' and s_valid_s5z_i = '1' and s_ready_s5z_s = '1') then
					s_ready_s1z_s <= '0';
					s_ready_qz_s  <= '0';
					s_ready_mz_s  <= '0';
					s_ready_s5z_s <= '0';
					m_valid_s4z_s <= '1';
				else
					s_ready_s1z_s <= '1';
					s_ready_qz_s  <= '1';
					s_ready_mz_s  <= '1';
					s_ready_s5z_s <= '1';
				end if;
				
				if (m_valid_s4z_s = '1' and m_ready_s4z_i = '1') then
					m_valid_s4z_s <= '0';
				end if;
			end if;
		end if;
	end process p_highres_hand_shak;

	s_ready_s1z_o <= s_ready_s1z_s;
	s_ready_qz_o  <= s_ready_qz_s;
	s_ready_mz_o  <= s_ready_mz_s;
	m_valid_s4z_o <= m_valid_s4z_s;
	m_data_s4z_o  <= m_data_s4z_s;

end behavioural;