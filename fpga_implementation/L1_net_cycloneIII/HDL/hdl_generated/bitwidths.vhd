library ieee;
  use    ieee.std_logic_1164.all;
  use    ieee.numeric_std.all;
  use  ieee.math_real.all;
package bitwidths is
  constant BITWIDTH : integer := 8;
  constant GENERAL_BITWIDTH : integer :=8;
  constant PIXEL_CONST    : integer :=8;
  constant SUM_WIDTH     : integer := 3*PIXEL_CONST;
end bitwidths;
