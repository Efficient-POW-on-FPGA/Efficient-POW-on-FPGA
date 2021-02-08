library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator is
  port(
    clk                 : in    std_logic;
    reset               : in    std_logic;
    target              : in    std_logic_vector(31 downto 0);
    hash_value          : in    std_logic_vector(255 downto 0);
    comparator_enable   : in    std_logic;
    hash_out            : out   std_logic_vector(255 downto 0);
    hash_found          : out   std_logic := '0'
    );
end comparator;

architecture v1 of comparator is
  signal hash_value_i : std_logic_vector(255 downto 0);
begin

  -- invert byte order of hash
  INVERT_BYTE_ORDER: for i in 0 to 31 generate
    hash_value_i(8*i+7 downto 8*i) <= hash_value(255-8*i downto 255-8*i-7);
  end generate;

  hash_out <= hash_value_i;

  process(clk, reset)
  begin

    if reset='1' then
      -- reset comparator, but don't change target
      hash_found <= '0';
    end if;

    if rising_edge(clk) then

      if comparator_enable = '1' then

        if unsigned(hash_value_i) <= resize(unsigned(target(23 downto 0)), 256) sll to_integer((signed("0" & target(31 downto 24))-3) sll 3) then
          -- a hash value that is smaller than the target was found
          hash_found <= '1';
        else
          -- hash isn't small enough
          hash_found <= '0';
        end if;

      else
        -- comparator disabled
        hash_found <= '0';
      end if;

    end if;

  end process;
end v1;
