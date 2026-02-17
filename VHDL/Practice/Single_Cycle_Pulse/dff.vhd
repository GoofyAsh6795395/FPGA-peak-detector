library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dff is
	port(
		clk: in STD_LOGIC;
		d: in STD_LOGIC;
		q: out STD_LOGIC
	);
end entity;

architecture simulation of dff is
begin
	process(clk)
	begin
		if rising_edge(clk) then
			q <= d;
		end if;
	end process;
end architecture;
