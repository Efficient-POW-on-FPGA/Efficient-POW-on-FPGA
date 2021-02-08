library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity compressor is
    port (
        clk                     : in std_logic;
        reset                   : in std_logic;
        wk_is_new               : in std_logic;
        wk_is_last              : in std_logic;
        chunk_is_new            : in std_logic;
        wk_1                    : in   unsigned(31 downto 0);
        wk_2                    : in   unsigned(31 downto 0);
        hash                    : out std_logic_vector(255 downto 0)
    );
end entity;

architecture v1 of compressor is
    -- (x"6a09e667", x"bb67ae85", x"3c6ef372", x"a54ff53a", x"510e527f", x"9b05688c", x"1f83d9ab", x"5be0cd19");
    constant state : std_logic_vector(255 downto 0) := x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
begin
    comp : compressor_second_stage
    port map (
        clk => clk,
        reset => reset,
        state_init => state,
        wk_1 => wk_1,
        wk_2 => wk_2,
        wk_is_new => wk_is_new,
        wk_is_last => wk_is_last,
        chunk_is_new => chunk_is_new,
        hash => hash
    );
end architecture;

