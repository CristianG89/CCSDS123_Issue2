--------------------------------------------------------------------------------
-- University:	NTNU Trondheim
-- Project:		CCSDS123 Issue 2
-- Engineer:	Cristian Gil Morales
-- Date:		01/11/2020
--------------------------------------------------------------------------------
-- IP name:		dbl_res_pred_smpl
--
-- Description: Double-resolution predicted sample value "s~z(t)" calculation
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

entity dbl_res_pred_smpl is
	generic (
		S_MID_G		: integer
	);
	port (
		clock_i		: in  std_logic;
		reset_i		: in  std_logic;

		valid_i		: in  std_logic;
		valid_o		: out std_logic;
		
		img_coord_i	: in  img_coord_t;
		img_coord_o	: out img_coord_t;

		data_s0_i	: in  std_logic_vector(D_C-1 downto 0);	-- "sz(t)"	(original sample)
		data_s6_i	: in  std_logic_vector(D_C-1 downto 0);	-- "s)z(t)" (high-resolution predicted sample)
		data_s4_o	: out std_logic_vector(D_C-1 downto 0)	-- "s~z(t)" (double-resolution predicted sample)
	);
end dbl_res_pred_smpl;

architecture behavioural of dbl_res_pred_smpl is
	signal valid_s		: std_logic;
	signal img_coord_s	: img_coord_t;
	signal data_s0z1_s	: std_logic_vector(D_C-1 downto 0);	-- s0_z-1(t)
	signal data_s4_s	: std_logic_vector(D_C-1 downto 0);

begin
	-- Delay of one complete spectral band to get value (z-1)
	i_fifo_s0z1 : entity work.fifo
	generic map(
		DATA_SIZE_G	=> D_C,
		FIFO_SIZE_G	=> (NX_C*NY_C-1)
	)
	port map(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		data_i		=> data_s0_i,
		valid_i		=> valid_i,
		data_o		=> data_s0z1_s	-- s0_z-1(t)
	);
	
	-- Double-resolution predicted sample (s~z(t)) calculation	
	p_dbl_res_pred_smpl_calc : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				data_s4_s <= (others => '0');
			else
				if (valid_i = '1') then
					if (img_coord_i.t = 0) then
						if (img_coord_i.z > 0 and P_C > 0) then
							data_s4_s <= 2*data_s0z1_s;
						else
							data_s4_s <= 2*S_MID_G;
						end if;
					else
						data_s4_s <= round_down(real(data_s6_i)/real(2**(OMEGA_C+1)));
					end if;
				end if;
			end if;
		end if;
	end process p_dbl_res_pred_smpl_calc;

	-- Input values delayed one clock cycle to synchronize them with the next modules in chain
	p_dbl_res_pred_smpl_delay : process(clock_i) is
	begin
		if rising_edge(clock_i) then
			if (reset_i = '1') then
				valid_s		<= '0';
				img_coord_s	<= (others => (others => 0));
			else
				valid_s		<= valid_i;
				img_coord_s	<= img_coord_i;
			end if;
		end if;
	end process p_dbl_res_pred_smpl_delay;

	-- Outputs
	valid_o		<= valid_s;
	img_coord_o	<= img_coord_s;
	data_s4_o	<= data_s4_s;
end behavioural;