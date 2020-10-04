library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity local_differences is
	generic (
		AXIS_TDATA_WIDTH_G	: integer;
		AXIS_TID_WIDTH_G	: integer;
		AXIS_TDEST_WIDTH_G	: integer;
		AXIS_TUSER_WIDTH_G	: integer;
		PREDICTION_MODE_G	: std_logic		-- 1: Full prediction mode, 0: Reduced prediction mode
	);
	port (
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;
		
		-- AXIS slave (input) interface for "s''z(t)" (sample representative)
		s_axis_tvalid_s2z_i	: in  std_logic;
		s_axis_tready_s2z_o	: out std_logic;
		s_axis_tlast_s2z_i	: in  std_logic;
		s_axis_tdata_s2z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_s2z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_s2z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_s2z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_s2z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
		
		-- AXIS slave (input) interface for "sigma z(t)" (local sum)
		s_axis_tvalid_lsz_i	: in  std_logic;
		s_axis_tready_lsz_o	: out std_logic;
		s_axis_tlast_lsz_i	: in  std_logic;
		s_axis_tdata_lsz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_lsz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_lsz_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_lsz_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_lsz_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
		
		-- AXIS master (output) interface for "Uz(t)" (local difference vector)
		m_axis_tvalid_uz_o	: out std_logic;
		m_axis_tready_uz_i	: in  std_logic;
		m_axis_tlast_uz_o	: out std_logic;
		m_axis_tdata_uz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		m_axis_tkeep_uz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		m_axis_tid_uz_o		: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		m_axis_tdest_uz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		m_axis_tuser_uz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
	);
end local_differences;

architecture behavioural of local_differences is
begin

	g_prediction_mode : if PREDICTION_MODE_G = "1" generate	-- Full prediction mode
		
	else generate	-- Reduced prediction mode
		
	end generate g_prediction_mode;
	
end behavioural;