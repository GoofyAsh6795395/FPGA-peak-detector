library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity typeConversion is
	port(
		vector: in STD_LOGIC_VECTOR (7 downto 0);
		result_resolved: out integer
	);
end entity;

architecture sim of typeConversion is
	
begin
	result_resolved <= to_integer(signed(vector));

end architecture;