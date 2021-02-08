library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- System to connect multiple cores to one master


entity bus_comp is
port(
    -- Found signal propagated through by other buses
    found_bus           : in    std_logic;
    -- Found signal passed by the belonging comparator
    found_comp          : in    std_logic;
    -- Nonce from previous bus
    nonce_bus           : in    std_logic_vector(31 downto 0);
    -- Nonce from belonging comparator
    nonce_comp          : in    std_logic_vector(31 downto 0);
    -- Hash propagated through by the other buses
    nonce_out           : out   std_logic_vector(31 downto 0);
    found_out           : out   std_logic
  );
end bus_comp;

architecture arch of bus_comp is
begin
  found_out <= found_comp or found_bus;
  -- Simplified version of our circuit plan
  nonce_out <= nonce_bus when found_comp = '0' else nonce_comp;

end architecture;
