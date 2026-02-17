library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dff_testbench is
	port(
		clk: in STD_LOGIC;
		d: in STD_LOGIC;
		q: out STD_LOGIC
	);
end entity;

architecture simulation of dff_testbench is
	component dff is
		port(
			clk: in STD_LOGIC;
			d: in STD_LOGIC;
			q: out STD_LOGIC
		);
	end component;
	signal clk_tb, d_tb, q_tb: STD_LOGIC;
begin
	dut: dff port map (clk_tb, d_tb, q_tb);
	process
	begin
		clk_tb <= '0';
		d_tb <= '0';
		wait for 5 ns;
		
		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		wait for 5 ns;

		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		d_tb <= '1';
		wait for 5 ns;

		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		wait for 5 ns;

		clk_tb <= '1';
		d_tb <= '0';
		wait for 5 ns;

		clk_tb <= '0';
		wait for 5 ns;

		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		wait for 5 ns;

		clk_tb <= '1';
		wait for 5 ns;
		wait;
	end process;
end architecture;