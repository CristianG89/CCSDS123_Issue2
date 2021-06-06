--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		07/11/2020
--------------------------------------------------------------------------------
-- IP name:		top_predictor
--
-- Description: Top entity for the "predictor" module
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.param_image.all;
use work.types_image.all;
use work.utils_image.all;

use work.param_predictor.all;
use work.types_predictor.all;
use work.utils_predictor.all;
use work.comp_predictor.all;
	
entity top_predictor is
	generic (
		-- 00: BSQ order, 01: BIP order, 10: BIL order
		SMPL_ORDER_G		: std_logic_vector(1 downto 0);
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G	: std_logic_vector(1 downto 0);
		-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
		LSUM_TYPE_G			: std_logic_vector(1 downto 0);
		-- 1: Full prediction mode, 0: Reduced prediction mode
		PREDICT_MODE_G		: std_logic;
		-- 1: band-dependent, 0: band-independent (for both absolute and relative error limit assignments)
		ABS_ERR_BAND_TYPE_G	: std_logic;
		REL_ERR_BAND_TYPE_G	: std_logic;
		-- 1: enabled, 0: disabled
		PER_ERR_LIM_UPD_G	: std_logic;
		-- 1: Custom weight init, 0: Default weight init
		W_INIT_TYPE_G		: std_logic
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		enable_i		: in  std_logic;
		enable_o		: out std_logic;
		img_coord_i		: in  img_coord_t;
		img_coord_o		: out img_coord_t;
		err_lim_i		: in  err_lim_t;
		err_lim_o		: out err_lim_t;
		
		data_s0_i		: in  signed(D_C-1 downto 0);	-- "sz(t)" (original sample)
		data_mp_quan_o	: out unsigned(D_C-1 downto 0)	-- "?z(t)" (mapped quantizer index)
	);
end top_predictor;

architecture behavioural of top_predictor is
	------------------------------------------------------------------------------------------------------
	-- CONSTANTS FROM ALGORITHM ITSELF
	------------------------------------------------------------------------------------------------------
	constant S_MIN_SGN_C  : integer := -2**(D_C-1);			-- S_MIN_C when working with signed samples
	constant S_MID_SGN_C  : integer := 0;					-- S_MID_C when working with signed samples
	constant S_MAX_SGN_C  : integer := 2**(D_C-1)-1;		-- S_MAX_C when working with signed samples
	
	constant S_MIN_USGN_C : integer := 0;					-- S_MIN_C when working with unsigned samples
	constant S_MID_USGN_C : integer := 2**(D_C-1);			-- S_MID_C when working with unsigned samples
	constant S_MAX_USGN_C : integer := 2**D_C-1;			-- S_MAX_C when working with unsigned samples
	
	------------------------------------------------------------------------------------------------------
	-- FUNCTIONS
	------------------------------------------------------------------------------------------------------
	-- To define the sample limit values (0 = samples unsigned type, 1 = samples signed type)
	pure function set_smpl_limits(smpl_type_in : std_logic) return smpl_lim_t is
		variable smpl_lim_v : smpl_lim_t;
	begin
		if (smpl_type_in = '1') then
			smpl_lim_v.min := S_MIN_SGN_C;
			smpl_lim_v.mid := S_MID_SGN_C;
			smpl_lim_v.max := S_MAX_SGN_C;
		else
			smpl_lim_v.min := S_MIN_USGN_C;
			smpl_lim_v.mid := S_MID_USGN_C;
			smpl_lim_v.max := S_MAX_USGN_C;
		end if;
		
		return smpl_lim_v;
	end function set_smpl_limits;
	
	------------------------------------------------------------------------------------------------------
	-- DESIGN CONSTANTS
	------------------------------------------------------------------------------------------------------
	constant SMPL_LIMIT_C	: smpl_lim_t := set_smpl_limits(SAMPLE_TYPE_C);
	
	constant PROC_TIME_C	: integer := 14;	-- Clock cycles used to complete the whole "Predictor" block

	-- Number of bands and number of local differences values for prediction
	signal pz_s, cz_s		: integer := 0;

	-- Enable and image coordinates to interconnect all sub-blocks
	signal enable1_s		: std_logic := '0';
	signal enable2_s		: std_logic := '0';
	signal enable3_s		: std_logic := '0';
	signal enable4_s		: std_logic := '0';
	signal enable5_s		: std_logic := '0';
	signal img_coord1_s		: img_coord_t := reset_img_coord;
	signal img_coord2_s		: img_coord_t := reset_img_coord;
	signal img_coord3_s		: img_coord_t := reset_img_coord;
	signal img_coord4_s		: img_coord_t := reset_img_coord;
	signal img_coord5_s		: img_coord_t := reset_img_coord;
	
	signal err_lim_in_s		: err_lim_t	  := reset_err_lim;
	signal err_lim_out_s	: err_lim_t	  := reset_err_lim;
	signal err_lim_ar_s		: err_lim_ar_t(PROC_TIME_C-1 downto 0) := (others => reset_err_lim);
	
	signal data_merr_ar_s	: array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_quant_ar_s	: array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_s0_ar_s		: array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_s3_ar_s		: array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	
	-- For whatever reason, these signed arrays cannot be used to save the output value from an IP (e.g. data_quant_o => data_quant_ar_s(0) FAIL),
	-- so independent signed signals must be used instead, and later assigned to these arrays (e.g. data_quant_o => data_quant_s PASS).

	signal data_merr_s		: signed(D_C-1 downto 0)	:= (others => '0');
	signal data_quant_s		: signed(D_C-1 downto 0)	:= (others => '0');
	signal data_res_s		: signed(D_C-1 downto 0)	:= (others => '0');
	signal data_mp_quan_s	: unsigned(D_C-1 downto 0)	:= (others => '0');
	
	signal data_s1_s		: signed(D_C-1 downto 0)	:= (others => '0');
	signal data_s2_s		: signed(D_C-1 downto 0)	:= (others => '0');
	signal data_s3_s		: signed(D_C-1 downto 0)	:= (others => '0');
	signal data_s6_s		: signed(Re_C-1 downto 0)	:= (others => '0');
	
