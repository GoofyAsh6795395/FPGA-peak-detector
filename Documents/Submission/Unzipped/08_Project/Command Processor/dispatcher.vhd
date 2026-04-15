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
		echo_ack: in STD_LOGIC

	);
end entity;

architecture synth of dispatcher is
	type stateType is (idle, dispatch, waitting);
	signal current_state, next_state: stateType := idle;
begin
	--No use of extra register to store input data anymore.
	--To avoid one extra clock cycle latency, now is one cycle, from request to valid & dispatch.
	data_out <= data_in;

	state_transition_logic:
	process(current_state, isEmpty, echo_ack)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>
				if isEmpty /= '1' then
					next_state <= dispatch;
				else
					next_state <= idle;
				end if;
			when dispatch =>
				next_state <= waitting;
			when waitting =>
				if echo_ack = '1' then
					next_state <= idle;
				else
					next_state <= waitting;
				end if;
			when others =>
				next_state <= idle;
		end case;
	end process;

	datapath:
	process(current_state, echo_ack)
	begin
		--To avoid latch inferrence.
		echo_req <= '0';
			--It's a voltage level signal.

		--To maintain some single pulse cycle outputs.
		parser_en <= '0';
		dequeue_req <= '0';

		case current_state is
			when dispatch =>
				--Keep requesting echo level high, until it's acknowledged
				echo_req <= '1';
				parser_en <= '1';
			when waitting =>
				if echo_ack = '1' then
					dequeue_req <= '1';
				else
					echo_req <= '1';
					--Keep high, until acknowledged signal is captured.
				end if;
			when others =>
				null;
		end case;
	end process;

	clocked_control:
	process(clk, reset)
	begin
		if rising_edge(clk) then
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
--
--Commitment at 12pm, 26/02/2026:
--	Succeed compiled, but untested.
--
--Modified on 05/03/2026:
--	Corrected the reset logic.
--	Tested, but not coverged, works in order.
--
--Modified on 09/03/2026:
--	Change the whole state transition logic.
--	Identified the problem of "echo_req", which is a voltage level signal instead of single cycle pulse.
--	!Following the logic of fifo, disptach first and dequeue later.
--		Because the signal on fifo_dispatcher_bus hints the data already available to dispatch.
