library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.comp_predictor.all;
	
entity predictor_top is
	generic (
		AXIS_TDATA_WIDTH_G	: integer := 64;
		AXIS_TID_WIDTH_G	: integer := 0;
		AXIS_TDEST_WIDTH_G	: integer := 0;
		AXIS_TUSER_WIDTH_G	: integer := 0
	);
	port (
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;
		
		-- AXIS slave (input) interface for signal "sz(t)"
		s_axis_tvalid_s0z_i	: in  std_logic;
		s_axis_tready_s0z_o	: out std_logic;
		s_axis_tlast_s0z_i	: in  std_logic;
		s_axis_tdata_s0z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
		s_axis_tkeep_s0z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
		s_axis_tid_s0z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
		s_axis_tdest_s0z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
		s_axis_tuser_s0z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
		
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
end predictor_top;

architecture behavioural of predictor_top is	
	-- Record already size-limited for generic AXI-Stream interface
	subtype axi_stream_if_t is axi_stream_t (
		tdata(AXIS_TDATA_WIDTH_G-1 downto 0),	-- Only sizes to be limited are defined here
		tkeep(AXIS_TDATA_WIDTH_G/8-1 downto 0),
		tid	 (AXIS_TID_WIDTH_G-1 downto 0),
		tdest(AXIS_TDEST_WIDTH_G-1 downto 0),
		tuser(AXIS_TUSER_WIDTH_G-1 downto 0)
	);
	
	-- Intermediate signals for interconnect
	signal axis_s3z_s	: axi_stream_if_t;	-- Intermediate interface for "s^z(t)"
	signal axis_s2z_s	: axi_stream_if_t;	-- Intermediate interface for "s''z(t)"
	signal axis_tz_s	: axi_stream_if_t;	-- Intermediate interface for "/\z(t)"
	signal axis_mz_s	: axi_stream_if_t;	-- Intermediate interface for "mz(t)"
	signal axis_qz_s	: axi_stream_if_t;	-- Intermediate interface for "qz(t)"
	
begin
	-- Adder module
	i_axis_adder : axis_adder
	generic map(
		AXIS_TDATA_WIDTH_G	=> AXIS_TDATA_WIDTH_G,
		AXIS_TID_WIDTH_G	=> AXIS_TID_WIDTH_G,
		AXIS_TDEST_WIDTH_G	=> AXIS_TDEST_WIDTH_G,
		AXIS_TUSER_WIDTH_G	=> AXIS_TUSER_WIDTH_G
	)
	port map(
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		
		-- AXIS slave (input) interface for signal sz(t)"
		s_axis_tvalid_s0z_i	=> s_axis_tvalid_s0z_i,
		s_axis_tready_s0z_o	=> s_axis_tready_s0z_o,
		s_axis_tlast_s0z_i	=> s_axis_tlast_s0z_i,
		s_axis_tdata_s0z_i	=> s_axis_tdata_s0z_i,
		s_axis_tkeep_s0z_i	=> s_axis_tkeep_s0z_i,
		s_axis_tid_s0z_i	=> s_axis_tid_s0z_i,
		s_axis_tdest_s0z_i	=> s_axis_tdest_s0z_i,
		s_axis_tuser_s0z_i	=> s_axis_tuser_s0z_i,

		-- AXIS slave (input) interface for signal "s^z(t)"
		s_axis_tvalid_s3z_i	=> axis_s3z_s.tvalid,
		s_axis_tready_s3z_o	=> axis_s3z_s.tready,
		s_axis_tlast_s3z_i	=> axis_s3z_s.tlast,
		s_axis_tdata_s3z_i	=> axis_s3z_s.tdata,
		s_axis_tkeep_s3z_i	=> axis_s3z_s.tkeep,
		s_axis_tid_s3z_i	=> axis_s3z_s.tid,
		s_axis_tdest_s3z_i	=> axis_s3z_s.tdest,
		s_axis_tuser_s3z_i	=> axis_s3z_s.tuser,
		
		-- AXIS master (output) interface for signal "/\z(t)"
		m_axis_tvalid_tz_o	=> axis_tz_s.tvalid,
		m_axis_tready_tz_i	=> axis_tz_s.tready,
		m_axis_tlast_tz_o	=> axis_tz_s.tlast,
		m_axis_tdata_tz_o	=> axis_tz_s.tdata,
		m_axis_tkeep_tz_o	=> axis_tz_s.tkeep,
		m_axis_tid_tz_o		=> axis_tz_s.tid,
		m_axis_tdest_tz_o	=> axis_tz_s.tdest,
		m_axis_tuser_tz_o	=> axis_tz_s.tuser
	);
	
	-- Quantizer module
	i_quantizer : quantizer
	generic map(
		AXIS_TDATA_WIDTH_G	=> AXIS_TDATA_WIDTH_G,
		AXIS_TID_WIDTH_G	=> AXIS_TID_WIDTH_G,
		AXIS_TDEST_WIDTH_G	=> AXIS_TDEST_WIDTH_G,
		AXIS_TUSER_WIDTH_G	=> AXIS_TUSER_WIDTH_G
	)
	port map(
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		
		-- AXIS slave (input) interface for signal "/\z(t)"
		s_axis_tvalid_tz_i	=> axis_tz_s.tvalid,
		s_axis_tready_tz_o	=> axis_tz_s.tready,
		s_axis_tlast_tz_i	=> axis_tz_s.tlast,
		s_axis_tdata_tz_i	=> axis_tz_s.tdata,
		s_axis_tkeep_tz_i	=> axis_tz_s.tkeep,
		s_axis_tid_tz_i		=> axis_tz_s.tid,
		s_axis_tdest_tz_i	=> axis_tz_s.tdest,
		s_axis_tuser_tz_i	=> axis_tz_s.tuser,

		-- AXIS slave (input) interface for signal "s^z(t)"
		s_axis_tvalid_s3z_i	=> axis_s3z_s.tvalid,
		s_axis_tready_s3z_o	=> axis_s3z_s.tready,
		s_axis_tlast_s3z_i	=> axis_s3z_s.tlast,
		s_axis_tdata_s3z_i	=> axis_s3z_s.tdata,
		s_axis_tkeep_s3z_i	=> axis_s3z_s.tkeep,
		s_axis_tid_s3z_i	=> axis_s3z_s.tid,
		s_axis_tdest_s3z_i	=> axis_s3z_s.tdest,
		s_axis_tuser_s3z_i	=> axis_s3z_s.tuser,

		-- AXIS master (output) interface for signal "mz(t)"
		m_axis_tvalid_mz_o	=> axis_mz_s.tvalid,
		m_axis_tready_mz_i	=> axis_mz_s.tready,
		m_axis_tlast_mz_o	=> axis_mz_s.tlast,
		m_axis_tdata_mz_o	=> axis_mz_s.tdata,
		m_axis_tkeep_mz_o	=> axis_mz_s.tkeep,
		m_axis_tid_mz_o		=> axis_mz_s.tid,
		m_axis_tdest_mz_o	=> axis_mz_s.tdest,
		m_axis_tuser_mz_o	=> axis_mz_s.tuser,
		
		-- AXIS master (output) interface for signal "qz(t)"
		m_axis_tvalid_qz_o	=> axis_qz_s.tvalid,
		m_axis_tready_qz_i	=> axis_qz_s.tready,
		m_axis_tlast_qz_o	=> axis_qz_s.tlast,
		m_axis_tdata_qz_o	=> axis_qz_s.tdata,
		m_axis_tkeep_qz_o	=> axis_qz_s.tkeep,
		m_axis_tid_qz_o		=> axis_qz_s.tid,
		m_axis_tdest_qz_o	=> axis_qz_s.tdest,
		m_axis_tuser_qz_o	=> axis_qz_s.tuser
	);
	
	-- Mapper module
	i_mapper : mapper
	generic map(
		AXIS_TDATA_WIDTH_G	=> AXIS_TDATA_WIDTH_G,
		AXIS_TID_WIDTH_G	=> AXIS_TID_WIDTH_G,
		AXIS_TDEST_WIDTH_G	=> AXIS_TDEST_WIDTH_G,
		AXIS_TUSER_WIDTH_G	=> AXIS_TUSER_WIDTH_G
	)
	port map(
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		
		-- AXIS slave (input) interface for signal "qz(t)"
		s_axis_tvalid_qz_i	=> axis_qz_s.tvalid,
		s_axis_tready_qz_o	=> axis_qz_s.tready,
		s_axis_tlast_qz_i	=> axis_qz_s.tlast,
		s_axis_tdata_qz_i	=> axis_qz_s.tdata,
		s_axis_tkeep_qz_i	=> axis_qz_s.tkeep,
		s_axis_tid_qz_i		=> axis_qz_s.tid,
		s_axis_tdest_qz_i	=> axis_qz_s.tdest,
		s_axis_tuser_qz_i	=> axis_qz_s.tuser,
		
		-- AXIS slave (input) interface for signal "s^z(t)"
		s_axis_tvalid_s3z_i	=> axis_s3z_s.tvalid,
		s_axis_tready_s3z_o	=> axis_s3z_s.tready,
		s_axis_tlast_s3z_i	=> axis_s3z_s.tlast,
		s_axis_tdata_s3z_i	=> axis_s3z_s.tdata,
		s_axis_tkeep_s3z_i	=> axis_s3z_s.tkeep,
		s_axis_tid_s3z_i	=> axis_s3z_s.tid,
		s_axis_tdest_s3z_i	=> axis_s3z_s.tdest,
		s_axis_tuser_s3z_i	=> axis_s3z_s.tuser,
		
		-- AXIS slave (input) interface for signal "mz(t)"		
		s_axis_tvalid_mz_i	=> axis_mz_s.tvalid,
		s_axis_tready_mz_o	=> axis_mz_s.tready,
		s_axis_tlast_mz_i	=> axis_mz_s.tlast,
		s_axis_tdata_mz_i	=> axis_mz_s.tdata,
		s_axis_tkeep_mz_i	=> axis_mz_s.tkeep,
		s_axis_tid_mz_i		=> axis_mz_s.tid,
		s_axis_tdest_mz_i	=> axis_mz_s.tdest,
		s_axis_tuser_mz_i	=> axis_mz_s.tuser,
		
		-- AXIS master (output) interface for signal "dz(t)"
		m_axis_tvalid_dz_o	=> m_axis_tvalid_dz_o,
		m_axis_tready_dz_i	=> m_axis_tready_dz_i,
		m_axis_tlast_dz_o	=> m_axis_tlast_dz_o,
		m_axis_tdata_dz_o	=> m_axis_tdata_dz_o,
		m_axis_tkeep_dz_o	=> m_axis_tkeep_dz_o,
		m_axis_tid_dz_o		=> m_axis_tid_dz_o,
		m_axis_tdest_dz_o	=> m_axis_tdest_dz_o,
		m_axis_tuser_dz_o	=> m_axis_tuser_dz_o
	);

	-- Sample Representative module
	i_spl_representative : spl_representative
	generic map(
		AXIS_TDATA_WIDTH_G	=> AXIS_TDATA_WIDTH_G,
		AXIS_TID_WIDTH_G	=> AXIS_TID_WIDTH_G,
		AXIS_TDEST_WIDTH_G	=> AXIS_TDEST_WIDTH_G,
		AXIS_TUSER_WIDTH_G	=> AXIS_TUSER_WIDTH_G
	)
	port map(
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		
		-- AXIS slave (input) interface for signal "qz(t)"
		s_axis_tvalid_qz_i	=> axis_qz_s.tvalid,
		s_axis_tready_qz_o	=> axis_qz_s.tready,
		s_axis_tlast_qz_i	=> axis_qz_s.tlast,
		s_axis_tdata_qz_i	=> axis_qz_s.tdata,
		s_axis_tkeep_qz_i	=> axis_qz_s.tkeep,
		s_axis_tid_qz_i		=> axis_qz_s.tid,
		s_axis_tdest_qz_i	=> axis_qz_s.tdest,
		s_axis_tuser_qz_i	=> axis_qz_s.tuser,

		-- AXIS slave (input) interface for signal "s^z(t)"
		s_axis_tvalid_s3z_i	=> axis_s3z_s.tvalid,
		s_axis_tready_s3z_o	=> axis_s3z_s.tready,
		s_axis_tlast_s3z_i	=> axis_s3z_s.tlast,
		s_axis_tdata_s3z_i	=> axis_s3z_s.tdata,
		s_axis_tkeep_s3z_i	=> axis_s3z_s.tkeep,
		s_axis_tid_s3z_i	=> axis_s3z_s.tid,
		s_axis_tdest_s3z_i	=> axis_s3z_s.tdest,
		s_axis_tuser_s3z_i	=> axis_s3z_s.tuser,
		
		-- AXIS slave (input) interface for signal "mz(t)"
		s_axis_tvalid_mz_i	=> axis_mz_s.tvalid,
		s_axis_tready_mz_o	=> axis_mz_s.tready,
		s_axis_tlast_mz_i	=> axis_mz_s.tlast,
		s_axis_tdata_mz_i	=> axis_mz_s.tdata,
		s_axis_tkeep_mz_i	=> axis_mz_s.tkeep,
		s_axis_tid_mz_i		=> axis_mz_s.tid,
		s_axis_tdest_mz_i	=> axis_mz_s.tdest,
		s_axis_tuser_mz_i	=> axis_mz_s.tuser,
		
		-- AXIS master (output) interface for signal "s''z(t)"
		m_axis_tvalid_s2z_o	=> axis_s2z_s.tvalid,
		m_axis_tready_s2z_i	=> axis_s2z_s.tready,
		m_axis_tlast_s2z_o	=> axis_s2z_s.tlast,
		m_axis_tdata_s2z_o	=> axis_s2z_s.tdata,
		m_axis_tkeep_s2z_o	=> axis_s2z_s.tkeep,
		m_axis_tid_s2z_o	=> axis_s2z_s.tid,
		m_axis_tdest_s2z_o	=> axis_s2z_s.tdest,
		m_axis_tuser_s2z_o	=> axis_s2z_s.tuser
	);

	-- Prediction module
	i_prediction : prediction
	generic map(
		AXIS_TDATA_WIDTH_G	=> AXIS_TDATA_WIDTH_G,
		AXIS_TID_WIDTH_G	=> AXIS_TID_WIDTH_G,
		AXIS_TDEST_WIDTH_G	=> AXIS_TDEST_WIDTH_G,
		AXIS_TUSER_WIDTH_G	=> AXIS_TUSER_WIDTH_G
	)
	port map(
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		
		-- AXIS slave (input) interface for signal "s''z(t)"		
		s_axis_tvalid_s2z_i	=> axis_s2z_s.tvalid,
		s_axis_tready_s2z_o	=> axis_s2z_s.tready,
		s_axis_tlast_s2z_i	=> axis_s2z_s.tlast,
		s_axis_tdata_s2z_i	=> axis_s2z_s.tdata,
		s_axis_tkeep_s2z_i	=> axis_s2z_s.tkeep,
		s_axis_tid_s2z_i	=> axis_s2z_s.tid,
		s_axis_tdest_s2z_i	=> axis_s2z_s.tdest,
		s_axis_tuser_s2z_i	=> axis_s2z_s.tuser,
		
		-- AXIS master (output) interface for signal "s^z(t)"
		m_axis_tvalid_s3z_o	=> axis_s3z_s.tvalid,
		m_axis_tready_s3z_i	=> axis_s3z_s.tready,
		m_axis_tlast_s3z_o	=> axis_s3z_s.tlast,
		m_axis_tdata_s3z_o	=> axis_s3z_s.tdata,
		m_axis_tkeep_s3z_o	=> axis_s3z_s.tkeep,
		m_axis_tid_s3z_o	=> axis_s3z_s.tid,
		m_axis_tdest_s3z_o	=> axis_s3z_s.tdest,
		m_axis_tuser_s3z_o	=> axis_s3z_s.tuser
	);

end behavioural;