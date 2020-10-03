library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity mapper is
	generic (
		AXIS_TDATA_WIDTH_G	: integer;
		AXIS_TID_WIDTH_G	: integer;
		AXIS_TDEST_WIDTH_G	: integer;
		AXIS_TUSER_WIDTH_G	: integer
	);
	port (
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;
		
		-- AXIS slave (input) interface for signal "qz(t)"
		s_axis_tvalid_qz_i	: in  std_logic;
		s_axis_tready_qz_o	: out std_logic;
		s_axis_tlast_qz_i	: in  std_logic;
		s_axis_tdata_qz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_qz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_qz_i		: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_qz_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_qz_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
		
		-- AXIS slave (input) interface for signal "s^z(t)"
		s_axis_tvalid_s3z_i	: in  std_logic;
		s_axis_tready_s3z_o	: out std_logic;
		s_axis_tlast_s3z_i	: in  std_logic;
		s_axis_tdata_s3z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_s3z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_s3z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_s3z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_s3z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);

		-- AXIS slave (input) interface for signal "mz(t)"
		s_axis_tvalid_mz_i	: in  std_logic;
		s_axis_tready_mz_o	: out std_logic;
		s_axis_tlast_mz_i	: in  std_logic;
		s_axis_tdata_mz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_mz_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_mz_i		: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_mz_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_mz_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
		
		-- AXIS master (output) interface for signal "dz(t)"
		m_axis_tvalid_dz_o	: out std_logic;
		m_axis_tready_dz_i	: in  std_logic;
		m_axis_tlast_dz_o	: out std_logic;
		m_axis_tdata_dz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		m_axis_tkeep_dz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		m_axis_tid_dz_o		: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		m_axis_tdest_dz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		m_axis_tuser_dz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
	);
end mapper;

architecture behavioural of mapper is
begin

end behavioural;