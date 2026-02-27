library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity rx_handshaker is
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

architecture synth of rx_handshaker is
	type stateType is (idle, processing);
	signal current_state, next_state: stateType := idle;
begin
	--There is always a signal on the output port.
	--The down-stream FIFO use the enqueue_request to determine whether the output data is valid or not.
	data_out <= data_in;

	state_transition_logic:
	process(current_state, valid, oe, fe)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>	
				if valid = '1' then
					next_state <= processing;
				else
					next_state <= idle;
				end if;
			when processing =>
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
			when idle =>
				done <= '0';
				enqueue_req <= '0';
				if oe = '1' or fe = '1' then
					--Pull up the "done" signal to avoid stalling when of/fe are detected
					--Because oe/fe last for one cycle, done signal will also be kept for same interval.
					done <= '1';
				else
					done <= '0';
				end if;
			when processing =>
				enqueue_req <= '1';
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
--
--Firstly drafted on 26/02/2026
--
--Commitment at 1pm, 26/02/2026:
--	Succeed compiling, but untested.
--
--Commitment at 4pm, 26/02/2026
--	Work in order, but too slow, too redundant
--	The simplification of FSM as well as single cycle pulse method are desired.
--
--Commitment at 4.30pm, 26/02/2026
--	Work in order except one circumstance where data changes while valid keeps high.
--	If needed, input should be registered to stablise the output.
--
--Commitment at 4.35pm, 26/02/2026
--	After a deep consideration, it should be ok.
--
--Commitment at 12pm, 27/02/2026
--	Rename the entity and file name, also in testbench
--	Reconstruct the work directory