library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_core is
	port(
		--100 MHz
		clk_out1  : out STD_LOGIC;
		--200 MHz
		clk_out2  : out STD_LOGIC;
		clk_in1 : in  STD_LOGIC
	);
end entity clk_core;

architecture RTL of clk_core is
	signal r_clk1 : std_logic := '0';
	signal r_clk2 : std_logic := '0';
begin
	process(clk_in1) is
	begin
		if rising_edge(clk_in1) then
			r_clk1<= not r_clk1;
			r_clk2<= not r_clk2;
		end if;
		if falling_edge(clk_in1) then
			r_clk2<= not r_clk2;
		end if;
	end process;
	clk_out1<=r_clk1;
	clk_out2<=r_clk2;
end architecture RTL;
