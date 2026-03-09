library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity tx_controller is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;

		--To receiver side
		echo_req: in STD_LOGIC;
		echo_ack: out STD_LOGIC;
		data_echo: in STD_LOGIC_VECTOR(7 downto 0);

		--To scheduler.
		print_req: in STD_LOGIC;
		print_ack: out STD_LOGIC;
		data_print: in STD_LOGIC_VECTOR(7 downto 0);

		--To transmitter.
		txnow: out STD_LOGIC;
		txdone: in STD_LOGIC;
		data_out: out STD_LOGIC_VECTOR(7 downto 0)
	);
end entity;

architecture synth of tx_controller is
	type stateType is (idle, ack, transmitting, waitting);
	signal current_state, next_state: stateType := idle;
	signal data_reg: STD_LOGIC_VECTOR(7 downto 0) := "00000000";
begin
	--Keep connected, but the time of sampling is determined by transmitter, based on TxNow signal.
	data_out <= data_reg;

	state_transition_logic:
	process(current_state, echo_req, print_req, txdone)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>
				if echo_req = '1' or print_req = '1' then
					next_state <= ack;
				else
					next_state <= idle;
				end if;
			when ack =>
				next_state <= transmitting;
			when transmitting =>
				next_state <= waitting;
			when waitting =>
				if txdone = '1' then
					next_state <= idle;
				else
					next_state <= waitting;
				end if;
			when others =>
				next_state <= idle;
		end case;
	end process;

	datapath:
	process(current_state, echo_req, print_req)
	begin
		--Single cycle pulses.
		echo_ack <= '0';
		print_ack <= '0';
		txnow <= '0';
		case current_state is
			when ack =>
				if echo_req = '1' then
					echo_ack <= '1';
				elsif print_req = '1' then
					print_ack <= '1';
				end if;
			when transmitting =>
				txnow <= '1';
			when others =>
				null;
		end case;
	end process;

	control:
	process(clk, reset, echo_req, print_req, data_echo, data_print)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				current_state <= idle;
				--Try aggregate style assignment
				data_reg <= (others => '0');
			else
				current_state <= next_state;
				
				--Instead of level-sensitive datapath process, the assignment of data register should be put in clocked process
				--Then, it will be a resettable DFF with an enable signal.
				if current_state = ack then
					--Use if, elsif statement to maintain the priority of echo operation.
					--In hardware level, I deduce it should be a cascaded mux logic to implement such a function(Not cure)
					if echo_req = '1' then
						data_reg <= data_echo;
					elsif print_req = '1' then
						data_reg <= data_print;
					end if;
				end if;
			end if;
		end if;
	end process;

end architecture;

--Log:
--
--Firstly drafted on 26/02/2026.
--
--Commitment at 5pm, 26/02/2026:
--	Not finished.
--
--Commitment at 11am, 27/02/2026:
--	Succeed compiling, but not tested.
--
--Modification on 08/03/2026:
--	Rename some ports to match the testbench and assignment requirements.
--
--Modification on 09/03/2026:
--	Corrected the sensitivity list, added all RHS and conditions used.
