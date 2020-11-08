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

entity sample_representative is
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;
		valid_i		: in  std_logic;
		
		img_coord_i	: in  img_coord_t;
		data_merr_i	: in  unsigned(D_C-1 downto 0);	-- "mz(t)"	 (maximum error)
		data_quant_i: in  unsigned(D_C-1 downto 0);	-- "qz(t)"   (quantizer index)
		data_s0_i	: in  unsigned(D_C-1 downto 0);	-- "sz(t)"	 (original sample)
		data_s3_i	: in  unsigned(D_C-1 downto 0);	-- "s^z(t)"  (predicted sample)
		data_s6_i	: in  unsigned(D_C-1 downto 0);	-- "s)z(t)"	 (high-resolution predicted sample)

		data_s1_o	: out unsigned(D_C-1 downto 0);	-- "s'z(t)"  (clipped quantizer bin center)
		data_s2_o	: out unsigned(D_C-1 downto 0)	-- "s''z(t)" (sample representative)
	);
end sample_representative;

architecture behavioural of sample_representative is
	constant PROC_TIME_C : integer := 3;	-- Clock cycles used to completely process "Sample Representatives"
	
	signal valid_ar_s	 : std_logic_vector(PROC_TIME_C-1 downto 0);
	signal img_coord_ar_s: img_coord_ar_t(PROC_TIME_C-1 downto 0);
	
	signal data_s1_s	: unsigned(D_C-1 downto 0);
	signal data_s2_s	: unsigned(D_C-1 downto 0);
	signal data_s5_s	: unsigned(D_C-1 downto 0);
	
begin
	-- Input values delayed PROC_TIME_C clock cycles to synchronize them with the next modules in chain
	p_smpl_repr_delay : process(clock_i) is
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
	end process p_smpl_repr_delay;
	
	i_clip_qua_bin_cnt : clip_quant_bin_center
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		valid_i		 => valid_i,
		
		data_s3_i	 => data_s3_i,
		data_merr_i	 => data_merr_i,
		data_quant_i => data_quant_i,
		data_s1_o	 => data_s1_s
	);

	i_dbl_res_smpl_rerp : dbl_res_smpl_repr
	port map(
		clock_i		 => clock_i,
		reset_i		 => reset_i,
		valid_i		 => valid_ar_s(0),

		data_merr_i	 => data_merr_i,
		data_quant_i => data_quant_i,
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
				if (valid_ar_s(1) = '1') then
					if (img_coord_ar_s(1).t = 0) then
						data_s2_s <= data_s0_i;
					else
						data_s2_s <= to_unsigned(round_down(real(to_integer(data_s5_s)+1)/2.0), D_C);
					end if;
				end if;
			end if;
		end if;
	end process p_smpl_repr_calc;

	-- Outputs
	data_s1_o <= data_s1_s;
	data_s2_o <= data_s2_s;
end behavioural;