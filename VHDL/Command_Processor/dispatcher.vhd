library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dispatcher is
	port(
		--Control.
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;

		--To FIFO.
		isEmpty: in STD_LOGIC;
		dequeue_req: out STD_LOGIC;
		data_in: in STD_LOGIC_VECTOR(7 downto 0);

		--To parser.
		--This signal should last only one cycle (single cycle pulse)
		--To make sure the parser not to repeatly read a same command.
		parser_en: out STD_LOGIC;

		--An unified output channel of data
		--To both parser and Tx.
		--If valid or not is determined by corrsponding controlled signal.
		data_out: out STD_LOGIC_VECTOR(7 downto 0);

		--To transmitter side.
		--Request is a voltage level signal instead of single cycle pulse.
		--Last for 2 clock cycles at minimum.
		echo_req: out STD_LOGIC;
		echo_acknowledged: in STD_LOGIC;

	);
end entity;

architecture synth of dispatcher is
	type stateType is (idle, dequeue, dispatch, waitting);
	signal current_state, next_state: stateType := idle;
	signal data_reg: STD_LOGIC_VECTOR(7 downto 0);
begin
	--data_out <= data_in;

	state_transition_logic:
	process(current_state, isEmpty, echo_acknowledged,)
	begin
		
	end process;

	datapath:
	process(current_state)
	begin
		--To avoid latch inferrence.
		--To maintain some single pulse cycle outputs.
		echo_req <= '0';
		parser_en <= '0';
		dequeue_req <= '0';

		case
			
		end case;
	end process;

	clocked_control:
	process(current_state)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			else
				
			end if;
		end if;
	end process;
end architecture;