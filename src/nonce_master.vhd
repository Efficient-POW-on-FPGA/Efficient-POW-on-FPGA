library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nonce_master is
port(
    clk                 : in    std_logic;
    -- We only need the end of the header, as this is where the threshold is encoded
    header_in           : in    std_logic_vector(31 downto 0);
    header_enable       : in    std_logic;
    reset               : out   std_logic;
    threshold_out       : out   std_logic_vector(31 downto 0);
    mining_enable       : out   std_logic
  );
end nonce_master;

architecture arch of nonce_master is

  signal mining_enable_internal     : std_logic := '0';

begin

  reset <= header_enable;
  mining_enable <= mining_enable_internal;
  -- Difficulty is simply last 4 bytes of header without the nonce appended
  -- (Reverse endianness for the comparator)
  threshold_out(31 downto 24) <= header_in(7 downto 0);
  threshold_out(23 downto 16) <= header_in(15 downto 8);
  threshold_out(15 downto 8) <= header_in(23 downto 16);
  threshold_out(7 downto 0) <= header_in(31 downto 24);

  process(clk)
  begin

    if(rising_edge(clk)) then
      if(header_enable = '1') then
        mining_enable_internal <= '1';
      end if;


      if(mining_enable_internal = '1') then
        mining_enable_internal <= '0';
      end if;
    end if;

  end process;

end architecture;
