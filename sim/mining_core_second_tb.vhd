library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.hash_components.all;

entity mining_core_second_tb is
end entity;


architecture v1 of mining_core_second_tb is

  component mining_core
    generic (
      modulo_remainder : unsigned(31 downto 0) := x"00000000";
      step  : unsigned(31 downto 0) := x"00000001";
      is_first : std_logic := '0'
      );
    port (
      clk              : in std_logic;
      reset            : in std_logic;
      header_chunk_one : in    std_logic_vector(543 downto 32);
      header_chunk_two : in    std_logic_vector(31 downto 0);
      start_nonce      : in unsigned(31 downto 0);
      threshold        : in std_logic_vector(31 downto 0);
      timestamp        : in unsigned(31 downto 0);
      mining_enable    : in std_logic := '0';
      hash_buffer_in   : in std_logic_vector(255 downto 0);
      buffer_ready     : out std_logic;
      found            : out std_logic;
      nonce_found      : out std_logic_vector(31 downto 0);
      hash             : out std_logic_vector(255 downto 0)
    );
  end component;

  signal clk, reset, mining_enable, found : std_logic;
  signal start_nonce,timestamp : unsigned(31 downto 0);
  signal header : std_logic_vector(543 downto 0);
  signal threshold, nonce_found : std_logic_vector(31 downto 0);
  signal hash : std_logic_vector(255 downto 0);
  signal buffer_in : std_logic_vector(255 downto 0) := x"bc909a336358bff090ccac7d1e59caa8c3c8d8e94f0103c896b187364719f91b";

  -- searched hash values found?
  signal found_1, found_2, found_3 : std_logic := '0';

  --unexpected hash value found?
  signal found_u : std_logic := '0';

  -- number of clocks after which simulation ends (at the latest)
  constant num_of_clocks : integer := 30000;
  signal i : integer := 0;

begin

  mining_core_component : mining_core port map(clk => clk,
    reset => reset,
    header_chunk_one    => header(543 downto 32),
    header_chunk_two    => header(31 downto 0), 
    start_nonce => start_nonce,
    threshold => threshold,
    timestamp => timestamp,
    mining_enable => mining_enable,
    hash_buffer_in => buffer_in,
    found => found,
    nonce_found => nonce_found,
    hash => hash);

  process
  begin
    
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    if (found_1 = '1' and found_2 = '1' and found_3 = '1') then
      report "all tests of mining_core_second_tb were successfull!" severity note;
      wait;
    end if;

    if (i = num_of_clocks) then
      if found_1='0' then
        report "searching for first hash value failed!" severity failure;
      elsif found_2 = '0' then
        report "searching for second hash value failed!" severity failure;
      elsif found_3 = '0' then
        report "searching for third hash value failed!" severity failure;
      elsif found_u = '1' then
        report "an unexpected hash value was found!" severity failure;
      end if;
    else
      i <= i + 1;
    end if;

  end process;

  process(clk)
  begin

    if rising_edge(clk) then

      if mining_enable = '1' then
        mining_enable <= '0';
      end if;

      if reset = '1' then
        reset <= '0';
        mining_enable <= '1';
      end if;

      if i = 0 then
        -- send reset signal
        mining_enable <= '0';
        start_nonce <= x"7C2bAC1A";
        reset <= '1';
      end if;
      
      if i = 1 then
        threshold <= x"1d00ffff";
        timestamp <= x"495FAB29"; 
        header <= x"0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a";
      end if;

      if found='1' then
        if unsigned(nonce_found) = x"7C2bAC1D" then
          found_1 <= '1';
          threshold <= x"20ffffff";
          reset <= '1';
        elsif unsigned(nonce_found) = x"7C2bAC1A" then
          found_2 <= '1';
          header <= x"0000ff3f50b56919c197ff4d3c03d6f565165768a53ed8d36ad600000000000000000000e2ad010b938a393b01125af58658b8832337cc521117d9de9e53311fdadd3ca8";
          threshold <= x"170e134e";
          timestamp <= x"5f98fef3"; 
          start_nonce <= x"d21ee95C";
          reset <= '1';
          buffer_in <= x"f4787c72ffd973b95ef1e6126615e3c6f3cb14c68a85af5e1e00465009ea9b45";
        elsif unsigned(nonce_found) = x"d21ee961" then
          found_3 <= '1';
          threshold <= x"00000000";
          reset <= '1';
          buffer_in <= x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
        else
          found_u <= '1';
        end if;
        --report "fitting hash value found with nonce " & integer'image(to_integer(unsigned(nonce_found))) severity note;
      end if;
      
    end if;
  end process;
end v1;
