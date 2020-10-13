library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
	
entity double_res_pred_error is
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "s'z(t)" (clipped quantizer bin center)
		s_valid_s1z_i	: in  std_logic;
		s_ready_s1z_o	: out std_logic;
		s_data_s1z_i	: in  image_t;

		-- Slave interface for signal "s~z(t)" (double-resolution predicted sample)
		s_valid_s6z_i	: in  std_logic;
		s_ready_s6z_o	: out std_logic;
		s_data_s6z_i	: in  image_t;
		
		-- Master interface for signal "ez(t)" (double-resolution prediction error)
		m_valid_ez_o	: out std_logic;
		m_ready_ez_i	: in  std_logic;
		m_data_ez_o		: out image_t
	);
end double_res_pred_error;

architecture behavioural of double_res_pred_error is
	signal s_ready_s1z_s : std_logic;
	signal s_ready_s6z_s : std_logic;
	signal m_valid_ez_s	 : std_logic;
	signal m_data_ez_s	 : image_t;

begin
	-- Double-resolution prediction error (ez(t)) calculation
	g_dbl_res_err_zaxis : for z in 0 to Nz_C-1 generate
		g_dbl_res_err_yaxis : for y in 0 to Ny_C-1 generate
			g_dbl_res_err_xaxis : for x in 0 to Nx_C-1 generate
				p_dbl_res_err : process(clk_i) is
				begin
					if rising_edge(clk_i) then
						if (rst_i = '0') then
							m_data_ez_s(z)(y)(x) <= 0;
						else
							if (s_valid_s1z_i = '1' and s_ready_s1z_s = '1' and s_valid_s6z_i = '1' and s_ready_s6z_s = '1' and m_valid_ez_s = '0') then
								m_data_ez_s(z)(y)(x) <= 2*s_data_s1z_i(z)(y)(x) - s_data_s6z_i(z)(y)(x);
							end if;
						end if;
					end if;
				end process p_dbl_res_err;
			end generate g_dbl_res_err_xaxis;
		end generate g_dbl_res_err_yaxis;
	end generate g_dbl_res_err_zaxis;

	-- Process for the hand-shaking signals
	p_dbl_res_err_hand_shak : process(clk_i) is
	begin
		if rising_edge(clk_i) then
			if (rst_i = '0') then
				s_ready_s1z_s <= '0';
				s_ready_s6z_s <= '0';
				m_valid_ez_s <= '0';
			else
				if (s_valid_s1z_i = '1' and s_ready_s1z_s = '1' and s_valid_s6z_i = '1' and s_ready_s6z_s = '1') then
					s_ready_s1z_s <= '0';
					s_ready_s6z_s <= '0';
					m_valid_ez_s <= '1';
				else
					s_ready_s1z_s <= '1';
					s_ready_s6z_s <= '1';
				end if;
				
				if (m_valid_ez_s = '1' and m_ready_ez_i = '1') then
					m_valid_ez_s <= '0';
				end if;
			end if;
		end if;
	end process p_dbl_res_err_hand_shak;
	
	s_ready_s1z_o <= s_ready_s1z_s;
	s_ready_s6z_o <= s_ready_s6z_s;
	m_valid_ez_o  <= m_valid_ez_s;
	m_data_ez_o	  <= m_data_ez_s;
end behavioural;