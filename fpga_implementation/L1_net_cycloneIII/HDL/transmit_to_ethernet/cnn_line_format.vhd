library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.bitwidths.all;
  use work.cnn_types.all;
  use work.params.all;
library std;
use ieee.math_real.all;

-- takes conv_layer outputs as inputs
entity cnn_line_format is
generic (
  PIXEL_SIZE      : integer := GENERAL_BITWIDTH;--8
  IMAGE_WIDTH     : integer := pool1_IMAGE_WIDTH;--222
  IMAGE_HEIGHT    : integer := pool1_IMAGE_WIDTH; --222
  NB_IN_FLOWS     : integer := pool1_OUT_SIZE--64
);
port (

  --WRITE SIDE
  clk                 : in std_logic;
  reset_n             : in std_logic;
  enable              : in std_logic;
  in_data             : in pixel_array (0 to NB_IN_FLOWS - 1);
  in_dv               : in std_logic;
  in_fv               : in std_logic;
  line_id             : in std_logic_vector(15 downto 0);

  --READ SIDE
  clk_tx			        : in std_logic;
  line_ready		      : out std_logic;
  read_req_board	    : in std_logic;
  data_out_board	    : out std_logic_vector(17 downto 0);
  --
  frame_id 		        : in std_logic_vector(15 downto 0);
  --
  line_select		      : in std_logic_vector(1 downto 0); --tx choose which line to read
  --
  empty_line		      : out std_logic;
  read_req_line	      : in std_logic;
  data_level_line	    : out std_logic_vector(15 downto 0);
  data_out_line	      : out std_logic_vector(NB_IN_FLOWS*PIXEL_SIZE-1 downto 0)
  );
end entity;



architecture rtl of  cnn_line_format is


  function to_integer1( s : std_logic ) return natural is
  begin
        if s = '1' then
        return 1;
     else
        return 0;
     end if;
  end function;

-- to keep 1 line in memory
  component gp_dcfifo
  generic (
    FIFO_DEPTH : positive;
    DATA_WIDTH : positive
  );
  port (
		aclr		   : IN STD_LOGIC;
        --- writer
		data		   : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    wrclk		   : IN STD_LOGIC ;
		wrreq		   : IN STD_LOGIC ;
    wrfull	   : OUT STD_LOGIC;
		wrempty		 : OUT std_logic ;
		wrusedw		 : OUT STD_LOGIC_VECTOR(integer(ceil(log2(real(FIFO_DEPTH))))-1 DOWNTO 0);
        --- reader
		rdclk	  	: IN STD_LOGIC ;
		rdreq	  	: IN STD_LOGIC ;
		q		      : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    rdusedw		: OUT STD_LOGIC_VECTOR(integer(ceil(log2(real(FIFO_DEPTH))))-1 DOWNTO 0);
		rdempty		: OUT STD_LOGIC
  );
  end component gp_dcfifo;

  signal aclr : std_logic;
  signal wrsel_int : std_logic;
  signal reset_fifo_line_int, wrreq_ff_int, wrfull_int, wrempty_int, rdreq_ff_line_int, rdempty_ff_line_int : std_logic_vector(1 downto 0);

  signal frame_id_int : std_logic_vector(15 downto 0);--don't use
  signal line_count_int : std_logic_vector(15 downto 0);

  type line_data_array is array(1 downto 0) of std_logic_vector( NB_IN_FLOWS*PIXEL_SIZE-1 downto 0);
  signal  fifo_line_data_in_int, fifo_line_to_tx_data_int : line_data_array;

  signal fifo_line_data_in_tmp : std_logic_vector( NB_IN_FLOWS*PIXEL_SIZE-1 downto 0);

  type level_data_array is array(1 downto 0) of std_logic_vector(integer(ceil(log2(real(IMAGE_WIDTH))))-1 DOWNTO 0);
  signal wrlvl_fifo_vgg_int, rdlvl_fifo_vgg_int : level_data_array;

  signal level_data_byte_int : std_logic_vector(integer(ceil(log2(real(NB_IN_FLOWS*IMAGE_WIDTH))))-1+2 downto 0);-- le + 3 pour arriver a 16 bits a la porc

  type DATA_FORMAT_STATE_ENUM is (steady, data, wait_end_line);
  signal DATA_FORMAT_STATE : DATA_FORMAT_STATE_ENUM;

  signal data_to_ff_board_int, data_from_ff_board_int : std_logic_vector(17 downto 0);
  signal reset_ff_board_int, wr_ff_board_int, rdreq_ff_board_int, rdempty_ff_board_int, wrfull_ff_board_int : std_logic;

  constant max_level_fifo  : std_logic_vector(7 DOWNTO 0) := x"DE";--std_logic_vector(unsigned(222,8));

