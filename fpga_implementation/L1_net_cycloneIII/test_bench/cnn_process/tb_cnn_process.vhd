library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work;
use work.bitwidths.all;
use work.cnn_types.all;
use work.params.all;
use STD.textio.all;
use ieee.std_logic_textio.all;


entity tb_cnn_process is
end entity;




architecture tb of tb_cnn_process is

file file_RESULTS, file_RESULTS_FP : text;

constant IM_WIDTH : integer := 224;
constant IM_HEIGHT : integer := 224;
constant COLOR_CHANNELS : integer := 3;
constant DATA_SIZE : integer := 8;

component frm_read_test_rgb is
generic( 	im_width 	: integer := 640;
			im_height	: integer := 480
			);
port(
	clk_sensor				: in std_logic;
	rst_n				: in std_logic;

	trigger				: in std_logic;
	data_out			: out std_logic_vector(31 downto 0);
	fen_out				: out std_logic;
	len_out 			: out std_logic
	);
end component;

signal clk_tb, clk_eth : std_logic := '0';
signal rst_n : std_logic := '0';

signal trigger : std_logic := '0';
signal data_out_sensor : std_logic_vector(31 downto 0);
signal fen_out, len_out, in_fv, in_dv : std_logic;

component cnn_process
generic(
  PIXEL_SIZE  : integer := GENERAL_BITWIDTH;
  IMAGE_WIDTH : integer := CONV1_IMAGE_WIDTH
);
port(
  clk      : in std_logic;
  reset_n  : in std_logic;
  enable   : in std_logic;
  --select_i : in std_logic_vector(31 downto 0);
  in_data  : in std_logic_vector(3*PIXEL_SIZE-1 downto 0);
  in_dv    : in std_logic;
  in_fv    : in std_logic;
  out_data : out pixel_array(0 to pool1_OUT_SIZE - 1);
  out_data_valid : out std_logic;
  out_dv   : out std_logic;
  out_fv   : out std_logic
);
end component;

signal in_dv_cnn_process_int, out_dv_cnn_process_int, out_fv_cnn_process_int, out_data_valid_cnn_process_int : std_logic;
signal in_data_cnn_process_int : std_logic_vector(3*DATA_SIZE - 1 downto 0);
signal out_data_cnn_process_int : pixel_array (0 to pool1_OUT_SIZE - 1);
--signal out_data_full_precision_cnn_process_int : full_precision_pixel_array(0 to pool1_OUT_SIZE-1);

signal flatten_data_int : std_logic_vector( pool1_OUT_SIZE*DATA_SIZE-1 downto 0);
-- signal flatten_data_full_precision_int : std_logic_vector( pool1_OUT_SIZE*(3*DATA_SIZE)-1 downto 0);

begin


  in_fv <= not fen_out;
  in_dv <= not len_out;
  
u0 : frm_read_test_rgb generic map( 	
	im_width 	=> IM_WIDTH,
	im_height	=> IM_HEIGHT
		)
port map(
	clk_sensor			=> clk_tb,
	rst_n				=> rst_n,
	trigger				=> trigger,
	data_out			=> data_out_sensor,
	fen_out				=> fen_out,
	len_out 			=> len_out
);


u1 : cnn_process
	generic map (
		PIXEL_SIZE  => DATA_SIZE,
		IMAGE_WIDTH => conv1_IMAGE_WIDTH
	)
	port map (
		clk      => clk_tb,
		reset_n  => rst_n,
		enable   => '1',
		in_data  => data_out_sensor(23 downto 0),
		in_dv    => in_dv,
		in_fv    => in_fv,
		out_data => out_data_cnn_process_int,
		out_data_valid  => out_data_valid_cnn_process_int,        
		out_dv          => out_dv_cnn_process_int,
		out_fv          => out_fv_cnn_process_int
  
        --test john
        --out_data_full_precision => open--out_data_full_precision_cnn_process_int
	);


