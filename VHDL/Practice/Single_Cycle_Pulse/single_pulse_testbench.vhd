library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity single_pulse_testbench is
end entity;

architecture rtl of single_pulse_testbench is
	component single_pulse is
		port(
			clk: in STD_LOGIC;
			level_in: in STD_LOGIC;
			output: out STD_LOGIC
	);
	end component;
	for reg: single_pulse use entity work.single_pulse(reg);
	for FSM: single_pulse use entity work.single_pulse(FSM);
	for FSM_2nd: single_pulse use entity work.single_pulse(FSM_2nd);
	signal level_in_tb, clk_tb, output_reg, output_FSM, output_FSM_2nd: STD_LOGIC;
begin
	reg: single_pulse port map (clk_tb, level_in_tb, output_reg);
	FSM: single_pulse port map (clk_tb, level_in_tb, output_FSM);
	FSM_2nd: single_pulse port map (clk_tb, level_in_tb, output_FSM_2nd);
	process
	begin
		clk_tb <= '0';
		level_in_tb <= '0';
		wait for 5 ns;
		
		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		wait for 5 ns;

		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		level_in_tb <= '1';
		wait for 5 ns;

		clk_tb <= '1';
		wait for 5 ns;

		clk_tb <= '0';
		wait for 5 ns;

		clk_tb <= '1';
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