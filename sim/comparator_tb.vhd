library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator_tb is
end entity;

architecture v1 of comparator_tb is
  component comparator
    port(
      clk                 : in    std_logic;
      reset               : in    std_logic;
      target              : in    std_logic_vector(31 downto 0);
      hash_value          : in    std_logic_vector(255 downto 0);
      comparator_enable   : in    std_logic;
      hash_out            : out   std_logic_vector(255 downto 0);
      hash_found          : out   std_logic
      );
  end component;

  signal clk, reset, comparator_enable, hash_found : std_logic;
  signal target : std_logic_vector(31 downto 0);
  signal hash_value, hash_out : std_logic_vector(255 downto 0);
  signal i : integer := 0; -- number of clock cycles

begin

  comparator_comp: comparator port map(clk => clk, reset => reset, target => target, hash_value => hash_value, comparator_enable => comparator_enable, hash_out => hash_out, hash_found => hash_found);

  -- simulate clock
  process
  begin

    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    i <= i + 1;

    if i = 23 then
      report "##### All tests of comparator_tb were successful! #####" severity note;
      wait;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      
      if i = 4 then
        -- reset comparator, initialize values
        reset <= '1';
        comparator_enable <= '0';
      end if;

      if i = 5 then
        reset <= '0';
      end if;

      if i = 6 then
        -- define target value
        target <= x"01003456"; -- equal to 0

        -- send first hash value (0)
        comparator_enable <= '1';
        hash_value <= (others => '0');
      end if;

      if i = 8 then
        -- hash with value 0 should be sent by comparator
        assert hash_found = '1' report "comparator was expected to find a hash value, but didn't" severity failure;
        assert to_integer(unsigned(hash_out)) = 0 report "comparator was expected to return 0, but returned " & integer'image(to_integer(unsigned(hash_out))) severity failure;
      end if;

      if i = 9 then
        -- send next hash value (1)
        comparator_enable <= '1';
        hash_value <= (248 => '1', others => '0');
      end if;

      if (i = 11) then
        assert hash_found = '0' report "a hash value was returned although greater than target 0" severity failure;
      end if;

      if i = 12 then
        -- change target value
        target <= x"01123456";
      end if;

      if (i=14) then
        assert hash_found = '1' report "comparator was expected to find a hash value, but didn't" severity failure;
      end if;

      if i= 15 then
        target <= x"1d00ffff";
        hash_value <= x"0000000000000000000000000000000000000000000000000000FFFF00000000";
      end if;

      if i = 17 then
        assert hash_found = '1' report "comparator was expected to find a hash value, but didn't" severity failure;
        hash_value <= x"0100000000000000000000000000000000000000000000000000FFFF00000000";
      end if;

      if i = 19 then
        assert hash_found = '0' report "a hash value was returned although greater than target" severity failure;
        target <= x"1711a333";
        hash_value <= x"6cf76dafc1b4b5c7702d8f4a808ade2aa8c7474199ed0d000000000000000000";
      end if;

      if i = 21 then
        assert hash_found = '1' report "comparator was expected to find a hash value, but didn't" severity failure;
      end if;

    end if;

  end process;

end v1;
