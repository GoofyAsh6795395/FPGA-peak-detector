library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity scheduler is
	port(
		--External control:
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;
		
		--To parser.
		isANNN: in STD_LOGIC;
		isL: in STD_LOGIC;
		isP: in STD_LOGIC;

		--To transmitter side.
		data_out: out STD_LOGIC_VECTOR(7 downto 0);
		print_req: out STD_LOGIC;
		print_ack: in STD_LOGIC;

		--To data processor

		start: out STD_LOGIC;
		dataReady: in STD_LOGIC;
		seqDone: in STD_LOGIC;

		numWords: out STD_LOGIC(11 downto 0);
		byte: in STD_LOGIC_VECTOR(7 downto 0);
		dataResults: in STD_LOGIC_VECTOR(55 downto 0);
		maxIndex: in STD_LOGIC_VECTOR(11 downto 0);

		start: out STD_LOGIC;
		dataReady: in STD_LOGIC;
		seqDone: in STD_LOGIC;
	);
end entity;

architecture synth of scheduler is
	type stateType is (idle, run, printData, printL, printP);
	signal current_state, next_state: stateType := idle;
begin
	state_transition_logic:
	
end architecture;