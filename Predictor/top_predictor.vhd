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
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;
use work.comp_predictor.all;
	
entity top_predictor is
	generic (
		-- 00: lossless, 01: absolute error limit only, 10: relative error limit only, 11: both absolute and relative error limits
		FIDEL_CTRL_TYPE_G : std_logic_vector(1 downto 0);
		LSUM_TYPE_G		: std_logic_vector(1 downto 0);	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
		PREDICT_MODE_G	: std_logic;	-- 1: Full prediction mode, 0: Reduced prediction mode
		W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;

		enable_i		: in  std_logic;
		enable_o		: out std_logic;
		
		img_coord_i		: in  img_coord_t;
		img_coord_o		: out img_coord_t;
		
		data_s0_i		: in  signed(D_C-1 downto 0);	-- "sz(t)" (original sample)
		data_mp_quan_o	: out unsigned(D_C-1 downto 0)	-- "?z(t)" (mapped quantizer index)
	);
end top_predictor;

architecture behavioural of top_predictor is
	-- User chooses the prediction mode, unless NX_C=1, when only 'reduced prediction mode' can be used
	pure function set_predict_mode(desired_mode_in : std_logic) return std_logic is
	begin
		if (NX_C = 1) then
			return '0';		-- Reduced predicted mode
		else
			return desired_mode_in;
		end if;
	end function set_predict_mode;

	constant PREDICT_MODE_C : std_logic := set_predict_mode(PREDICT_MODE_G);
	signal pz_s, cz_s		: integer := 0;

	constant PROC_TIME_C	: integer := 14;	-- Clock cycles used to completely process "Quantizer"
	
	signal enable_ar_s		: std_logic_vector(PROC_TIME_C-1 downto 0)	:= (others => '0');
	signal img_coord_ar_s	: img_coord_ar_t(PROC_TIME_C-1 downto 0)	:= (others => reset_img_coord);
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
					pz_s <= work.utils.min_int(img_coord_i.z, P_C);
					cz_s <= work.utils.min_int(img_coord_i.z, P_C) + 3;	-- +3 means the 3 additional directional positions
				end if;
			end if;
		end if;
	end process p_min_spec_band;
	
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_predictor_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_ar_s		  <= (others => '0');
				img_coord_ar_s	  <= (others => reset_img_coord);
				data_merr_ar_s	  <= (others => (others => '0'));
				data_quant_ar_s	  <= (others => (others => '0'));
				data_s0_ar_s	  <= (others => (others => '0'));
				data_s3_ar_s	  <= (others => (others => '0'));
			else
				enable_ar_s(0)	  <= enable_i;
				img_coord_ar_s(0) <= img_coord_i;
				data_merr_ar_s(0) <= data_merr_s;
				data_quant_ar_s(0)<= data_quant_s;
				data_s0_ar_s(0)	  <= data_s0_i;
				data_s3_ar_s(0)	  <= data_s3_s;
				
				for i in 1 to (PROC_TIME_C-1) loop
					enable_ar_s(i)		<= enable_ar_s(i-1);
					img_coord_ar_s(i)	<= img_coord_ar_s(i-1);
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
		enable_i	=> enable_ar_s(0),

		img_coord_i	=> img_coord_ar_s(0),
		data_s0_i	=> data_s0_ar_s(0),
		data_s3_i	=> data_s3_s,
		data_res_o	=> data_res_s
	);
	
	i_quantizer : quantizer
	generic map(
		FIDEL_CTRL_TYPE_G => FIDEL_CTRL_TYPE_G
	)
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		enable_i	 => enable_ar_s(1),
		
		img_coord_i	 => img_coord_ar_s(1),
		data_s3_i	 => data_s3_ar_s(1),
		data_res_i	 => data_res_s,
		
		data_merr_o	 => data_merr_s,
		data_quant_o => data_quant_s
	);
	
	i_sample_repr : sample_representative
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		enable_i	 => enable_ar_s(2),
		
		img_coord_i	 => img_coord_ar_s(2),
		data_merr_i	 => data_merr_s,
		data_quant_i => data_quant_s,
		data_s0_i	 => data_s0_ar_s(2),
		data_s3_i	 => data_s3_ar_s(2),
		data_s6_i	 => data_s6_s,
		
		data_s1_o	 => data_s1_s,
		data_s2_o	 => data_s2_s		
	);
	
	i_prediction : prediction
	generic map(
		LSUM_TYPE_G		=> LSUM_TYPE_G,
		PREDICT_MODE_G	=> PREDICT_MODE_C,
		W_INIT_TYPE_G	=> W_INIT_TYPE_G
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		enable_i	=> enable_ar_s(4),
		
		img_coord_i	=> img_coord_ar_s(4),
		data_s0_i	=> data_s0_ar_s(4),
		data_s1_i	=> data_s1_s,
		data_s2_i	=> data_s2_s,
		
		data_s3_o	=> data_s3_s,
		data_s6_o	=> data_s6_s
	);
	
	i_mapper : mapper
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_ar_s(12),
		
		img_coord_i		=> img_coord_ar_s(12),
		data_s3_i		=> data_s3_s,
		data_merr_i	 	=> data_merr_ar_s(11),
		data_quant_i	=> data_quant_ar_s(11),
		data_mp_quan_o	=> data_mp_quan_s
	);
	
	-- Outputs
	enable_o		<= enable_ar_s(13);
	img_coord_o		<= img_coord_ar_s(13);
	data_mp_quan_o	<= data_mp_quan_s;

end behavioural;