library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.bitwidths.all;
  use work.cnn_types.all;
  use work.params.all;
entity cnn_process is
generic(
  PIXEL_SIZE  : integer := PIXEL_CONST;
  IMAGE_WIDTH : integer := CONV1_IMAGE_WIDTH
);
port(
  clk      : in std_logic;
  reset_n  : in std_logic;
  enable   : in std_logic;
  select_i : in std_logic_vector(31 downto 0);
  in_data  : in std_logic_vector(3*PIXEL_SIZE-1 downto 0);
  in_dv    : in std_logic;
  in_fv    : in std_logic;
  out_data : out pixel_array(0 to pool1_OUT_SIZE - 1);
  out_dv   : out std_logic;
  out_fv   : out std_logic
  );
end entity;

architecture STRUCTURAL of cnn_process is
 -- Signals
signal data_data: pixel_array(0 to conv1_IN_SIZE-1);
signal data_dv	: std_logic;
signal data_fv	: std_logic;
signal conv1_data: pixel_array (0 to conv1_OUT_SIZE - 1);
signal conv1_dv	: std_logic;
signal conv1_fv	: std_logic;
signal stride_data : pixel_array(0 to conv1_OUT_SIZE - 1);
signal stride_data_valid, stride_fv, stride_dv : std_logic;
signal pool1_data: pixel_array (0 to pool1_OUT_SIZE - 1);
signal pool1_dv	: std_logic;
signal pool1_fv	: std_logic;

--Components
component InputLayer
generic (
  PIXEL_SIZE      : integer;
  NB_OUT_FLOWS    : integer
);
port (
  clk      : in  std_logic;
  reset_n  : in  std_logic;
  enable   : in  std_logic;
  in_data  : in  std_logic_vector(3*PIXEL_SIZE-1 downto 0);
  in_dv    : in  std_logic;
  in_fv    : in  std_logic;
  out_data : out pixel_array(0 to NB_OUT_FLOWS-1);
  out_dv   : out std_logic;
  out_fv   : out std_logic
);
end component InputLayer;

component DisplayLayer is
generic(
  PIXEL_SIZE : integer;
  NB_IN_FLOWS: integer
);
port(
  in_data  : in  pixel_array(0 to NB_IN_FLOWS-1);
  in_dv    : in  std_logic;
  in_fv    : in  std_logic;
  sel      : in  std_logic_vector(31 downto 0);
  out_data : out std_logic_vector(PIXEL_SIZE-1 downto 0);
  out_dv   : out std_logic;
  out_fv   : out std_logic
);
end component;

component ConvLayer
generic (
  PIXEL_SIZE   : integer;
  IMAGE_WIDTH  : integer;
  SUM_WIDTH    : integer;
  KERNEL_SIZE  : integer;
  NB_IN_FLOWS  : integer;
  NB_OUT_FLOWS : integer;
  KERNEL_VALUE : pixel_matrix;
  BIAS_VALUE   : pixel_array
);
port (
  clk      : in  std_logic;
  reset_n  : in  std_logic;
  enable   : in  std_logic;
  in_data  : in  pixel_array(0 to NB_IN_FLOWS - 1);
  in_dv    : in  std_logic;
  in_fv    : in  std_logic;
  out_data : out pixel_array(0 to NB_OUT_FLOWS - 1);
  out_data_valid  : out std_logic;
  out_dv   : out std_logic;
  out_fv   : out std_logic
);
end component ConvLayer;


component stride_gen is
generic(
PIXEL_SIZE  : integer;
IMAGE_WIDTH : integer;
KERNEL_SIZE : integer;
STRIDE_SIZE : integer;
NB_IN_FLOWS	: integer;
NB_OUT_FLOWS: integer
);
port(
clk             : in  std_logic;
reset_n         : in  std_logic;
enable          : in  std_logic;
in_data         : in  pixel_array(0 to NB_IN_FLOWS - 1);
in_dv           : in  std_logic;
in_fv           : in  std_logic;
out_data        : out pixel_array(0 to NB_OUT_FLOWS - 1);
out_data_valid  : out std_logic;
out_dv          : out std_logic;
out_fv          : out std_logic
);
end component;

