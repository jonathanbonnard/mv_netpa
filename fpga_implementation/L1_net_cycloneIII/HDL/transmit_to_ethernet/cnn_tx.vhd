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
entity cnn_tx is
generic (
  PIXEL_SIZE      : integer := GENERAL_BITWIDTH;--8
  IMAGE_WIDTH     : integer := pool1_IMAGE_WIDTH;--57
  IMAGE_HEIGHT    : integer := pool1_IMAGE_WIDTH; --57
  NB_IN_FLOWS     : integer := pool1_OUT_SIZE--48 pour alexnet  
);
port (
  clk_proc                 : in std_logic;
  reset_n             : in std_logic;
  enable              : in std_logic;
  in_data             : in pixel_array(0 to NB_IN_FLOWS - 1);
  in_dv               : in std_logic;
  in_fv               : in std_logic;
  line_id             : in std_logic_vector(15 downto 0);

  clk_eth             : in std_logic;
  cnn_to_tx_size	    : out std_logic_vector(15 downto 0);
    cnn_to_tx_request	  : out std_logic;
	cnn_to_tx_granted	  : in std_logic;
	cnn_to_tx_valid	    : out std_logic;
	cnn_to_tx_eof		    : out std_logic;
	cnn_to_tx_data	    : out std_logic_vector(7 downto 0)

);
end entity;



architecture rtl of cnn_tx is

  component cnn_line_format
  generic (
    PIXEL_SIZE   : integer := GENERAL_BITWIDTH;
    IMAGE_WIDTH  : integer := pool1_IMAGE_WIDTH;
    IMAGE_HEIGHT : integer := pool1_IMAGE_WIDTH;
    NB_IN_FLOWS  : integer := pool1_OUT_SIZE
  );
  port (
    clk             : in  std_logic;
    reset_n         : in  std_logic;
    enable          : in  std_logic;
    in_data         : in  pixel_array (0 to NB_IN_FLOWS - 1);
    in_dv           : in  std_logic;
    in_fv           : in  std_logic;
    line_id         : in  std_logic_vector(15 downto 0);
    clk_tx          : in  std_logic;
    line_ready      : out std_logic;
    read_req_board  : in  std_logic;
    data_out_board  : out std_logic_vector(17 downto 0);
    frame_id        : in  std_logic_vector(15 downto 0);--no use
    line_select     : in  std_logic_vector(1 downto 0);
    empty_line      : out std_logic;
    read_req_line   : in  std_logic;
    data_level_line : out std_logic_vector(15 downto 0);
    data_out_line   : out std_logic_vector(NB_IN_FLOWS*PIXEL_SIZE-1 downto 0)
  );
  end component cnn_line_format;

  signal line_ready_cnn_line_format_int, read_req_board_cnn_line_format_int, empty_line_cnn_line_format_int  : std_logic;
  signal data_out_board_cnn_line_format_int : std_logic_vector(17 downto 0);
  signal data_level_line_cnn_line_format_int : std_logic_vector(15 downto 0);
  signal line_select_cnn_line_format_int : std_logic_vector(1 downto 0);
  signal data_out_line_cnn_line_format_int : std_logic_vector(NB_IN_FLOWS*GENERAL_BITWIDTH-1 downto 0);

  component cnn_line_tx
  generic (
    PIXEL_SIZE   : integer := GENERAL_BITWIDTH; 
    IMAGE_WIDTH  : integer := pool1_IMAGE_WIDTH;
    IMAGE_HEIGHT : integer := pool1_IMAGE_WIDTH;
    NB_IN_FLOWS  : integer := pool1_OUT_SIZE
  );
  port (
    clk                 : in  std_logic;
    rst_n               : in  std_logic;
    line_ready          : in  std_logic;
    read_req_board      : out std_logic;
    data_board          : in  std_logic_vector(17 downto 0);
    line_select         : out std_logic_vector(1 downto 0);
    empty_line          : in  std_logic;
    read_line           : out std_logic;
    data_level_line     : in  std_logic_vector(15 downto 0);
    data_out_line       : in  std_logic_vector(NB_IN_FLOWS*PIXEL_SIZE-1 downto 0);
    frame_to_tx_size    : out std_logic_vector(15 downto 0);
    frame_to_tx_request : out std_logic;
    frame_to_tx_granted : in  std_logic;
    frame_to_tx_valid   : out std_logic;
    frame_to_tx_eof     : out std_logic;
    frame_to_tx_data    : out std_logic_vector(7 downto 0)
  );
  end component cnn_line_tx;

  signal read_line_cnn_line_tx_int, frame_to_tx_request_cnn_line_tx_int, frame_to_tx_granted_cnn_line_tx_int, frame_to_tx_valid_cnn_line_tx_int, frame_to_tx_eof_cnn_line_tx_int : std_logic;
  signal frame_to_tx_size_cnn_line_tx_int : std_logic_vector(15 downto 0);
  signal frame_to_tx_data_cnn_line_tx_int : std_logic_vector(7 downto 0);
  
  
begin 
u0 : cnn_line_format
generic map (
  PIXEL_SIZE   => PIXEL_SIZE,
  IMAGE_WIDTH  => IMAGE_WIDTH,
  IMAGE_HEIGHT => IMAGE_HEIGHT,
  NB_IN_FLOWS  => NB_IN_FLOWS
)
port map (
  clk             => clk_proc,
  reset_n         => reset_n,
  enable          => '1',
  in_data         => in_data,
  in_dv           => in_dv,
  in_fv           => in_fv,
  line_id         => line_id,
  clk_tx          => clk_eth,
  line_ready      => line_ready_cnn_line_format_int,
  read_req_board  => read_req_board_cnn_line_format_int,
  data_out_board  => data_out_board_cnn_line_format_int,
  frame_id        => (others => '0'),
  line_select     => line_select_cnn_line_format_int,
  empty_line      => empty_line_cnn_line_format_int,
  read_req_line   => read_line_cnn_line_tx_int,
  data_level_line => data_level_line_cnn_line_format_int,
  data_out_line   => data_out_line_cnn_line_format_int
);

u1 : cnn_line_tx
generic map (
  PIXEL_SIZE   => PIXEL_SIZE,
  IMAGE_WIDTH  => IMAGE_WIDTH,
  IMAGE_HEIGHT => IMAGE_WIDTH,
  NB_IN_FLOWS  => NB_IN_FLOWS
)
port map (
  clk                 => clk_eth,
  rst_n               => reset_n,
  line_ready          => line_ready_cnn_line_format_int,
  read_req_board      => read_req_board_cnn_line_format_int,
  data_board          => data_out_board_cnn_line_format_int,
  line_select         => line_select_cnn_line_format_int,
  empty_line          => empty_line_cnn_line_format_int,
  read_line           => read_line_cnn_line_tx_int,
  data_level_line     => data_level_line_cnn_line_format_int,
  data_out_line       => data_out_line_cnn_line_format_int,
  frame_to_tx_size    => cnn_to_tx_size,
  frame_to_tx_request => cnn_to_tx_request,
  frame_to_tx_granted => cnn_to_tx_granted,
  frame_to_tx_valid   => cnn_to_tx_valid,
  frame_to_tx_eof     => cnn_to_tx_eof,
  frame_to_tx_data    => cnn_to_tx_data
);



end architecture;