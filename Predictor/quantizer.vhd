library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
	
entity quantizer is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0)
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "/\z(t)" (prediction residual)
		s_valid_tz_i	: in  std_logic;
		s_ready_tz_o	: out std_logic;
		s_data_tz_i		: in  image_t;

		-- Slave interface for signal "s^z(t)" (predicted sample)
		s_valid_s3z_i	: in  std_logic;
		s_ready_s3z_o	: out std_logic;
		s_data_s3z_i	: in  image_t;

		-- Master (output) interface for signal "mz(t)" (maximum error)
		m_valid_mz_o	: out std_logic;
		m_ready_mz_i	: in  std_logic;
		m_data_mz_o		: out image_t;
		
		-- Master (output) interface for signal "qz(t)" (quantizer index)
		m_valid_qz_o	: out std_logic;
		m_ready_qz_i	: in  std_logic;
		m_data_qz_o		: out image_t
	);
end quantizer;

architecture behavioural of quantizer is
	signal s_ready_tz_s	: std_logic;
	signal s_ready_s3z_s: std_logic;
	signal m_valid_mz_s	: std_logic;
	signal m_valid_qz_s	: std_logic;
	signal m_data_mz_s	: image_t;
	signal m_data_qz_s	: image_t;

begin
	-- Quantizer index (qz(t)) calculation
	g_zaxis_quantizer : for z in 0 to Nz_C-1 generate
		g_yaxis_quantizer : for y in 0 to Ny_C-1 generate
			g_xaxis_quantizer : for x in 0 to Nx_C-1 generate
				p_quantizer : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_qz_s(z)(y)(x) <= 0;
						else
							if (y = 0 and x = 0) then	-- t=0
								m_data_qz_s(z)(0)(0) <= s_data_tz_i(z)(0)(0);
							elsif (s_valid_tz_i = '1' and s_ready_tz_s = '1' and m_valid_mz_s = '1' and m_ready_mz_i = '1' and m_valid_qz_s = '0') then
								m_data_qz_s(z)(y)(x) <= sgn(s_data_tz_i(z)(y)(x))*round_down(real(abs_int(s_data_tz_i(z)(y)(x))+m_data_mz_s(z)(y)(x))/real(2*m_data_mz_s(z)(y)(x)+1));
							end if;
						end if;
					end if;
				end process p_quantizer;
			end generate g_xaxis_quantizer;
		end generate g_yaxis_quantizer;
	end generate g_zaxis_quantizer;

	-- Maximum error (mz(t)) calculation
	i_fidelity_ctrl : fidelity_control
	generic map(
		FIDEL_CTRL_TYPE_G => FIDEL_CTRL_TYPE_G
	)
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,

		s_valid_s3z_i	=> s_valid_s3z_i,
		s_ready_s3z_o	=> s_ready_s3z_s,
		s_data_s3z_i	=> s_data_s3z_i,

		m_valid_mz_o	=> m_valid_mz_s,
		m_ready_mz_i	=> m_ready_mz_i,
		m_data_mz_o		=> m_data_mz_s
	);

	-- Process for the hand-shaking signals
	p_quant_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_tz_s <= '0';
				m_valid_qz_s <= '0';
			else
				if (s_valid_tz_i = '1' and s_ready_tz_s = '1' and m_valid_mz_s = '1' and m_ready_mz_i = '1') then
					s_ready_tz_s <= '0';
					m_valid_qz_s <= '1';
				else
					s_ready_tz_s <= '1';
				end if;

				if (m_valid_qz_s = '1' and m_ready_qz_i = '1') then
					m_valid_qz_s <= '0';
				end if;
			end if;
		end if;
	end process p_quant_hand_shak;
	
	s_ready_tz_o  <= s_ready_tz_s;
	s_ready_s3z_o <= s_ready_s3z_s;
	m_valid_mz_o  <= m_valid_mz_s;
	m_valid_qz_o  <= m_valid_qz_s;
	m_data_mz_o	  <= m_data_mz_s;
	m_data_qz_o	  <= m_data_qz_s;

end behavioural;