--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		sample_representative
--
-- Description: Computes the sample_representative "s''z(t)"
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.types.all;
use work.param_image.all;
use work.param_predictor.all;
use work.comp_predictor.all;

entity sample_representative is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		enable_i	: in  std_logic;
		
		img_coord_i	: in  img_coord_t;
		data_merr_i	: in  signed(D_C-1 downto 0);	-- "mz(t)"	 (maximum error)
		data_quant_i: in  signed(D_C-1 downto 0);	-- "qz(t)"   (quantizer index)
		data_s0_i	: in  signed(D_C-1 downto 0);	-- "sz(t)"	 (original sample)
		data_s3_i	: in  signed(D_C-1 downto 0);	-- "s^z(t)"  (predicted sample)
		data_s6_i	: in  signed(Re_C-1 downto 0);	-- "s)z(t)"	 (high-resolution predicted sample)

		data_s1_o	: out signed(D_C-1 downto 0);	-- "s'z(t)"  (clipped quantizer bin center)
		data_s2_o	: out signed(D_C-1 downto 0)	-- "s''z(t)" (sample representative)
	);
end sample_representative;

architecture behavioural of sample_representative is
	constant PROC_TIME_C	: integer := 2;	-- Clock cycles used to completely process "Sample Representatives"
	
	signal enable_ar_s	 	: std_logic_vector(PROC_TIME_C-1 downto 0) := (others => '0');
	signal img_coord_ar_s	: img_coord_ar_t(PROC_TIME_C-1 downto 0)   := (others => reset_img_coord);
	signal data_merr_ar_s	: array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	signal data_quant_ar_s	: array_signed_t(PROC_TIME_C-1 downto 0)(D_C-1 downto 0) := (others => (others => '0'));
	
	signal data_s1_s		: signed(D_C-1 downto 0) := (others => '0');
	signal data_s2_s		: signed(D_C-1 downto 0) := (others => '0');
	signal data_s5_s		: signed(D_C-1 downto 0) := (others => '0');
	
begin
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_smpl_repr_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				enable_ar_s		<= (others => '0');
				img_coord_ar_s	<= (others => reset_img_coord);
				data_merr_ar_s	<= (others => (others => '0'));
				data_quant_ar_s	<= (others => (others => '0'));
			else
				enable_ar_s(0)	   <= enable_i;
				img_coord_ar_s(0)  <= img_coord_i;
				data_merr_ar_s(0)  <= data_merr_i;
				data_quant_ar_s(0) <= data_quant_i;
				for i in 1 to (PROC_TIME_C-1) loop
					enable_ar_s(i)	   <= enable_ar_s(i-1);
					img_coord_ar_s(i)  <= img_coord_ar_s(i-1);
					data_merr_ar_s(i)  <= data_merr_ar_s(i-1);
					data_quant_ar_s(i) <= data_quant_ar_s(i-1);
				end loop;
			end if;
		end if;
	end process p_smpl_repr_delay;
	
	i_clip_qua_bin_cnt : clip_quant_bin_center
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		enable_i	 => enable_i,
		
		data_s3_i	 => data_s3_i,
		data_merr_i	 => data_merr_i,
		data_quant_i => data_quant_i,
		data_s1_o	 => data_s1_s
	);

	i_dbl_res_smpl_rerp : dbl_res_smpl_repr
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		enable_i	 => enable_ar_s(0),

		data_merr_i	 => data_merr_ar_s(0),
		data_quant_i => data_quant_ar_s(0),
		data_s6_i	 => data_s6_i,
		data_s1_i	 => data_s1_s,
		data_s5_o	 => data_s5_s
	);

	-- Sample representative (s''z(t)) calculation
	p_smpl_repr_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s2_s <= (others => '0');
			else
				if (enable_ar_s(1) = '1') then
					if (img_coord_ar_s(1).t = 0) then
						data_s2_s <= data_s0_i;
					else
						data_s2_s <= round_down(resize((data_s5_s+"1")/"2", D_C));
					end if;
				end if;
			end if;
		end if;
	end process p_smpl_repr_calc;

	-- Outputs
	data_s1_o <= data_s1_s;
	data_s2_o <= data_s2_s;
end behavioural;