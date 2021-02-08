library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hash_components.all;

entity compressor_second_stage is
    port (
        clk                     : in std_logic;
        reset                   : in std_logic;
        state_init              : in std_logic_vector(255 downto 0); --when reset, compressor takes this as state
        wk_is_new               : in std_logic;
        wk_is_last              : in std_logic;
        chunk_is_new            : in std_logic;
        wk_1                    : in   unsigned(31 downto 0);
        wk_2                    : in   unsigned(31 downto 0);
        hash                    : out std_logic_vector(255 downto 0)
    );
end entity;

architecture v1 of compressor_second_stage is
    function t1er(s4 : unsigned(31 downto 0);
        s5 : unsigned(31 downto 0);
        s6 : unsigned(31 downto 0);
        s7 : unsigned(31 downto 0);
        wwkk : unsigned(31 downto 0)) return unsigned is
    begin
        return s7 + (rotate_right(s4, 6) xor rotate_right(s4, 11) xor rotate_right(s4, 25)) + ((s4 and s5) xor ((not s4) and s6)) + wwkk;
    end function;
    function t2er(s0 : unsigned(31 downto 0);
        s1 : unsigned(31 downto 0);
        s2 : unsigned(31 downto 0)) return unsigned is
    begin
        return (rotate_right(s0, 2) xor rotate_right(s0, 13) xor rotate_right(s0, 22)) + ((s0 and s1) xor (s0 and s2) xor (s1 and s2));
    end function;

begin
    process (clk, reset) 
        variable state : compressor_state; -- (x"6a09e667", x"bb67ae85", x"3c6ef372", x"a54ff53a", x"510e527f", x"9b05688c", x"1f83d9ab", x"5be0cd19");
        variable t11 : unsigned(31 downto 0);
        variable t12 : unsigned(31 downto 0);
    begin
    if reset = '1' then
        --initialize so that rising edge doesnt affect things
    else
        if rising_edge(clk) and wk_is_new = '1' then

            if chunk_is_new = '1' then
                for l in 0 to 7 loop
                    state(7-l) := unsigned(state_init(32*l+31 downto 32*l));
                end loop;
            end if;
            
            t11      := t1er(state(4), state(5), state(6), state(7), wk_1);
            state(7) := state(5);
            state(5) := state(3) + t11;
            t12      := t1er(state(5), state(4), state(7), state(6), wk_2);
            state(6) := state(4);
            state(4) := state(2) + t12;

            state(3) := state(1);
            state(1) := t11 + t2er(state(0), state(1), state(2));


            state(2) := state(0);
            state(0) := t12 + t2er(state(1), state(2), state(3));

            if wk_is_last = '1' then
                for l in 0 to 7 loop
                    hash(32*l+31 downto 32*l) <= std_logic_vector(unsigned(state_init(32*l+31 downto 32*l)) + state(7-l));
                end loop;
            end if;
        end if;
    end if;
end process;
end architecture;
