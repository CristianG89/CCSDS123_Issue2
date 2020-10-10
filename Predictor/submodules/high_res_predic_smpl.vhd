library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity high_res_predic_smpl is
	generic (
		DATA_WIDTH_G	: integer;
		S_MAX_G			: integer;
		S_MIN_G			: integer	
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;

		-- Slave (input) interface for signal "s^z(t)"
		s_valid_s3z_i	: in  std_logic;
		s_ready_s3z_o	: out std_logic;
		s_data_s3z_i	: in  std_logic_vector(DATA_WIDTH_G-1 downto 0);

		-- Slave (input) interface for signal "qz(t)"
		s_valid_qz_i	: in  std_logic;
		s_ready_qz_o	: out std_logic;
		s_data_qz_i		: in  std_logic_vector(DATA_WIDTH_G-1 downto 0);

		-- Slave (input) interface for signal "mz(t)"
		s_valid_mz_i	: in  std_logic;
		s_ready_mz_o	: out std_logic;
		s_data_mz_i		: in  std_logic_vector(DATA_WIDTH_G-1 downto 0);
		
		-- Master (output) interface for signal "s)z(t)"
		m_valid_s5z_o	: out std_logic;
		m_ready_s5z_i	: in  std_logic;
		m_data_s5z_o	: out std_logic_vector(DATA_WIDTH_G-1 downto 0)
	);
end high_res_predic_smpl;

architecture behavioural of high_res_predic_smpl is
	signal s_ready_s3z_s : std_logic;
	signal s_ready_qz_s	 : std_logic;
	signal s_ready_mz_s	 : std_logic;
	signal m_valid_s5z_s : std_logic;
	signal m_data_s5z_s	 : std_logic_vector(DATA_WIDTH_G-1 downto 0);

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
							if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and s_valid_qz_i = '1' and s_ready_qz_s = '1' and s_valid_mz_i = '1' and s_ready_mz_s = '1' and m_valid_s5z_s = '0') then
								m_data_s5z_s(z)(y)(x) <= clip(s_data_s3z_i(z)(y)(x)+s_data_qz_i(z)(y)(x)*(2*s_data_mz_i(z)(y)(x)+1), S_MAX_G, S_MIN_G);
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
				s_ready_s3z_s <= '0';
				s_ready_qz_s  <= '0';
				s_ready_mz_s  <= '0';
				m_valid_s5z_s <= '0';
			else
				if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and s_valid_qz_i = '1' and s_ready_qz_s = '1' and s_valid_mz_i = '1' and s_ready_mz_s = '1') then
					s_ready_s3z_s <= '0';
					s_ready_qz_s  <= '0';
					s_ready_mz_s  <= '0';
					m_valid_s5z_s <= '1';
				else
					s_ready_s3z_s <= '1';
					s_ready_qz_s  <= '1';
					s_ready_mz_s  <= '1';
				end if;
				
				if (m_valid_s5z_s = '1' and m_ready_s5z_i = '1') then
					m_valid_s5z_s <= '0';
				end if;
			end if;
		end if;
	end process p_highres_hand_shak;

	s_ready_s3z_o <= s_ready_s3z_s;
	s_ready_qz_o  <= s_ready_qz_s;
	s_ready_mz_o  <= s_ready_mz_s;
	m_valid_s5z_o <= m_valid_s5z_s;
	m_data_s5z_o  <= m_data_s5z_s;

end behavioural;