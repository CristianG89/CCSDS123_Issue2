library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity local_sum is
	generic (
		DATA_WIDTH_G	: integer;
		S_MAX_G			: integer;
		S_MIN_G			: integer;
		LSUM_TYPE_G		: std_logic_vector(1 downto 0)	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave (input) interface for "s''z(t)" (sample representative)
		s_valid_s2z_i	: in  std_logic;
		s_ready_s2z_o	: out std_logic;
		s_data_s2z_i	: in  std_logic_vector(DATA_WIDTH_G-1 downto 0);
		
		-- Master (output) interface for "sigma z(t)" (local sum)
		m_valid_lsz_o	: out std_logic;
		m_ready_lsz_i	: in  std_logic;
		m_data_lsz_o	: out std_logic_vector(DATA_WIDTH_G-1 downto 0)
	);
end local_sum;

architecture behavioural of local_sum is
	signal s_ready_s2z_s : std_logic;
	signal m_valid_lsz_s : std_logic;
	signal m_data_lsz_s	 : std_logic_vector(DATA_WIDTH_G-1 downto 0);

begin
	-- Local sum calculation
	g_lsum_type : case LSUM_TYPE_G generate
		when "00" =>	-- Wide neighbour-oriented case
			g_lsum_zaxis_wi_ne : for z in 0 to Nz_C-1 generate
				g_lsum_yaxis_wi_ne : for y in 0 to Ny_C-1 generate
					g_lsum_xaxis_wi_ne : for x in 0 to Nx_C-1 generate
						p_lsum_wi_ne : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_lsz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and m_valid_lsz_s = '0') then
										if (y > 0 and x > 0 and x < Nx_C-1) then
											m_data_lsz_s(z)(y)(x) <= s_data_s2z_i(z)(y)(x-1) + s_data_s2z_i(z)(y-1)(x-1) + s_data_s2z_i(z)(y-1)(x) + s_data_s2z_i(z)(y-1)(x+1);
										elsif (y = 0 and x > 0) then
											m_data_lsz_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y)(x-1);
										elsif (y > 0 and x = 0) then
											m_data_lsz_s(z)(y)(x) <= 2*(s_data_s2z_i(z)(y-1)(x) + s_data_s2z_i(z)(y-1)(x+1));
										elsif (y > 0 and x = Nx_C-1) then
											m_data_lsz_s(z)(y)(x) <= s_data_s2z_i(z)(y)(x-1) + s_data_s2z_i(z)(y-1)(x-1) + 2*s_data_s2z_i(z)(y-1)(x);
										else	-- Just in case to avoid latches
											m_data_lsz_s(z)(y)(x) <= 0;
										end if;
									end if;
								end if;
							end if;
						end process p_lsum_wi_ne;
					end generate g_lsum_xaxis_wi_ne;
				end generate g_lsum_yaxis_wi_ne;
			end generate g_lsum_zaxis_wi_ne;

		when "01" =>	-- Narrow neighbour-oriented case
			g_lsum_zaxis_na_ne : for z in 0 to Nz_C-1 generate
				g_lsum_yaxis_na_ne : for y in 0 to Ny_C-1 generate
					g_lsum_xaxis_na_ne : for x in 0 to Nx_C-1 generate
						p_lsum_na_ne : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_lsz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and m_valid_lsz_s = '0') then
										if (y > 0 and x > 0 and x < Nx_C-1) then
											m_data_lsz_s(z)(y)(x) <= s_data_s2z_i(z)(y-1)(x-1) + 2*s_data_s2z_i(z)(y-1)(x) + s_data_s2z_i(z)(y-1)(x+1);
										elsif (y = 0 and x > 0 and z > 0) then
											m_data_lsz_s(z)(y)(x) <= 4*s_data_s2z_i(z-1)(y)(x-1);
										elsif (y > 0 and x = 0) then
											m_data_lsz_s(z)(y)(x) <= 2*(s_data_s2z_i(z)(y-1)(x) + s_data_s2z_i(z)(y-1)(x+1));
										elsif (y > 0 and x = Nx_C-1) then
											m_data_lsz_s(z)(y)(x) <= 2*(s_data_s2z_i(z)(y-1)(x-1) + s_data_s2z_i(z)(y-1)(x));
										elsif (y = 0 and x > 0 and z = 0) then
											m_data_lsz_s(z)(y)(x) <= 4*S_MID_C;
										else	-- Just in case to avoid latches
											m_data_lsz_s(z)(y)(x) <= 0;
										end if;
									end if;
								end if;
							end if;
						end process p_lsum_na_ne;
					end generate g_lsum_xaxis_na_ne;
				end generate g_lsum_yaxis_na_ne;
			end generate g_lsum_zaxis_na_ne;

		when "10" =>	-- Wide column-oriented case
			g_lsum_zaxis_wi_co : for z in 0 to Nz_C-1 generate
				g_lsum_yaxis_wi_co : for y in 0 to Ny_C-1 generate
					g_lsum_xaxis_wi_co : for x in 0 to Nx_C-1 generate
						p_lsum_wi_co : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_lsz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and m_valid_lsz_s = '0') then
										if (y > 0) then
											m_data_lsz_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y-1)(x);
										elsif (y = 0 and x > 0) then
											m_data_lsz_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y)(x-1);
										else	-- Just in case to avoid latches
											m_data_lsz_s(z)(y)(x) <= 0;
										end if;
									end if;
								end if;
							end if;
						end process p_lsum_wi_co;
					end generate g_lsum_xaxis_wi_co;
				end generate g_lsum_yaxis_wi_co;
			end generate g_lsum_zaxis_wi_co;
			
		when others =>	-- Narrow column-oriented case (when "11")
			g_lsum_zaxis_na_co : for z in 0 to Nz_C-1 generate
				g_lsum_yaxis_na_co : for y in 0 to Ny_C-1 generate
					g_lsum_xaxis_na_co : for x in 0 to Nx_C-1 generate
						p_lsum_na_co : process(clk_i) is
						begin
							if rising_edge(clk_i) then
								if (rst_i = '0') then
									m_data_lsz_s(z)(y)(x) <= 0;
								else
									if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1' and m_valid_lsz_s = '0') then
										if (y > 0) then
											m_data_lsz_s(z)(y)(x) <= 4*s_data_s2z_i(z)(y-1)(x);
										elsif (y = 0 and x > 0 and z > 0) then
											m_data_lsz_s(z)(y)(x) <= 4*s_data_s2z_i(z-1)(y)(x-1);
										elsif (y = 0 and x > 0 and z = 0) then
											m_data_lsz_s(z)(y)(x) <= 4*S_MID_C;
										else	-- Just in case to avoid latches
											m_data_lsz_s(z)(y)(x) <= 0;
										end if;
									end if;
								end if;
							end if;
						end process p_lsum_na_co;
					end generate g_lsum_xaxis_na_co;
				end generate g_lsum_yaxis_na_co;
			end generate g_lsum_zaxis_na_co;
	end generate g_lsum_type;

	-- Process for the hand-shaking signals
	p_lsum_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s2z_s <= '0';
				m_valid_lsz_s <= '0';
			else
				if (s_valid_s2z_i = '1' and s_ready_s2z_s = '1') then
					s_ready_s2z_s <= '0';
					m_valid_lsz_s <= '1';
				else
					s_ready_s2z_s <= '1';
				end if;
				
				if (m_valid_lsz_s = '1' and m_ready_lsz_i = '1') then
					m_valid_lsz_s <= '0';
				end if;
			end if;
		end if;
	end process p_lsum_hand_shak;

	s_ready_s2z_o <= s_ready_s2z_s;
	m_valid_lsz_o <= m_valid_lsz_s;
	m_data_lsz_o  <= m_data_lsz_s;

end behavioural;