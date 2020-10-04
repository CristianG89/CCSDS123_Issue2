library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
	
entity local_sum is
	generic (
		AXIS_TDATA_WIDTH_G	: integer;
		AXIS_TID_WIDTH_G	: integer;
		AXIS_TDEST_WIDTH_G	: integer;
		AXIS_TUSER_WIDTH_G	: integer;
		-- 00: Wide neighbour-oriented case, 01: Narrow neighbour-oriented case, 10: Wide column-oriented case, 11: Narrow column-oriented case
		LOCAL_SUM_TYPE_G	: std_logic_vector(1 downto 0)
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
		
		-- AXIS master (output) interface for "sigma z(t)" (local sum)
		m_axis_tvalid_lsz_o	: out std_logic;
		m_axis_tready_lsz_i	: in  std_logic;
		m_axis_tlast_lsz_o	: out std_logic;
		m_axis_tdata_lsz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		m_axis_tkeep_lsz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		m_axis_tid_lsz_o	: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		m_axis_tdest_lsz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		m_axis_tuser_lsz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
	);
end local_sum;

architecture behavioural of local_sum is
begin

	g_local_sum_type : case LOCAL_SUM_TYPE_G generate
	
		when "00" =>	-- Wide neighbour-oriented case
		
		when "01" =>	-- Narrow neighbour-oriented case
		
		when "10" =>	-- Wide column-oriented case
		
		when others =>	-- Narrow column-oriented case (when "11")

	end generate g_local_sum_type;

end behavioural;