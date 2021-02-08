-- testbench for compressor

-- this testbench tests compressor with w = 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity compressor_tb is
end entity;

architecture v1 of compressor_tb is
  component compressor 
    port(
        clk                     : in std_logic;
        reset                   : in std_logic;
        wk_is_new               : in std_logic;
        wk_is_last              : in std_logic;
        chunk_is_new            : in std_logic;
        wk_1                    : in unsigned(31 downto 0);
        wk_2                    : in unsigned(31 downto 0);
        hash                    : out std_logic_vector(255 downto 0)
    );
  end component;

  signal clk : std_logic;
  signal wk_is_last : std_logic;
  signal chunk_is_new : std_logic;
  signal wk_1 : unsigned(31 downto 0);
  signal wk_2 : unsigned(31 downto 0);
  signal hash: std_logic_vector(255 downto 0);

  signal i : integer := 0;
  
    type consts is array(0 to 63) of unsigned(31 downto 0);
    constant k : consts := (
        x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
        x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
        x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
        x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
        x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13", x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
        x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3", x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
        x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5", x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
        x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208", x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
    );
begin

  c: compressor port map(
    clk => clk,
    reset => '0',
    wk_is_new => '1',
    wk_is_last => wk_is_last,
    chunk_is_new => chunk_is_new,
    wk_1 => wk_1,
    wk_2 => wk_2,
    hash => hash
  );

  wk_is_last <= '1' when i = 31 else '0';
  chunk_is_new <= '1' when (i = 0 or i = 32) else '0';
  wk_1 <= k((i mod 32) * 2);
  wk_2 <= k((i mod 32) * 2 + 1);
  process
  begin

    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;

    i <= i + 1;

    if i = 36 then
        wait;
    end if;
  end process;

  process(clk)
  begin
    if(clk'event and clk='1') then

      if i = 34 then
        assert (hash = x"DA5698BE17B9B46962335799779FBECA8CE5D491C0D26243BAFEF9EA1837A9D8")
        report "##### TEST FAILED #####" severity failure;
      end if;
    
    end if;
  end process;

end v1;