begin

  aclr  <= not reset_n;

  process(in_data)
  begin
    for i in NB_IN_FLOWS-1 downto 0 loop
        fifo_line_data_in_tmp( ((i+1)*PIXEL_SIZE-1) downto i*PIXEL_SIZE) <= in_data(i);
    end loop;
  end process;

  u0_ff_data_ping : gp_dcfifo
  generic map (
  DATA_WIDTH => NB_IN_FLOWS*PIXEL_SIZE,
  FIFO_DEPTH => IMAGE_WIDTH--
  )
  port map (
  aclr    => aclr,

  wrclk   => clk,
  wrreq   => wrreq_ff_int(0),
  data    => fifo_line_data_in_int(0),
  wrfull  => wrfull_int(0),
  wrempty	=> wrempty_int(0),
  wrusedw => wrlvl_fifo_vgg_int(0),

  rdclk		=> clk_tx,
  rdreq		=> rdreq_ff_line_int(0),
  q			  => fifo_line_to_tx_data_int(0),
  rdempty	=> rdempty_ff_line_int(0),
  rdusedw => rdlvl_fifo_vgg_int(0)
  );




  u1_ff_data_pong : gp_dcfifo
  generic map (
  DATA_WIDTH => NB_IN_FLOWS*PIXEL_SIZE,
  FIFO_DEPTH => IMAGE_WIDTH-- + le numéro de la ligne + le pixel offset
  )
  port map (
  aclr    => aclr,

  wrclk   => clk,
  wrreq   => wrreq_ff_int(1),
  data    => fifo_line_data_in_int(1),
  wrfull  => wrfull_int(1),
  wrempty	=> wrempty_int(1),
  wrusedw => wrlvl_fifo_vgg_int(1),

  rdclk		=> clk_tx,
  rdreq		=> rdreq_ff_line_int(1),
  q			  => fifo_line_to_tx_data_int(1),
  rdempty	=> rdempty_ff_line_int(1),
  rdusedw => rdlvl_fifo_vgg_int(1)
  );

  --header generator state machine
  process(clk, reset_n)
  begin
  if reset_n = '0' then

  	wrsel_int			       	<= '1';
  	reset_fifo_line_int		<= (others => '1');
  	wrreq_ff_int			    <= (others => '0');
  	fifo_line_data_in_int	<= (others => (others => '0'));
  	wr_ff_board_int		  	<= '0';
  	frame_id_int			    <= (others => '0');
  	line_count_int			  <= (others => '0');
  	DATA_FORMAT_STATE		  <= steady;


  elsif rising_edge(clk) then

  	wrsel_int				      <= wrsel_int;
  	reset_fifo_line_int		<= (others => '0');
  	wrreq_ff_int			    <= (others => '0');
  	fifo_line_data_in_int	<= (others => (others => '0'));
  	wr_ff_board_int			  <= '0';
  	data_to_ff_board_int	<= (others => '0');
  	line_count_int			  <= line_count_int;
  	frame_id_int			    <= frame_id_int;

  	case DATA_FORMAT_STATE is

  	when steady =>
  		if in_dv = '0' then
  			if wrempty_int(0) = '1' then
  				wrsel_int			<= '0';
  				DATA_FORMAT_STATE	<= data;
  			elsif wrempty_int(1) = '1' then
  				wrsel_int			<= '1';
  				DATA_FORMAT_STATE	<= data;
  			else
  				wrsel_int			<= '0';
  				DATA_FORMAT_STATE	<= steady;
  			end if;
  			frame_id_int	<= frame_id;
  		else
  			wrsel_int			<= '0';
  			DATA_FORMAT_STATE	<= steady;
  		end if;
  		wrreq_ff_int	<= (others => '0');

  	when data =>
  		if in_dv = '1' then
  			wrreq_ff_int(to_integer1(wrsel_int))			      <= '1';
  			fifo_line_data_in_int(to_integer1(wrsel_int)) 	<= fifo_line_data_in_tmp;
  			line_count_int									                <= line_id;
  			DATA_FORMAT_STATE								                <= wait_end_line;
  		else
  			wrreq_ff_int(to_integer1(wrsel_int))			      <= '0';
  			fifo_line_data_in_int(to_integer1(wrsel_int)) 	<= (others => '0'); --pour montrer que cette ligne de fifo est en attente de pixels
  			line_count_int									                <= line_count_int;--(others => '0');
  			DATA_FORMAT_STATE								                <= data;
  		end if;

  	when wait_end_line =>
  		line_count_int									<= line_count_int;
  		if wrlvl_fifo_vgg_int(to_integer1(wrsel_int)) = max_level_fifo then -- = in_dv = '0' then --stop
  			wrreq_ff_int(to_integer1(wrsel_int))			<= '0';
  			fifo_line_data_in_int(to_integer1(wrsel_int)) 	<= (others => '0'); --pour montrer que cette ligne de fifo a terminÃƒÆ’Ã‚Â© d'ÃƒÆ’Ã‚Â©crire une ligne de l'image
  			wr_ff_board_int									<= '1';
  			if wrsel_int = '0' then
  				data_to_ff_board_int							<= "01" & line_count_int;
  			else
  				data_to_ff_board_int							<= "10" & line_count_int;
  			end if;
  			DATA_FORMAT_STATE								<= steady;
  		else
  			wrreq_ff_int(to_integer1(wrsel_int))			      <= in_dv;
  			fifo_line_data_in_int(to_integer1(wrsel_int)) 	<= fifo_line_data_in_tmp;
  			DATA_FORMAT_STATE								                <= wait_end_line;
  		end if;

  	when others =>

  		wrsel_int				       <= '1';
  		reset_fifo_line_int		 <= (others => '1');
  		wrreq_ff_int		    	 <= (others => '0');
  		fifo_line_data_in_int	 <= (others => (others => '0'));
  		wr_ff_board_int			   <= '0';
  		line_count_int			   <= (others => '0');
  		frame_id_int			     <= (others => '0');
  		DATA_FORMAT_STATE		   <= steady;

  	end case;
  end if;
  end process;


