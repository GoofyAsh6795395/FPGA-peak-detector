library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mul_accum is
	port(
		clk: in STD_LOGIC;
		a: in integer range 0 to 256;
		b: in integer range 0 to 256;
		c: in integer range 0 to 256;
		result: out integer range 0 to 1024
	);
end entity;

architecture normal of mul_accum is
    signal a_reg, b_reg, c_reg: integer range 0 to 256;
begin
	process(clk, a, b, c)
	begin
		if rising_edge(clk) then
		    a_reg <= a;
		    b_reg <= b;
		    c_reg <= c;
			result <= a_reg * b_reg + c_reg;
		end if;
	end process;
end architecture;