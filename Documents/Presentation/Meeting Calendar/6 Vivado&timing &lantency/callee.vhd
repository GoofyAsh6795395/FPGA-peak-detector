library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity callee is
	port(
		clk: in STD_LOGIC;
		req: in STD_LOGIC;
		ack: out STD_LOGIC;
		data: out integer range 0 to 15
	);
end entity;

architecture sim of callee is
	type stateType is (ready, processing);
	signal current_state, next_state: stateType;
	signal data_next, data_reg: integer range 0 to 15 := 0;
begin
	data <= data_reg;
	state_transition_logic:
	process(current_state, req)
	begin
		next_state <= current_state;
		case current_state is
			when ready =>
				if req = '1' then
					next_state <= processing;
				else
					next_state <= ready;
				end if;
			when processing =>
				next_state <= ready;
			when others =>
				next_state <= ready;
		end case;
	end process;

	datapath:
	process(current_state, req)
	begin
		data_next <= data_reg;
		ack <= '0';
		if current_state = ready and req = '1' then
			ack <= '1';	--It's a single cycle pulse here.
			data_next <= data_reg + 1;
		end if;
	end process;

	clocked:
	process(clk, current_state)
	begin
		if rising_edge(clk) then
			current_state <= next_state;
			data_reg <= data_next;
		end if;
	end process;
end architecture;