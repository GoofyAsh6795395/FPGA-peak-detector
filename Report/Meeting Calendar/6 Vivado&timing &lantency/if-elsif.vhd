library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity if_elsif is
	port(
	    clk: in STD_LOGIC;     --Ignore it in this file, for the purpose of timing constraint later.
		input1: in integer range 0 to 8;
		input2: in integer range 0 to 8;
		input3: in integer;
		output: out integer range 0 to 8
	);
end entity;

--architecture independent_cond of if_elsif is
--	signal internal: integer range 0 to 8 := 0;
--begin
--	internal <= input1;
--	process(internal)
--	begin
--		if internal > 0 then
			
--			if input2 > 5 then
--				output <= 1;
--			else
--				output <= 2;
--			end if;
--		else
--			output <= 3;
--		end if;
--	end process;
--end architecture;

--architecture dependent_cond of if_elsif is
--	signal internal: integer range 0 to 8 := 0;
--begin
--	internal <= input1;
--	process(internal)
--	begin
--		if internal > 0 then
--			if internal > 5 then
--				output <= 1;
--			else
--				output <= 2;
--			end if;
--		end if;
--	end process;
--end architecture;

architecture int32 of if_elsif is
	signal internal: integer := 0;
begin
	internal <= input3;
	process(internal)
	begin
		if internal > 0 then
			if internal > 5 then
				output <= 1;
			else
				output <= 2;
			end if;
		end if;
	end process;
end architecture;
