library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.utils.all;

-- Package Declaration Section
package comp_predictor is
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Predictor (top) module
	------------------------------------------------------------------------------------------------------------------------------
	component predictor_top is
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
	end component predictor_top;
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Adder module
	------------------------------------------------------------------------------------------------------------------------------
	component axis_adder is
		generic (
			AXIS_TDATA_WIDTH_G	: integer;
			AXIS_TID_WIDTH_G	: integer;
			AXIS_TDEST_WIDTH_G	: integer;
			AXIS_TUSER_WIDTH_G	: integer
		);
		port (
			clk_i				: in  std_logic;
			rst_i				: in  std_logic;
			
			-- AXIS slave (input) interface for signal sz(t)"
			s_axis_tvalid_s0z_i	: in  std_logic;
			s_axis_tready_s0z_o	: out std_logic;
			s_axis_tlast_s0z_i	: in  std_logic;
			s_axis_tdata_s0z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			s_axis_tkeep_s0z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			s_axis_tid_s0z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			s_axis_tdest_s0z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			s_axis_tuser_s0z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);

			-- AXIS slave (input) interface for signal "s^z(t)"
			s_axis_tvalid_s3z_i	: in  std_logic;
			s_axis_tready_s3z_o	: out std_logic;
			s_axis_tlast_s3z_i	: in  std_logic;
			s_axis_tdata_s3z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			s_axis_tkeep_s3z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			s_axis_tid_s3z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			s_axis_tdest_s3z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			s_axis_tuser_s3z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
			
			-- AXIS master (output) interface for signal "/\z(t)"
			m_axis_tvalid_tz_o	: out std_logic;
			m_axis_tready_tz_i	: in  std_logic;
			m_axis_tlast_tz_o	: out std_logic;
			m_axis_tdata_tz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			m_axis_tkeep_tz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			m_axis_tid_tz_o		: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			m_axis_tdest_tz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			m_axis_tuser_tz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
		);
	end component axis_adder;

	------------------------------------------------------------------------------------------------------------------------------
	-- Quantizer module
	------------------------------------------------------------------------------------------------------------------------------
	component quantizer is
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
	end component quantizer;
	
	------------------------------------------------------------------------------------------------------------------------------
	-- Mapper module
	------------------------------------------------------------------------------------------------------------------------------
	component mapper is
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
	end component mapper;

	------------------------------------------------------------------------------------------------------------------------------
	-- Sample Representative module
	------------------------------------------------------------------------------------------------------------------------------
	component spl_representative is
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
			
			-- AXIS master (output) interface for signal "s''z(t)"
			m_axis_tvalid_s2z_o	: out std_logic;
			m_axis_tready_s2z_i	: in  std_logic;
			m_axis_tlast_s2z_o	: out std_logic;
			m_axis_tdata_s2z_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			m_axis_tkeep_s2z_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			m_axis_tid_s2z_o	: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			m_axis_tdest_s2z_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			m_axis_tuser_s2z_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
		);
	end component spl_representative;

	------------------------------------------------------------------------------------------------------------------------------
	-- Prediction module (and its submodules)
	------------------------------------------------------------------------------------------------------------------------------
	component prediction is
		generic (
			AXIS_TDATA_WIDTH_G	: integer;
			AXIS_TID_WIDTH_G	: integer;
			AXIS_TDEST_WIDTH_G	: integer;
			AXIS_TUSER_WIDTH_G	: integer
		);
		port (
			clk_i				: in  std_logic;
			rst_i				: in  std_logic;
			
			-- AXIS slave (input) interface for signal "s''z(t)"
			s_axis_tvalid_s2z_i	: in  std_logic;
			s_axis_tready_s2z_o	: out std_logic;
			s_axis_tlast_s2z_i	: in  std_logic;
			s_axis_tdata_s2z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			s_axis_tkeep_s2z_i	: in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			s_axis_tid_s2z_i	: in  std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			s_axis_tdest_s2z_i	: in  std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			s_axis_tuser_s2z_i	: in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
			
			-- AXIS master (output) interface for signal "s^z(t)"
			m_axis_tvalid_s3z_o	: out std_logic;
			m_axis_tready_s3z_i	: in  std_logic;
			m_axis_tlast_s3z_o	: out std_logic;
			m_axis_tdata_s3z_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			m_axis_tkeep_s3z_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			m_axis_tid_s3z_o	: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			m_axis_tdest_s3z_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			m_axis_tuser_s3z_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
		);
	end component prediction;

	component local_sum is
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
	end component local_sum;

	component local_differences is
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
	end component local_differences;
	
	component weights is
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
			
			-- AXIS master (output) interface for "Wz(t)" (weight vector)
			m_axis_tvalid_wz_o	: out std_logic;
			m_axis_tready_wz_i	: in  std_logic;
			m_axis_tlast_wz_o	: out std_logic;
			m_axis_tdata_wz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
			m_axis_tkeep_wz_o	: out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
			m_axis_tid_wz_o		: out std_logic_vector(AXIS_TID_WIDTH_G-1 downto 0);
			m_axis_tdest_wz_o	: out std_logic_vector(AXIS_TDEST_WIDTH_G-1 downto 0);
			m_axis_tuser_wz_o	: out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0)
		);
	end component weights;

end package comp_predictor;