library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;

entity spl_representative is
	generic (
		S_MAX_G			: integer;
		S_MIN_G			: integer
	);
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "s^z(t)" (predicted sample)
		s_valid_s3z_i	: in  std_logic;
		s_ready_s3z_o	: out std_logic;
		s_data_s3z_i	: in  image_t;
		
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
		
		-- Master (output) interface for signal "s''z(t)" (sample representative)
		m_valid_s2z_o	: out std_logic;
		m_ready_s2z_i	: in  std_logic;
		m_data_s2z_o	: out image_t
	);
end spl_representative;

architecture behavioural of spl_representative is
	signal s_ready_s3z_s : std_logic;
	signal s_ready_qz_s	 : std_logic;
	signal s_ready_mz_s	 : std_logic;
	signal m_valid_s2z_s : std_logic;
	signal m_data_s2z_s	 : image_t;
	
	signal valid_s1z_s	 : std_logic;
	signal ready_s1z_s	 : std_logic;
	signal data_s1z_s	 : image_t;

	signal valid_s4z_s	 : std_logic;
	signal ready_s4z_s	 : std_logic;
	signal data_s4z_s	 : image_t;
	
begin
	-- Clipped quantizer bin center (s'z(t)) calculation
	i_clip_quant_bin_cntr : clip_quant_bin_center
	generic map(
		S_MAX_G			=> S_MAX_G,
		S_MIN_G			=> S_MIN_G
	)
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,

		s_valid_s3z_i	=> s_valid_s3z_i,
		s_ready_s3z_o	=> s_ready_s3z_o,
		s_data_s3z_i	=> s_data_s3z_i,

		s_valid_qz_i	=> s_valid_qz_i,
		s_ready_qz_o	=> s_ready_qz_o,
		s_data_qz_i		=> s_data_qz_i,

		s_valid_mz_i	=> s_valid_mz_i,
		s_ready_mz_o	=> s_ready_mz_o,
		s_data_mz_i		=> s_data_mz_i,
		
		m_valid_s1z_o	=> valid_s1z_s,
		m_ready_s1z_i	=> ready_s1z_s,
		m_data_s1z_o	=> data_s1z_s
	);
	
	-- Double-resolution sample representative (s~''z(t)) calculation
	i_dbl_res_smpl_repr : double_res_smpl_repr
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,

		s_valid_s1z_i	=> valid_s1z_s,
		s_ready_s1z_o	=> ready_s1z_s,
		s_data_s1z_i	=> data_s1z_s,

		s_valid_qz_i	=> s_valid_qz_i,
		s_ready_qz_o	=> s_ready_qz_o,
		s_data_qz_i		=> s_data_qz_i,

		s_valid_mz_i	=> s_valid_mz_i,
		s_ready_mz_o	=> s_ready_mz_o,
		s_data_mz_i		=> s_data_mz_i,
		
		s_valid_s5z_i	=> s_valid_s5z_i,
		s_ready_s5z_o	=> s_ready_s5z_o,
		s_data_s5z_i	=> s_data_s5z_i,
		
		m_valid_s4z_o	=> valid_s4z_s,
		m_ready_s4z_i	=> ready_s4z_s,
		m_data_s4z_o	=> data_s4z_s
	);
	
	-- Sample representative values (s''z(t)) calculation
	g_smpl_repr_zaxis : for z in 0 to Nz_C-1 generate
		g_smpl_repr_yaxis : for y in 0 to Ny_C-1 generate
			g_smpl_repr_xaxis : for x in 0 to Nx_C-1 generate
				p_smpl_repr : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_s2z_s(z)(y)(x) <= 0;
						else
							if () then
								
							elsif (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and s_valid_qz_i = '1' and s_ready_qz_s = '1' and s_valid_mz_i = '1' and s_ready_mz_s = '1' and m_valid_s1z_s = '0') then
								m_data_s2z_s(z)(y)(x) <= round_down(real(m_data_s4z_s(z)(y)(x)+1)/real(2));
							end if;
						end if;
					end if;
				end process p_smpl_repr;
			end generate g_smpl_repr_xaxis;
		end generate g_smpl_repr_yaxis;
	end generate g_smpl_repr_zaxis;
	
	-- Process for the hand-shaking signals
	p_sampl_repr_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s3z_s <= '0';
				s_ready_qz_s  <= '0';
				s_ready_mz_s  <= '0';
				m_valid_s2z_s <= '0';
			else
				if (s_valid_s3z_i = '1' and s_ready_s3z_s = '1' and s_valid_qz_i = '1' and s_ready_qz_s = '1' and s_valid_mz_i = '1' and s_ready_mz_s = '1') then
					s_ready_s3z_s <= '0';
					s_ready_qz_s  <= '0';
					s_ready_mz_s  <= '0';
					m_valid_s2z_s <= '1';
				else
					s_ready_s3z_s <= '1';
					s_ready_qz_s  <= '1';
					s_ready_mz_s  <= '1';
				end if;
				
				if (m_valid_s2z_s = '1' and m_ready_s2z_i = '1') then
					m_valid_s2z_s <= '0';
				end if;
			end if;
		end if;
	end process p_sampl_repr_hand_shak;
	
	s_ready_s3z_o <= s_ready_s3z_s;
	s_ready_qz_o  <= s_ready_qz_s;
	s_ready_mz_o  <= s_ready_mz_s;
	m_valid_s2z_o <= m_valid_s2z_s;
	m_data_s2z_o  <= m_data_s2z_s;

end behavioural;