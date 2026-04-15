library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity caller is
	port(
		clk: in STD_LOGIC;
		req: out STD_LOGIC;
		ack: in STD_LOGIC
	);
end entity;

architecture sim of caller is
	type stateType is (idle, run);
	signal current_state, next_state: stateType;
begin
	state_transition_logic:
	process(current_state, ack)
	begin
		next_state <= current_state;	--Avoid latch.
		case current_state is
			when idle =>
				next_state <= run;
			when run =>
				if ack = '1' then
					next_state <= idle;
				else
					next_state <= run;
				end if;
			when others =>
				next_state <= idle;
		end case;
	end process;
	
	datapath:
	process(current_state, ack)
	begin
		req <= '0';	--Assign at the beginning to avoid latch inferrence.
		if current_state = run then
			if ack = '1' then
				req <= '0';
			else
				req <= '1';
			end if;
		end if;
	end process;

	clocked:
	process(clk, current_state)
	begin
		if rising_edge(clk) then
			current_state <= next_state;
		end if;
	end process;


end architecture;