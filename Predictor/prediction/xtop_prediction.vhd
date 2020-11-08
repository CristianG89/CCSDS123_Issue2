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
use work.types.all;
use work.utils.all;
use work.param_image.all;
use work.param_predictor.all;

entity prediction is
	generic (
		LSUM_TYPE_G		: std_logic_vector(1 downto 0);	-- 00: Wide neighbour, 01: Narrow neighbour, 10: Wide column, 11: Narrow column
		PREDICT_MODE_G	: std_logic;	-- 1: Full prediction mode, 0: Reduced prediction mode
		W_INIT_TYPE_G	: std_logic		-- 1: Custom weight init, 0: Default weight init
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		valid_i		: in  std_logic;
		
		img_coord_i : in  img_coord_t;
		data_s1_i	: in  unsigned(D_C-1 downto 0);		-- "s'z(t)"	 (clipped quantizer bin center)
		data_s2_i	: in  unsigned(D_C-1 downto 0);		-- "s''z(t)" (sample representative)
		
		data_s3_o	: out unsigned(D_C-1 downto 0);		-- "s^z(t)"	 (predicted sample)
		data_s6_o	: out unsigned(D_C-1 downto 0)		-- "s)z(t)"	 (high-resolution predicted sample)
	);
end prediction;

architecture behavioural of prediction is
	constant PROC_TIME_C	 : integer := 2;	-- Clock cycles used to completely process "Prediction"
	
	signal valid_ar_s		 : std_logic_vector(PROC_TIME_C-1 downto 0);
	signal img_coord_ar_s	 : img_coord_ar_t(PROC_TIME_C-1 downto 0);

	signal data_lsum_s		 : unsigned(D_C-1 downto 0);
	signal data_pre_cldiff_s : unsigned(D_C-1 downto 0);
	signal data_s2_pos_s	 : s2_pos_t;
	signal ldiff_pos_s		 : ldiff_pos_t;
	signal ldiff_vect_s		 : array_unsigned_t(MAX_CZ_C-1 downto 0)(D_C-1 downto 0);
	
	signal data_pred_err_s	 : unsigned(D_C-1 downto 0);
	signal data_w_exp_s		 : unsigned(D_C-1 downto 0);
	signal weight_vect_s	 : array_unsigned_t(MAX_CZ_C-1 downto 0)(OMEGA_C+3-1 downto 0);

	signal data_s3_s		 : unsigned(D_C-1 downto 0);
	signal data_s4_s		 : unsigned(D_C-1 downto 0);
	signal data_s6_s		 : unsigned(D_C-1 downto 0);
	
begin
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_prediction_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_ar_s		<= (others => '0');
				img_coord_ar_s	<= (others => reset_img_coord);
			else
				valid_ar_s(0)	  <= valid_i;
				img_coord_ar_s(0) <= img_coord_i;
				for i in 1 to (PROC_TIME_C-1) loop
					valid_ar_s(i)	  <= valid_ar_s(i-1);
					img_coord_ar_s(i) <= img_coord_ar_s(i-1);
				end loop;
			end if;
		end if;
	end process p_prediction_delay;

	i_smpl_store : sample_store
	port map(
		clock_i		  => clock_i,
		reset_i		  => reset_i,
		valid_i		  => valid_ar_s(XXX),
		
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
		valid_i		  => valid_ar_s(XXX),
		
		img_coord_i	  => img_coord_ar_s(XXX),
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
		valid_i		  => valid_ar_s(XXX),
		
		img_coord_i	  => img_coord_ar_s(XXX),
		data_lsum_i	  => data_lsum_s,
		data_s2_pos_i => data_s2_pos_s,
		ldiff_pos_o	  => ldiff_pos_s
	);

	i_ldiff_vector : local_diff_vector
	generic map(
		PREDICT_MODE_G => PREDICT_MODE_G
	)
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		valid_i		 => valid_ar_s(XXX),
		
		ldiff_pos_i	 => ldiff_pos_s,
		ldiff_vect_o => ldiff_vect_s
	);
	
	i_dbl_res_pred_er : dbl_res_pred_error
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		valid_i			=> valid_ar_s(XXX),
		
		data_s1_i		=> data_s1_i,
		data_s4_i		=> data_s4_s,
		data_pred_err_o => data_pred_err_s
	);
	
	i_w_upd_scal_exp : weight_upd_scal_exp
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		valid_i		 => valid_ar_s(XXX),
		
		img_coord_i	 => img_coord_ar_s(XXX),
		data_w_exp_o => data_w_exp_s
	);
	
	i_weights_vector : weights_vector
	generic map(
		W_INIT_TYPE_G => W_INIT_TYPE_G
	)
	port map(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		valid_i			=> valid_ar_s(XXX),
		
		img_coord_i		=> img_coord_ar_s(XXX),
		data_w_exp_i	=> data_w_exp_s,
		data_pred_err_i => data_pred_err_s,
		ldiff_vect_i	=> ldiff_vect_s,
		weight_vect_o	=> weight_vect_s
	);
	
	i_pr_ctrl_ldiff : pred_central_local_diff
	port map(
		clock_i		  => clock_i,
		reset_i		  => reset_i,
		valid_i		  => valid_ar_s(XXX),
		
		weight_vect_i => weight_vect_s,
		ldiff_vect_i  => ldiff_vect_s,
		
		data_pred_cldiff_o => data_pre_cldiff_s
	);

	i_high_res_pred_smpl : high_res_pred_smpl
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		valid_i		=> valid_ar_s(XXX),

		data_pre_cldiff_i => data_pre_cldiff_s,
		data_lsum_i => data_lsum_s,
		data_s6_o	=> data_s6_s
	);

	i_dbl_res_pred_smpl : dbl_res_pred_smpl
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		valid_i		=> valid_ar_s(XXX),

		img_coord_i	=> img_coord_ar_s(XXX),
		data_s0_i	=> data_s0_s,
		data_s6_i	=> data_s6_s,
		data_s4_o	=> data_s4_s
	);

	i_pred_smpl : predicted_sample
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		valid_i		=> valid_ar_s(XXX),

		data_s4_i	=> data_s4_s,
		data_s3_o	=> data_s3_s
	);

	-- Outputs
	data_s3_o <= data_s3_s;
	data_s6_o <= data_s6_s;
end behavioural;