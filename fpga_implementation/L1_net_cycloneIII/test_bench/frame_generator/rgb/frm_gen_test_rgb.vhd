library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Use Ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;




entity frm_gen_test_rgb is
generic( 	im_width 	: integer := 240;--give 639
			im_height	: integer := 240--give 511
			);
port(
	clk_e2v				: in std_logic;
	rst_n				: in std_logic;

	trigger				: in std_logic;
	data_out			: out std_logic_vector(31 downto 0);
	fen_out				: out std_logic;
	len_out 			: out std_logic
	);
end entity;





architecture rtl of frm_gen_test_rgb is


signal cnt_int : unsigned(31 downto 0) := (others => '0');

type frm_gen_state_s is (idle,fen_state, len_state, wait_state, wait_state_2);
signal frm_gen_state : frm_gen_state_s;

constant len_interval : integer := 1360;

begin

data_out	<= std_logic_vector(cnt_int);

process(clk_e2v, rst_n)
variable tempo_int : integer;
variable i : integer range 0 to 2048;--p
variable j : integer range 0 to 2048;--l
begin
if rst_n = '0' then
	cnt_int	<= (others => '0');
	tempo_int	:= 0;
	i:= 0;
	j:= 0;
	fen_out <= '1';
	len_out <= '1';
	frm_gen_state	<= idle;
elsif rising_edge(clk_e2v) then
	case frm_gen_state is

	when idle =>
		if trigger = '1' then
			frm_gen_state	<= fen_state;
		else
			frm_gen_state	<= idle;
		end if;
		cnt_int	<= (others => '0');
		tempo_int	:= 0;
		i:= 0;
		j:= 0;
		fen_out <= '1';
		len_out <= '1';

	when fen_state =>
		if tempo_int < len_interval then
			fen_out	<= '1';
			tempo_int := tempo_int + 1;
			frm_gen_state	<= fen_state;
		else
			fen_out	<= '0';
			tempo_int:= 0;
			frm_gen_state	<= len_state;
		end if;
		cnt_int	<= (others => '0');
		i:= 0;
		j:= 0;
		len_out <= '1';

	when len_state =>
		if i < 2 then --pixel
			len_out	<= '1';
			i := i + 1;
			cnt_int	<= cnt_int;
			frm_gen_state	<= len_state;
		elsif (i > 1 and i < im_width+2) then
			len_out	<= '0';
			i := i + 1;
			cnt_int	<= cnt_int + 1;
			frm_gen_state	<= len_state;
		else
			len_out	<= '1';
			i := 0;
			cnt_int	<= cnt_int;
			frm_gen_state	<= wait_state;
		end if;

	when wait_state =>
		if tempo_int < len_interval then
			fen_out <= '0';
			tempo_int	:= tempo_int + 1;
		else
			tempo_int	:= 0;
			if j = im_height - 1 then --ligne
				fen_out <= '1';
				j:= 0;
				frm_gen_state	<= wait_state_2;
			else
				fen_out <= '0';
				j:= j + 1;
				frm_gen_state	<= len_state;
			end if;
			cnt_int	<= cnt_int;
			len_out <= '1';
		end if;


	when wait_state_2 =>
		if tempo_int < 512 then
			tempo_int	:= tempo_int + 1;
			frm_gen_state	<= wait_state_2;
		else
			tempo_int		:= 0;
			frm_gen_state	<= fen_state;
		end if;

		cnt_int	<= (others => '0');
		i:= 0;
		j:= 0;
		fen_out <= '1';
		len_out <= '1';
		frm_gen_state	<= fen_state;




	when others =>
		cnt_int	<= (others => '0');
		tempo_int		:= 0;
		i:= 0;
		j:= 0;
		fen_out <= '1';
		len_out <= '1';
		frm_gen_state	<= idle;


	end case;
end if;

end process;



end architecture;
