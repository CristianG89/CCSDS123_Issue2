--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		07/11/2020
--------------------------------------------------------------------------------
-- IP name:		prediction
--
-- Description: Computes the predicted sample "s^z(t)"
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_predictor.all;
use work.utils_predictor.all;
use work.param_image.all;
use work.param_predictor.all;
use work.comp_predictor.all;

entity prediction is
	generic (
		LSUM_TYPE_G		: std_logic_vector(1 downto 0);	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
		PREDICT_MODE_G	: std_logic;	-- 1: Full prediction mode, 0: Reduced prediction mode
		W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;
		
		img_coord_i : in  img_coord_t;
		data_s0_i	: in  signed(D_C-1 downto 0);		-- "sz(t)"   (original sample)
		data_s1_i	: in  signed(D_C-1 downto 0);		-- "s'z(t)"	 (clipped quantizer bin center)
		data_s2_i	: in  signed(D_C-1 downto 0);		-- "s''z(t)" (sample representative)
		
		data_s3_o	: out signed(D_C-1 downto 0);		-- "s^z(t)"	 (predicted sample)
		data_s6_o	: out signed(Re_C-1 downto 0)		-- "s)z(t)"	 (high-resolution predicted sample)
	);
end prediction;

architecture behavioural of prediction is
	constant PROC_TIME_C	 : integer := 8;	-- Clock cycles used to complete process "Prediction" (highest number, not needed by all of them)
	
	signal enable_ar_s		 : std_logic_vector(PROC_TIME_C-1 downto 0) := (others => '0');
	signal img_coord_ar_s	 : img_coord_ar_t(PROC_TIME_C-1 downto 0)	:= (others => reset_img_coord);
	signal data_s0_ar_s		 : array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_s1_ar_s		 : array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_s6_ar_s		 : array_signed_t(PROC_TIME_C-1 downto 0)(Re_C-1 downto 0):= (others => (others => '0'));
	signal data_lsum_ar_s	 : array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_s2_pos_ar_s	 : s2_pos_ar_t(PROC_TIME_C-1 downto 0) := (others => reset_s2_pos);
	signal ldiff_vect_ar_s	 : matrix_signed_t(PROC_TIME_C-1 downto 0)(MAX_CZ_C-1 downto 0)(D_C-1 downto 0) := (others => (others => (others => '0')));
	
	-- For whatever reason, these signed arrays cannot be used to save the output value from an IP (e.g. data_s6_o => data_s6_ar_s(0) FAIL),
	-- so independent signed signals must be used instead, and later assigned to these arrays (e.g. data_s6_o => data_s6_s PASS).

	signal data_s3_s		 : signed(D_C-1 downto 0) := (others => '0');
	signal data_s4_s		 : signed(D_C-1 downto 0) := (others => '0');
	signal data_s6_s		 : signed(Re_C-1 downto 0):= (others => '0');
	signal data_lsum_s		 : signed(D_C-1 downto 0) := (others => '0');
	signal data_s2_pos_s	 : s2_pos_t		:= reset_s2_pos;
	signal ldiff_pos_s		 : ldiff_pos_t	:= reset_ldiff_pos;
	signal data_pred_cldiff_s : signed(D_C-1 downto 0) := (others => '0');
	signal data_pred_err_s	 : signed(D_C-1 downto 0) := (others => '0');
	signal data_w_exp_s		 : signed(D_C-1 downto 0) := (others => '0');
	signal ldiff_vect_s		 : array_signed_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0)		 := (others => (others => '0'));
	signal weight_vect_s	 : array_signed_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0) := (others => (others => '0'));

