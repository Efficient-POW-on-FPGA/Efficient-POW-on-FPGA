library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package com_components is
  component com_controller is
    generic (
      g_clks_per_bit : integer
    );
    port (
      i_clk              : in std_logic;
      
      rx                 : in std_logic;
      tx                 : out std_logic;

      --communication bus

      o_in_header        : out std_logic_vector(639 downto 0);
      o_in_header_fin    : out std_logic;
      
      i_found            : in std_logic;
      i_found_nonce      : in std_logic_vector(31 downto 0)
    );
  end component;
end package;