begin
	p_min_spec_band : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				pz_s <= 0;
				cz_s <= 0;
			else
				-- If coord. "t" gets minimum number, it means the image is in a new spectral band
				if (img_coord_i.t = 0) then
					pz_s <= work.utils_image.min(img_coord_i.z, P_C);
					cz_s <= work.utils_image.min(img_coord_i.z, P_C) + 3;	-- +3 means the 3 additional directional positions
				end if;
			end if;
		end if;
	end process p_min_spec_band;
	
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_predictor_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				err_lim_in_s	  <= reset_err_lim;
				err_lim_ar_s	  <= (others => reset_err_lim);
				data_merr_ar_s	  <= (others => (others => '0'));
				data_quant_ar_s	  <= (others => (others => '0'));
				data_s0_ar_s	  <= (others => (others => '0'));
				data_s3_ar_s	  <= (others => (others => '0'));
			else
				err_lim_in_s	  <= err_lim_i;
				err_lim_ar_s(0)	  <= err_lim_out_s;
				data_merr_ar_s(0) <= data_merr_s;
				data_quant_ar_s(0)<= data_quant_s;
				data_s0_ar_s(0)	  <= data_s0_i;
				data_s3_ar_s(0)	  <= data_s3_s;
				
				for i in 1 to (PROC_TIME_C-1) loop
					err_lim_ar_s(i)		<= err_lim_ar_s(i-1);
					data_merr_ar_s(i)	<= data_merr_ar_s(i-1);
					data_quant_ar_s(i)	<= data_quant_ar_s(i-1);
					data_s0_ar_s(i)		<= data_s0_ar_s(i-1);
					data_s3_ar_s(i)		<= data_s3_ar_s(i-1);
				end loop;
			end if;
		end if;
	end process p_predictor_delay;
	
	i_adder : adder
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		
		enable_i	=> enable_i,
		enable_o	=> enable1_s,
		img_coord_i	=> img_coord_i,
		img_coord_o	=> img_coord1_s,
		
		data_s0_i	=> data_s0_i,
		data_s3_i	=> data_s3_s,
		data_res_o	=> data_res_s
	);
	
	i_quantizer : quantizer
	generic map(
		SMPL_ORDER_G		=> SMPL_ORDER_G,
		FIDEL_CTRL_TYPE_G	=> FIDEL_CTRL_TYPE_G,
		ABS_ERR_BAND_TYPE_G	=> ABS_ERR_BAND_TYPE_G,
		REL_ERR_BAND_TYPE_G	=> REL_ERR_BAND_TYPE_G
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		
		enable_i	=> enable1_s,
		enable_o	=> enable2_s,
		img_coord_i	=> img_coord1_s,
		img_coord_o	=> img_coord2_s,
		err_lim_i	=> err_lim_in_s,
		err_lim_o	=> err_lim_out_s,
		
		data_s3_i	=> data_s3_ar_s(0),
		data_res_i	=> data_res_s,
		
		data_merr_o	=> data_merr_s,
		data_quant_o=> data_quant_s
	);
	
	i_sample_repr : sample_representative
	generic map(
		SMPL_LIMIT_G => SMPL_LIMIT_C
	)
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		
		enable_i	 => enable2_s,
		enable_o	 => enable3_s,
		img_coord_i	 => img_coord2_s,
		img_coord_o	 => img_coord3_s,
		
		data_merr_i	 => data_merr_s,
		data_quant_i => data_quant_s,
		data_s0_i	 => data_s0_ar_s(2),
		data_s3_i	 => data_s3_s,
		data_s6_i	 => data_s6_s,
		
		data_s1_o	 => data_s1_s,
		data_s2_o	 => data_s2_s		
	);
	
	i_prediction : prediction
	generic map(
		SMPL_LIMIT_G	=> SMPL_LIMIT_C,
		SMPL_ORDER_G	=> SMPL_ORDER_G,
		LSUM_TYPE_G		=> LSUM_TYPE_G,
		PREDICT_MODE_G	=> PREDICT_MODE_G,
		W_INIT_TYPE_G	=> W_INIT_TYPE_G
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		
		enable_i	=> enable3_s,
		enable_o	=> enable4_s,
		img_coord_i	=> img_coord3_s,
		img_coord_o	=> img_coord4_s,
		
		data_s0_i	=> data_s0_ar_s(4),
		data_s1_i	=> data_s1_s,
		data_s2_i	=> data_s2_s,
		
		data_s3_o	=> data_s3_s,
		data_s6_o	=> data_s6_s
	);
	
	i_mapper : mapper
	generic map(
		SMPL_LIMIT_G	=> SMPL_LIMIT_C
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		
		enable_i		=> enable4_s,
		enable_o		=> enable5_s,
		img_coord_i		=> img_coord4_s,
		img_coord_o		=> img_coord5_s,
		
		data_s3_i		=> data_s3_s,
		data_merr_i	 	=> data_merr_ar_s(11),
		data_quant_i	=> data_quant_ar_s(11),
		data_mp_quan_o	=> data_mp_quan_s
	);
	
	-- Outputs
	enable_o		<= enable5_s;
	img_coord_o		<= img_coord5_s;
	err_lim_o		<= err_lim_ar_s(2);
	data_mp_quan_o	<= data_mp_quan_s;
end behavioural;