begin
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_prediction_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_ar_s			<= (others => '0');
				img_coord_ar_s		<= (others => reset_img_coord);
				data_s0_ar_s		<= (others => (others => '0'));
				data_s1_ar_s		<= (others => (others => '0'));
				data_s6_ar_s		<= (others => (others => '0'));
				data_lsum_ar_s		<= (others => (others => '0'));
				data_s2_pos_ar_s	<= (others => reset_s2_pos);
				ldiff_vect_ar_s		<= (others => (others => (others => '0')));
			else
				enable_ar_s(0)		<= enable_i;
				img_coord_ar_s(0)	<= img_coord_i;
				data_s0_ar_s(0)		<= data_s0_i;
				data_s1_ar_s(0)		<= data_s1_i;
				data_s6_ar_s(0)		<= data_s6_s;
				data_lsum_ar_s(0)	<= data_lsum_s;
				data_s2_pos_ar_s(0)	<= data_s2_pos_s;
				ldiff_vect_ar_s(0)	<= ldiff_vect_s;

				for i in 1 to (PROC_TIME_C-1) loop
					enable_ar_s(i)		<= enable_ar_s(i-1);
					img_coord_ar_s(i)	<= img_coord_ar_s(i-1);
					data_s0_ar_s(i)		<= data_s0_ar_s(i-1);
					data_s1_ar_s(i)		<= data_s1_ar_s(i-1);
					data_s6_ar_s(i)		<= data_s6_ar_s(i-1);
					data_lsum_ar_s(i)	<= data_lsum_ar_s(i-1);
					data_s2_pos_ar_s(i)	<= data_s2_pos_ar_s(i-1);
					ldiff_vect_ar_s(i)	<= ldiff_vect_ar_s(i-1);
				end loop;
			end if;
		end if;
	end process p_prediction_delay;

	i_smpl_store : sample_store
	port map(
		clock_i		  => clock_i,
		reset_i		  => reset_i,
		enable_i	  => enable_i,
		
		data_s2_i	  => data_s2_i,
		data_s2_pos_o => data_s2_pos_s
	);
	
	i_local_sum : local_sum
	generic map(
		LSUM_TYPE_G	  => LSUM_TYPE_G
	)
	port map(
		clock_i		  => clock_i,
		reset_i		  => reset_i,
		enable_i	  => enable_ar_s(0),
		
		img_coord_i	  => img_coord_ar_s(0),
		data_s2_pos_i => data_s2_pos_s,
		data_lsum_o	  => data_lsum_s
	);
	
	i_local_diff : local_diff
	generic map(
		PREDICT_MODE_G => PREDICT_MODE_G
	)
	port map(
		clock_i		  => clock_i,
		reset_i		  => reset_i,
		enable_i	  => enable_ar_s(1),
		
		img_coord_i	  => img_coord_ar_s(1),
		data_lsum_i	  => data_lsum_s,
		data_s2_pos_i => data_s2_pos_ar_s(0),
		ldiff_pos_o	  => ldiff_pos_s
	);

	i_ldiff_vector : local_diff_vector
	generic map(
		PREDICT_MODE_G	=> PREDICT_MODE_G
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_ar_s(2),
		
		ldiff_pos_i		=> ldiff_pos_s,
		ldiff_vect_o	=> ldiff_vect_s
	);
	
	i_dbl_res_pred_er : dbl_res_pred_error
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_ar_s(2),
		
		data_s1_i		=> data_s1_ar_s(2),
		data_s4_i		=> data_s4_s,
		data_pred_err_o => data_pred_err_s
	);
	
	i_w_upd_scal_exp : weight_upd_scal_exp
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_ar_s(2),
		
		img_coord_i		=> img_coord_ar_s(2),
		data_w_exp_o	=> data_w_exp_s
	);
	
	i_weights_vector : weights_vector
	generic map(
		W_INIT_TYPE_G	=> W_INIT_TYPE_G
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_ar_s(3),
		
		img_coord_i		=> img_coord_ar_s(3),
		data_w_exp_i	=> data_w_exp_s,
		data_pred_err_i => data_pred_err_s,
		ldiff_vect_i	=> ldiff_vect_s,
		weight_vect_o	=> weight_vect_s
	);
	
	i_pr_ctrl_ldiff : pred_central_local_diff
	generic map(
		PREDICT_MODE_G	=> PREDICT_MODE_G
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		enable_i		=> enable_ar_s(4),
		
		img_coord_i		=> img_coord_ar_s(4),
		weight_vect_i	=> weight_vect_s,
		ldiff_vect_i	=> ldiff_vect_ar_s(0),
		
		data_pred_cldiff_o => data_pred_cldiff_s
	);

	i_high_res_pred_smpl : high_res_pred_smpl
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		enable_i	=> enable_ar_s(5),

		data_pred_cldiff_i => data_pred_cldiff_s,
		data_lsum_i => data_lsum_ar_s(3),
		data_s6_o	=> data_s6_s
	);

	i_dbl_res_pred_smpl : dbl_res_pred_smpl
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		enable_i	=> enable_ar_s(6),

		img_coord_i	=> img_coord_ar_s(6),
		data_s0_i	=> data_s0_ar_s(6),
		data_s6_i	=> data_s6_s,
		data_s4_o	=> data_s4_s
	);

	i_pred_smpl : predicted_sample
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		enable_i	=> enable_ar_s(7),

		data_s4_i	=> data_s4_s,
		data_s3_o	=> data_s3_s
	);

	-- Outputs
	data_s3_o <= data_s3_s;
	data_s6_o <= data_s6_ar_s(1);
end behavioural;