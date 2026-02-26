library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity rx_control is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;
		
		--To receiver.
		oe: in STD_LOGIC;
		fe: in STD_LOGIC;

		valid: in STD_LOGIC;
		done: out STD_LOGIC;
		data_in: in STD_LOGIC_VECTOR(7 downto 0);

		
		--To FIFO.
		enqueue_req: out STD_LOGIC;
		data_out: out STD_LOGIC_VECTOR(7 downto 0)
	);
end entity;

architecture synth of rx_control is
	type stateType is (idle, enqueue, ack);
	signal current_state, next_state: stateType := idle;
begin
	--There is always a signal on the output port.
	--The down-stream FIFO use the enqueue_request to determine whether the output is valid or not.
	data_out <= data_in;


	state_transition_logic:
	process(current_state, valid, oe, fe)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>	
				if oe = '1' or fe = '1' then
					--Pull up the "done" signal to avoid stalling when of/fe are detected
					next_state <= ack;
				elsif valid = '1' then
					next_state <= enqueue;
				else
					next_state <= idle;
				end if;
			when enqueue =>
				next_state <= ack;
			when ack =>
				next_state <= idle;
			when others =>
				next_state <= idle;
		end case;
	end process;
	
	output_logic:
	process(current_state)
	begin
		--To avoid latch inferrence
		enqueue_req <= '0';
		done <= '0';

		case current_state is
			when enqueue =>
				enqueue_req <= '1';
			when ack =>
				done <= '1';
			when others => null;
		end case;
	end process;
	
	clocked_control_logic:
	process(clk, reset)
	begin
		if rising_edge (clk) then
			if reset = '1' then
				current_state <= idle;
			else
				current_state <= next_state;
			end if;
		end if;
	end process;
end architecture;

--Log:
--Firstly drafted on 26/02/2026
--Commitment:
--	Succeed compiling, but untested.
--End;