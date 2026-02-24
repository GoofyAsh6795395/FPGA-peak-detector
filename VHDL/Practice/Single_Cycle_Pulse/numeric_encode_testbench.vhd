library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity typeConversion_tb is
	port(
		vector: in STD_LOGIC_VECTOR (7 downto 0);
		result_resolved: out integer
	);
end entity;

architecture sim of typeConversion_tb is
	component typeConversion is
		port(
			vector: in STD_LOGIC_VECTOR (7 downto 0);
			result_resolved: out integer
		);
	end component;
	signal vector_tb: STD_LOGIC_VECTOR (7 downto 0);
	signal result: integer := 0;
begin
	dut: typeConversion port map (vector_tb, result);
	process
	begin
		vector_tb <= "01111111";
		--Two's complement: 127
		--Sign Magnitude: 127
		wait for 5 ns;
		vector_tb <= "10000000";
		--Two's complement: -128
		--Sign Magnitude: -0
		wait;
	end process;

end architecture;