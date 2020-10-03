library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity quantizer is
	generic (
		AXIS_TDATA_WIDTH_G	: integer;
		AXIS_TID_WIDTH_G	: integer;
		AXIS_TDEST_WIDTH_G	: integer;
		AXIS_TUSER_WIDTH_G	: integer
	);
	port (
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;
		
		-- AXIS slave (input) interface for signal "/\z(t)"
		s_axis_tvalid_tz_i	: in  std_logic;
		s_axis_tready_tz_o	: out std_logic;
		s_axis_tlast_tz_i	: in  std_logic;
		s_axis_tdata_tz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_tz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_tz_i		: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_tz_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_tz_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);

		-- AXIS slave (input) interface for signal "s^z(t)"
		s_axis_tvalid_s3z_i	: in  std_logic;
		s_axis_tready_s3z_o	: out std_logic;
		s_axis_tlast_s3z_i	: in  std_logic;
		s_axis_tdata_s3z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_s3z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_s3z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_s3z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_s3z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);

		-- AXIS master (output) interface for signal "mz(t)"
		m_axis_tvalid_mz_o	: out std_logic;
		m_axis_tready_mz_i	: in  std_logic;
		m_axis_tlast_mz_o	: out std_logic;
		m_axis_tdata_mz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		m_axis_tkeep_mz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		m_axis_tid_mz_o		: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		m_axis_tdest_mz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		m_axis_tuser_mz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
		
		-- AXIS master (output) interface for signal "qz(t)"
		m_axis_tvalid_qz_o	: out std_logic;
		m_axis_tready_qz_i	: in  std_logic;
		m_axis_tlast_qz_o	: out std_logic;
		m_axis_tdata_qz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		m_axis_tkeep_qz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		m_axis_tid_qz_o		: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		m_axis_tdest_qz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		m_axis_tuser_qz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
	);
end quantizer;

architecture behavioural of quantizer is
begin

end behavioural;