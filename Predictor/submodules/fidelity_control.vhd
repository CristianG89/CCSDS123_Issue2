library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;
	
entity fidelity_control is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;

		-- Slave interface for signal "s^z(t)" (predicted sample)
		s_valid_s3z_i	: in  std_logic;
		s_ready_s3z_o	: out std_logic;
		s_data_s3z_i	: in  image_t;

		-- Master interface for signal "mz(t)" (maximum error)
		m_valid_mz_o	: out std_logic;
		m_ready_mz_i	: in  std_logic;
		m_data_mz_o		: out image_t
	);
end fidelity_control;

architecture behavioural of fidelity_control is
	signal s_ready_s3z_s : std_logic;
	signal m_valid_mz_s	 : std_logic;
	signal m_data_mz_s	 : image_t;

begin
	-- Maximum error value (mz(t)) calculation
	g_merr_type : case FIDEL_CTRL_TYPE_G generate
		when "00" =>	-- Lossless method
			m_data_mz_s <= (others => (others => (others => 0)));

		when "01" =>	-- ONLY absolute error limit method
			g_merr_zaxis_abs : for z in 0 to Nz_C-1 generate
				g_merr_yaxis_abs : for y in 0 to Ny_C-1 generate
					g_merr_xaxis_abs : for x in 0 to Nx_C-1 generate
						p_merr_abs : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_mz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and m_valid_mz_s = '0') then
										m_data_mz_s(z)(y)(x) <= Az_C;
									end if;
								end if;
							end if;
						end process p_merr_abs;
					end generate g_merr_xaxis_abs;
				end generate g_merr_yaxis_abs;
			end generate g_merr_zaxis_abs;

		when "10" =>	-- ONLY relative error limit method
			g_merr_zaxis_rel : for z in 0 to Nz_C-1 generate
				g_merr_yaxis_rel : for y in 0 to Ny_C-1 generate
					g_merr_xaxis_rel : for x in 0 to Nx_C-1 generate
						p_merr_rel : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_mz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and m_valid_mz_s = '0') then
										m_data_mz_s(z)(y)(x) <= round_down(real(Rz_C)*real(abs_int(s_data_s3z_i(z)(y)(x)))/real(2**D_C));
									end if;
								end if;
							end if;
						end process p_merr_rel;
					end generate g_merr_xaxis_rel;
				end generate g_merr_yaxis_rel;
			end generate g_merr_zaxis_rel;
	
		when others =>	-- BOTH absolute and relative error limits
			g_merr_zaxis_abs_rel : for z in 0 to Nz_C-1 generate
				g_merr_yaxis_abs_rel : for y in 0 to Ny_C-1 generate
					g_merr_xaxis_abs_rel : for x in 0 to Nx_C-1 generate
						p_merr_abs_rel : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_mz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and m_valid_mz_s = '0') then
										m_data_mz_s(z)(y)(x) <= min(Az_C, round_down(real(Rz_C)*real(abs_int(s_data_s3z_i(z)(y)(x)))/real(2**D_C)));
									end if;
								end if;
							end if;
						end process p_merr_abs_rel;
					end generate g_merr_xaxis_abs_rel;
				end generate g_merr_yaxis_abs_rel;
			end generate g_merr_zaxis_abs_rel;
	end generate g_merr_type;

	-- Process for the hand-shaking signals
	p_merr_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s3z_s <= '0';
				m_valid_mz_s <= '0';
			else
				if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1') then
					s_ready_s3z_s <= '0';
					m_valid_mz_s <= '1';
				else
					s_ready_s3z_s <= '1';
				end if;
				
				if (m_valid_mz_s = '1' and m_ready_mz_i = '1') then
					m_valid_mz_s <= '0';
				end if;
			end if;
		end if;
	end process p_merr_hand_shak;

	s_ready_s3z_o <= s_ready_s3z_s;
	m_valid_mz_o  <= m_valid_mz_s;
	m_data_mz_o	  <= m_data_mz_s;

end behavioural;