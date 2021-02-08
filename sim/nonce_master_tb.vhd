library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nonce_master_tb is
end entity;

architecture v1 of nonce_master_tb is
  component nonce_master is
    port(
        clk                 : in    std_logic;
        header_in           : in    std_logic_vector(31 downto 0);
        header_enable       : in    std_logic;
        reset               : out   std_logic;
        threshold_out       : out   std_logic_vector(31 downto 0);
        mining_enable       : out   std_logic
      );
  end component;

  signal clk, reset, mining_enable, header_enable : std_logic := '0';
  signal threshold_out : std_logic_vector(31 downto 0);
  signal header_in: std_logic_vector(607 downto 0);
  signal i : integer := 0; -- number of clock cycles

begin

  nonce_master_comp: nonce_master
  port map(
    clk => clk,
    header_in => header_in(31 downto 0),
    header_enable => header_enable,
    reset => reset,
    threshold_out => threshold_out,
    mining_enable => mining_enable
  );

  -- simulate clock
  process
  begin

    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    i <= i + 1;

    if i = 20 then
      wait;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then

      if i = 4 then
        -- Initially reset should be 0
        assert reset = '0' report "Nonce master is supposed to keep reset at 0 until header changes" severity failure;
        assert mining_enable = '0' report "Nonce master is supposed to keep enable at 0 until header changes" severity failure;
        -- Pass first header
        header_in <= x"00000020a9d3e619c61beb426d951c77cf09d6d7a95d8471ef8604000000000000000000c2ee46bca5d44b999df0b008e920df68b235d9baa7f77fbfec99f88e86e248035817ac5e33a31117";
        header_enable <= '1';
      end if;

      if i = 7 then
       report "##### Nonce master test passed #####" severity note;
    end if;


      if falling_edge(clk) then
        if i = 5 then
          assert reset = '1' report "Reset should be set after having been passed a header" severity failure;
        end if;

        if i = 6 then
          assert reset = '0' report "Reset should only stay on 1 for 1 clk cycle" severity failure;
          assert threshold_out = x"1711a333" report "Threshold was read out wrong" severity failure;
          assert mining_enable = '1' report "Mining should be enabled when new header is entered" severity failure;
        end if;

      end if;

    end if;

  end process;

end v1;
