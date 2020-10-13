library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;
	
entity high_res_pred_smpl is
	generic (
		S_MAX_G			: integer;
		S_MIN_G			: integer;
		S_MID_G			: integer
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;

		-- Slave interface for signal "d^z(t)" (predicted central local difference)
		s_valid_pldz_i	: in  std_logic;
		s_ready_pldz_o	: out std_logic;
		s_data_pldz_i	: in  image_t;

		-- Slave interface for signal "sigma z(t)" (local sum)
		s_valid_lsz_i	: in  std_logic;
		s_ready_lsz_o	: out std_logic;
		s_data_lsz_i	: in  image_t;
		
		-- Master interface for signal "s)z(t)" (high-resolution predicted sample)
		m_valid_s5z_o	: out std_logic;
		m_ready_s5z_i	: in  std_logic;
		m_data_s5z_o	: out image_t
	);
end high_res_pred_smpl;

architecture behavioural of high_res_pred_smpl is
	signal s_ready_pldz_s : std_logic;
	signal s_ready_lsz_s  : std_logic;
	signal m_valid_s5z_s  : std_logic;
	signal m_data_s5z_s	  : image_t;

begin
	-- High-resolution predicted sample values (s)z(t)) calculation
	g_highres_pred_zaxis : for z in 0 to Nz_C-1 generate
		g_highres_pred_yaxis : for y in 0 to Ny_C-1 generate
			g_highres_pred_xaxis : for x in 0 to Nx_C-1 generate
				p_highres_pred : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_s5z_s(z)(y)(x) <= 0;
						else
							if (s_valid_pldz_i = '1' and s_ready_pldz_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1' and m_valid_s5z_s = '0') then
								m_data_s5z_s(z)(y)(x) <= clip(mod_R(s_data_pldz_i(z)(y)(x)+2**OMEGA_C*(s_data_lsz_i(z)(y)(x)-4*S_MID_G), Re_C)+2**(OMEGA_C+2)*S_MID_G+2**(OMEGA_C+1), 2**(OMEGA_C+2)*S_MIN_G, 2**(OMEGA_C+2)*S_MAX_G+2**(OMEGA_C+1));
							end if;
						end if;
					end if;
				end process p_highres_pred;
			end generate g_highres_pred_xaxis;
		end generate g_highres_pred_yaxis;
	end generate g_highres_pred_zaxis;

	-- Process for the hand-shaking signals
	p_highres_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_pldz_s <= '0';
				s_ready_lsz_s  <= '0';
				m_valid_s5z_s <= '0';
			else
				if (s_valid_pldz_i = '1' and s_ready_pldz_s = '1' and s_valid_lsz_i = '1' and s_ready_lsz_s = '1') then
					s_ready_pldz_s <= '0';
					s_ready_lsz_s  <= '0';
					m_valid_s5z_s <= '1';
				else
					s_ready_pldz_s <= '1';
					s_ready_lsz_s  <= '1';
				end if;
				
				if (m_valid_s5z_s = '1' and m_ready_s5z_i = '1') then
					m_valid_s5z_s <= '0';
				end if;
			end if;
		end if;
	end process p_highres_hand_shak;

	s_ready_pldz_o <= s_ready_pldz_s;
	s_ready_lsz_o  <= s_ready_lsz_s;
	m_valid_s5z_o  <= m_valid_s5z_s;
	m_data_s5z_o   <= m_data_s5z_s;

end behavioural;