clk_tb <= not clk_tb after 12.37 ns;
clk_eth <= not clk_eth after 4 ns;

  process(out_data_cnn_process_int)
  begin
    for i in pool1_OUT_SIZE-1 downto 0 loop
        flatten_data_int( ((i+1)*DATA_SIZE-1) downto i*DATA_SIZE) <= out_data_cnn_process_int(i);
        --flatten_data_full_precision_int( ((i+1)*3*DATA_SIZE-1) downto 3*i*DATA_SIZE ) <= out_data_full_precision_cnn_process_int(i);
    end loop;
  end process;
  
process(clk_tb)
variable v_OLINE, v_OLINE_FP     : line;
begin
if rising_edge(clk_tb) then
    if out_dv_cnn_process_int = '1' then
        --for i in conv1_1_OUT_SIZE-1 downto 0 
		
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(95))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(94))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(93))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(92))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(91))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(90))), right, 8);
		
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(89))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(88))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(87))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(86))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(85))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(84))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(83))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(82))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(81))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(80))), right, 8);
        
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(79))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(78))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(77))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(76))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(75))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(74))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(73))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(72))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(71))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(70))), right, 8);
		
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(69))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(68))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(67))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(66))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(65))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(64))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(63))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(62))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(61))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(60))), right, 8);
        
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(59))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(58))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(57))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(56))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(55))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(54))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(53))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(52))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(51))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(50))), right, 8);
        
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(49))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(48))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(47))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(46))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(45))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(44))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(43))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(42))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(41))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(40))), right, 8);

        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(39))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(38))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(37))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(36))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(35))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(34))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(33))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(32))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(31))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(30))), right, 8);

        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(29))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(28))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(27))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(26))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(25))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(24))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(23))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(22))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(21))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(20))), right, 8);
        
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(19))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(18))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(17))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(16))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(15))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(14))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(13))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(12))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(11))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(10))), right, 8);
        
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(9))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(8))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(7))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(6))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(5))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(4))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(3))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(2))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(1))), right, 8);
        write(  v_OLINE,to_integer(signed(out_data_cnn_process_int(0))), right, 8);
        
        
        -- write(v_OLINE, to_integer(unsigned(out_data_cnn_process_int(63)))&" "&to_integer(unsigned(flatten_data_int(55 downto 48)))&" "&to_integer(unsigned(flatten_data_int(47 downto 40)))&" "&to_integer(unsigned(flatten_data_int(39 downto 32)))&" "&to_integer(unsigned(flatten_data_int(31 downto 24)))&" "&to_integer(unsigned(flatten_data_int(23 downto 16)))&" "&to_integer(unsigned(flatten_data_int(15 downto 8)))&" "&to_integer(unsigned(flatten_data_int(7 downto 0))), right, 7);  
        --hwrite(v_OLINE_FP, flatten_data_full_precision_int);  
        
        writeline(file_RESULTS, v_OLINE);        
        --writeline(file_RESULTS_FP, v_OLINE_FP);
    end if;
end if;
end process;


process
begin
wait for 0 ns;
file_open(file_RESULTS, "C:\Users\john\Desktop\these_jon\EP3C120_PROJECTS\RGMII_MT9_C_NETPA_K33\TEST_BENCHS\netpa_airplane_0.txt", write_mode);
-- file_open(file_RESULTS_FP, "C:\Users\john\Desktop\these_jon\python_projects\temp\out_vgg_sim_full_precision.txt", write_mode);
rst_n	<= '0';
trigger <= '0';


wait for 16 ns;
rst_n	<= '1';
trigger <= '0';


wait for 16 ns;
rst_n	<= '1';
trigger <= '1';


wait for 16 ns;
rst_n	<= '1';
trigger <= '0';




wait for 10000000 ns;
file_close(file_RESULTS);
-- file_close(file_RESULTS_FP);
assert false  report "end of sim" severity failure;

end process;

end architecture;