-- fifo board
reset_ff_board_int <= not(reset_n);
u2_ff_board : gp_dcfifo
generic map (
DATA_WIDTH => (2+16),
FIFO_DEPTH => 8-- + le numéro de la ligne + le pixel offset
)
port map (

  aclr		   => reset_ff_board_int,
  data		   => data_to_ff_board_int,
  wrclk		   => clk,
  wrreq		   => wr_ff_board_int,
  wrfull		 => wrfull_ff_board_int,

  rdclk		   => clk_tx,
  rdreq		   => rdreq_ff_board_int,
  q			     => data_from_ff_board_int,
  rdempty		 => rdempty_ff_board_int
);

--read side
empty_line <= 	rdempty_ff_line_int(0) when line_select = "01" else
				        rdempty_ff_line_int(1) when line_select = "10" else
				        '1';
rdreq_ff_line_int <= line_select when read_req_line = '1' else (others => '0');

--level_data_byte_int	<= 	std_logic_vector(unsigned(rdlvl_fifo_vgg_int(0))*NB_IN_FLOWS) when line_select = "01" else-- max is 64*222
--						            std_logic_vector(unsigned(rdlvl_fifo_vgg_int(1))*NB_IN_FLOWS) when line_select = "10" else
--						            (others => '0');

--level_data_byte_int	<= 	(others => '0');--std_logic_vector(unsigned(rdlvl_fifo_vgg_int(0))*NB_IN_FLOWS) when line_select = "01" else-- max is 64*222
--						            --std_logic_vector(unsigned(rdlvl_fifo_vgg_int(1))*NB_IN_FLOWS) when line_select = "10" else
--						            --(others => '0');
--data_level_line     <= (integer(ceil(log2(real(IMAGE_WIDTH-1)))) DOWNTO 0 => level_data_byte_int, others => '0');--level_data_byte_int(15 downto 0);
data_level_line     <= (others => '0');--level_data_byte_int;
data_out_line	      <= 	fifo_line_to_tx_data_int(0) when line_select = "01" else
					              fifo_line_to_tx_data_int(1) when line_select = "10" else
					              (others => '0');

line_ready          <= not(rdempty_ff_board_int);
rdreq_ff_board_int	<= read_req_board;
data_out_board	    <= data_from_ff_board_int;

end architecture;
