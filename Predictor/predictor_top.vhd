library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.comp_predictor.all;
	
entity predictor_top is
	port (
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
		-- Slave interface for signal "sz(t)"
		s_valid_s0z_i	: in  std_logic;
		s_ready_s0z_o	: out std_logic;
		s_data_s0z_i	: in  image_t;
		
		-- Master interface for signal "dz(t)"
		m_valid_dz_o	: out std_logic;
		m_ready_dz_i	: in  std_logic;
		m_data_dz_o		: out image_t
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
	
	-- When samples are unsigned integers:
	constant S_MIN_C : integer := 0;
	constant S_MAX_C : integer := 2**D_C-1;
	constant S_MID_C : integer := 2**(D_C-1);
	-- When samples are signed integers:
	-- constant S_MIN_C : integer := -2**(D_C-1);
	-- constant S_MAX_C : integer := 2**(D_C-1)-1;
	-- constant S_MID_C : integer := 0;
	
begin
	-- Adder module
	i_axis_adder : axis_adder
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		
		-- AXIS slave (input) interface for signal "sz(t)"
		s_valid_s0z_i	=> s_valid_s0z_i,
		s_ready_s0z_o	=> s_ready_s0z_o,
		s_data_s0z_i	=> s_data_s0z_i,

		-- AXIS slave (input) interface for signal "s^z(t)"
		s_valid_s3z_i	=> axis_s3z_s.tvalid,
		s_ready_s3z_o	=> axis_s3z_s.tready,
		s_data_s3z_i	=> axis_s3z_s.tdata,
		
		-- AXIS master (output) interface for signal "/\z(t)"
		m_valid_tz_o	=> axis_tz_s.tvalid,
		m_ready_tz_i	=> axis_tz_s.tready,
		m_data_tz_o		=> axis_tz_s.tdata
	);
	
	-- Quantizer module
	i_quantizer : quantizer
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		
		-- AXIS slave (input) interface for signal "/\z(t)"
		s_valid_tz_i	=> axis_tz_s.tvalid,
		s_ready_tz_o	=> axis_tz_s.tready,
		s_data_tz_i		=> axis_tz_s.tdata,

		-- AXIS slave (input) interface for signal "s^z(t)"
		s_valid_s3z_i	=> axis_s3z_s.tvalid,
		s_ready_s3z_o	=> axis_s3z_s.tready,
		s_data_s3z_i	=> axis_s3z_s.tdata,

		-- AXIS master (output) interface for signal "mz(t)"
		m_valid_mz_o	=> axis_mz_s.tvalid,
		m_ready_mz_i	=> axis_mz_s.tready,
		m_data_mz_o		=> axis_mz_s.tdata,
		
		-- AXIS master (output) interface for signal "qz(t)"
		m_valid_qz_o	=> axis_qz_s.tvalid,
		m_ready_qz_i	=> axis_qz_s.tready,
		m_data_qz_o		=> axis_qz_s.tdata
	);
	
	-- Mapper module
	i_mapper : mapper
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		
		-- AXIS slave (input) interface for signal "qz(t)"
		s_valid_qz_i	=> axis_qz_s.tvalid,
		s_ready_qz_o	=> axis_qz_s.tready,
		s_data_qz_i		=> axis_qz_s.tdata,
		
		-- AXIS slave (input) interface for signal "s^z(t)"
		s_valid_s3z_i	=> axis_s3z_s.tvalid,
		s_ready_s3z_o	=> axis_s3z_s.tready,
		s_data_s3z_i	=> axis_s3z_s.tdata,
		
		-- AXIS slave (input) interface for signal "mz(t)"		
		s_valid_mz_i	=> axis_mz_s.tvalid,
		s_ready_mz_o	=> axis_mz_s.tready,
		s_data_mz_i		=> axis_mz_s.tdata,
		
		-- AXIS master (output) interface for signal "dz(t)"
		m_valid_dz_o	=> m_valid_dz_o,
		m_ready_dz_i	=> m_ready_dz_i,
		m_data_dz_o		=> m_data_dz_o
	);

	-- Sample Representative module
	i_spl_representative : spl_representative
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		
		-- AXIS slave (input) interface for signal "qz(t)"
		s_valid_qz_i	=> axis_qz_s.tvalid,
		s_ready_qz_o	=> axis_qz_s.tready,
		s_data_qz_i		=> axis_qz_s.tdata,
		
		-- AXIS slave (input) interface for signal "s^z(t)"
		s_valid_s3z_i	=> axis_s3z_s.tvalid,
		s_ready_s3z_o	=> axis_s3z_s.tready,
		s_data_s3z_i	=> axis_s3z_s.tdata,
		
		-- AXIS slave (input) interface for signal "mz(t)"
		s_valid_mz_i	=> axis_mz_s.tvalid,
		s_ready_mz_o	=> axis_mz_s.tready,
		s_data_mz_i		=> axis_mz_s.tdata,
		
		-- AXIS master (output) interface for signal "s''z(t)"
		m_valid_s2z_o	=> axis_s2z_s.tvalid,
		m_ready_s2z_i	=> axis_s2z_s.tready,
		m_data_s2z_o	=> axis_s2z_s.tdata
	);

	-- Prediction module
	i_prediction : prediction
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		
		-- AXIS slave (input) interface for signal "s''z(t)"		
		s_valid_s2z_i	=> axis_s2z_s.tvalid,
		s_ready_s2z_o	=> axis_s2z_s.tready,
		s_data_s2z_i	=> axis_s2z_s.tdata,
		
		-- AXIS master (output) interface for signal "s^z(t)"
		m_valid_s3z_o	=> axis_s3z_s.tvalid,
		m_ready_s3z_i	=> axis_s3z_s.tready,
		m_data_s3z_o	=> axis_s3z_s.tdata
	);

end behavioural;