library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sim_tb_top is
end entity sim_tb_top;

architecture tb of sim_tb_top is

    component main is
        port (
            sys_clk : in std_logic;
            tx_pin    : out std_logic;
            rx_pin    : in std_logic
        );
    end component;

    signal clk          : std_logic := '0';
    constant clk_period : time      := 5 ns;

begin

    clk   <= not clk after (clk_period/2);

    u_ip_top : main port map(
        sys_clk => clk,
        tx_pin  => open,
        rx_pin  => '0'
    );

end architecture tb;