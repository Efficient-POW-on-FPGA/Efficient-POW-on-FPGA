library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity mining_core_tb is
end entity;

architecture v1 of mining_core_tb is
  component mining_core
    generic (
      modulo_remainder : unsigned(31 downto 0) := x"00000000";
      step  : unsigned(31 downto 0) := x"00000001";
      is_first : std_logic := '1'
      );
    port (
      clk              : in std_logic;
      reset            : in std_logic;
      header_chunk_one : in    std_logic_vector(543 downto 32);
      header_chunk_two : in    std_logic_vector(31 downto 0);
      start_nonce      : in unsigned(31 downto 0);
      threshold        : in std_logic_vector(31 downto 0);
      timestamp        : in unsigned(31 downto 0);
      mining_enable    : in std_logic;
      hash_buffer_in   : in std_logic_vector(255 downto 0);
      hash_buffer_out  : out std_logic_vector(255 downto 0);
      buffer_ready     : out std_logic;
      found            : out std_logic;
      nonce_found      : out std_logic_vector(31 downto 0);
      hash             : out std_logic_vector(255 downto 0)
    );
  end component;

  signal clk, found : std_logic;
  signal reset : std_logic := '1';
  signal mining_enable : std_logic := '0';
  signal header : std_logic_vector(543 downto 0) := x"0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a";
  signal threshold, nonce_found : std_logic_vector(31 downto 0);
  signal hash : std_logic_vector(255 downto 0);
  signal first_buffer_out : std_logic_vector(255 downto 0) ;
  signal first_buffer_in : std_logic_vector(255 downto 0) := x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
  signal first_buffer_ready : std_logic;

  -- first (/second) hash value found?
  signal found_1 : std_logic := '0';

  -- number of clocks after which simulation ends (at the latest)
  constant num_of_clocks : integer := 500;
  signal i : integer := 0;

begin

  mining_core_component : mining_core port map(
    clk => clk,
    reset => reset,
    header_chunk_one    => header(543 downto 32),
    header_chunk_two    => header(31 downto 0), 
    start_nonce => x"7C2bAC1A",
    threshold => x"1d00ffff",
    timestamp => x"495FAB29",
    mining_enable => mining_enable, 
    hash_buffer_in => first_buffer_in,
    hash_buffer_out => first_buffer_out, 
    buffer_ready => first_buffer_ready,
    found => found, 
    nonce_found => nonce_found, 
    hash => hash
  );

  process
  begin

    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    if found_1='1' then
        wait;
    end if;

    if (i = num_of_clocks) then
    report "##### TICKS PER HASH FAILED!" severity failure;
      wait;
    else
      i <= i + 1;
    end if;

  end process;

  process(clk, first_buffer_ready)
  begin

    if first_buffer_ready = '1' then
      first_buffer_in <= first_buffer_out;
    end if;

    if rising_edge(clk) then

      if reset = '1' then
        reset <= '0';
        mining_enable <= '1';
      end if;

      if mining_enable = '1' then
        mining_enable <= '0';
      end if;

      if found='1' then
        if unsigned(nonce_found) = x"7C2bAC1D" then
          found_1 <= '1';
        end if;
        -- i-4 because three empty cycles at the beginning (3 + 1 additional reset cycle)
        report "##### CLOCK CYCLES UNTIL FIRST HASH IS CALCULATED:" & integer'image(i-4) severity note;
      end if;

    end if;
  end process;
end v1;
