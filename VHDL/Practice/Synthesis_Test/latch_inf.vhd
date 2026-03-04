library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity media is
	port(
		clk: in STD_LOGIC;
		sig_in: in STD_LOGIC;
		condition: in STD_LOGIC;
		out1: out STD_LOGIC;
		out2: out STD_LOGIC;
		out3: out STD_LOGIC
	);
end entity;

architecture volt_level of media is
begin
	--Voltage_level
	process(condition)
	begin
		if condition = '1' then
			out1 <= sig_in;
		else
			out1 <= '0';		--An arbitiary assignment to avoid latch.
		end if;
	end process;

	--Latch(maybe)
	process(condition)
	begin
		if condition = '1' then
			out2 <= sig_in;
		end if;
	end process;

	--DFF
	process(clk, condition)
	begin
		if rising_edge(clk) then
			out3 <= sig_in;
		end if;
	end process;

end architecture;