component PoolLayer
generic 
(  PIXEL_SIZE   : integer;
  IMAGE_WIDTH  : integer;
  KERNEL_SIZE  : integer;
  NB_OUT_FLOWS : integer
);
port (  clk      : in  std_logic;
  reset_n  : in  std_logic;
  enable   : in  std_logic;
  in_data  : in  pixel_array(0 to NB_OUT_FLOWS - 1);
  in_dv    : in  std_logic;
  in_fv    : in  std_logic;
  out_data : out pixel_array(0 to NB_OUT_FLOWS - 1);
  out_dv   : out std_logic;
  out_fv   : out std_logic
);
end component PoolLayer;

 -- Instances
begin
InputLayer_i : InputLayer
generic map (
  PIXEL_SIZE      => PIXEL_SIZE,
  NB_OUT_FLOWS    => conv1_IN_SIZE
)
port map (
  clk      => clk,
  reset_n  => reset_n,
  enable   => enable,
  in_data  => in_data,
  in_dv    => in_dv,
  in_fv    => in_fv,
  out_data => data_data,
  out_dv   => data_dv,
  out_fv   => data_fv
  );

conv1: ConvLayer
generic map (
  PIXEL_SIZE   => PIXEL_SIZE,
  SUM_WIDTH    => SUM_WIDTH,
  IMAGE_WIDTH  => conv1_IMAGE_WIDTH,
  KERNEL_SIZE  => conv1_KERNEL_SIZE,
  NB_IN_FLOWS  => conv1_IN_SIZE,
  NB_OUT_FLOWS => conv1_OUT_SIZE,
  KERNEL_VALUE => conv1_KERNEL_VALUE,
  BIAS_VALUE   => conv1_BIAS_VALUE
)
port map (
  clk      => clk,
  reset_n  => reset_n,
  enable   => enable,
  in_data  => data_data,
  in_dv    => data_dv,
  in_fv    => data_fv,
  out_data => conv1_data,
  out_dv   => conv1_dv,
  out_fv   => conv1_fv
);

stride_gen1 : stride_gen
generic map (
PIXEL_SIZE  => PIXEL_SIZE,
IMAGE_WIDTH => conv1_IMAGE_WIDTH,
STRIDE_SIZE => 4,
NB_IN_FLOWS	=> conv1_OUT_SIZE,
NB_OUT_FLOWS=> conv1_OUT_SIZE
)
port(
clk             => clk,
reset_n         => reset_n,
enable          => enable,
in_data         => conv1_data,
in_dv           => conv1_dv,
in_fv           => conv1_fv,
out_data        => stride_data,
out_data_valid  => stride_data_valid,
out_dv          => stride_dv,
out_fv          => stride_fv
);

pool1 : PoolLayer
generic map (
  PIXEL_SIZE   => PIXEL_SIZE,
  IMAGE_WIDTH  => pool1_IMAGE_WIDTH,
  KERNEL_SIZE  => pool1_KERNEL_SIZE,
  NB_OUT_FLOWS => pool1_OUT_SIZE
)
port map (
  clk      => clk,
  reset_n  => reset_n,
  enable   => enable,
  in_data  => stride_data,
  in_dv    => stride_dv,
  in_fv    => stride_fv,
  out_data => out_data,
  out_dv   => out_dv,
  out_fv   => out_fv
);

--DisplayLayer_i: DisplayLayer
--  generic map(
--  PIXEL_SIZE => PIXEL_SIZE,
--  NB_IN_FLOWS => pool1_OUT_SIZE
--  )
--  port map(
--  in_data  => pool1_data,
--  in_dv    => pool1_dv,
--  in_fv    => pool1_fv,
--  sel      => select_i,
--  out_data => out_data,
--  out_dv   => out_dv,
--  out_fv   => out_fv
--);
end architecture;
