library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity axis_adder is
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "sz(t)" (clipped quantizer bin center)
		s_valid_s0z_i	: in  std_logic;
		s_ready_s0z_o	: out std_logic;
		s_data_s0z_i	: in  image_t;

		-- Slave interface for signal "s^z(t)" (predicted sample)
		s_valid_s3z_i	: in  std_logic;
		s_ready_s3z_o	: out std_logic;
		s_data_s3z_i	: in  image_t;
		
		-- Master interface for signal "/\z(t)" (prediction residual)
		m_valid_tz_o	: out std_logic;
		m_ready_tz_i	: in  std_logic;
		m_data_tz_o		: out image_t
	);
end axis_adder;

architecture behavioural of axis_adder is
	signal s_ready_s0z_s : std_logic;
	signal s_ready_s3z_s : std_logic;
	signal m_valid_tz_s	 : std_logic;
	signal m_data_tz_s	 : image_t;

begin
	-- Prediction residual (/\z(t)) calculation
	g_adder_zaxis : for z in 0 to Nz_C-1 generate
		g_adder_yaxis : for y in 0 to Ny_C-1 generate
			g_adder_xaxis : for x in 0 to Nx_C-1 generate
				p_adder : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_tz_s(z)(y)(x) <= 0;
						else
							if (s_valid_s0z_i = '1' and s_ready_s0z_s = '1' and s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and m_valid_tz_s = '0') then
								m_data_tz_s(z)(y)(x) <= s_data_s0z_i(z)(y)(x) - s_data_s3z_i(z)(y)(x);
							end if;
						end if;
					end if;
				end process p_adder;
			end generate g_adder_xaxis;
		end generate g_adder_yaxis;
	end generate g_adder_zaxis;

	-- Process for the hand-shaking signals
	p_adder_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s0z_s <= '0';
				s_ready_s3z_s <= '0';
				m_valid_tz_s <= '0';
			else
				if (s_valid_s0z_i = '1' and s_ready_s0z_s = '1' and s_valid_s3z_i = '1' and s_ready_s3z_s = '1') then
					s_ready_s0z_s <= '0';
					s_ready_s3z_s <= '0';
					m_valid_tz_s <= '1';
				else
					s_ready_s0z_s <= '1';
					s_ready_s3z_s <= '1';
				end if;
				
				if (m_valid_tz_s = '1' and m_ready_tz_i = '1') then
					m_valid_tz_s <= '0';
				end if;
			end if;
		end if;
	end process p_adder_hand_shak;
	
	s_ready_s0z_o <= s_ready_s0z_s;
	s_ready_s3z_o <= s_ready_s3z_s;
	m_valid_tz_o  <= m_valid_tz_s;
	m_data_tz_o	  <= m_data_tz_s;
end behavioural;