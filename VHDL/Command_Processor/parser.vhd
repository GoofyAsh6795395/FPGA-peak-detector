library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity parser is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;
		command: in STD_LOGIC_VECTOR (7 downto 0);
		enable: in STD_LOGIC;

		isANNN: out STD_LOGIC;
		isL: out STD_LOGIC;
		isP: out STD_LOGIC
	);
end entity;

architecture synth of parser is
	type recorded is (idle, A, AN, ANN);
	--Mealy-style FSM is utilised in this programme to simplify the response of enable signal.
	--Because the enable signal lasts for only one cycle and control the behaviour of both reading and sendout commands.
	--The delayed feature of Moore-style FSM is not friendly for such an enable signal.
	--So, there are not separated state "ANNN", "L" or "P" in the type declaration.
	signal current_state, next_state: recorded := idle;

	constant ascii_a: STD_LOGIC_VECTOR (7 downto 0) := x"61";
	constant ascii_a_cap: STD_LOGIC_VECTOR (7 downto 0) := x"41";
	constant ascii_l: STD_LOGIC_VECTOR (7 downto 0) := x"6C";
	constant ascii_l_cap: STD_LOGIC_VECTOR (7 downto 0) := x"4C";
	constant ascii_p: STD_LOGIC_VECTOR (7 downto 0) := x"50";
	constant ascii_p_cap: STD_LOGIC_VECTOR (7 downto 0) := x"70";
	constant ascii_0: STD_LOGIC_VECTOR (7 downto 0) := x"30";
	constant ascii_9: STD_LOGIC_VECTOR (7 downto 0) := x"39";

	--signal ANNN_found, L_found, P_found: STD_LOGIC := '0';
	--signal ANNN_next, L_next, P_next: STD_LOGIC := '0';
begin
	state_transition_logic:
	process(enable, command, current_state)
	begin
		next_state <= current_state;
		if enable = '1' then
			case current_state is
			when idle =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= idle;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= idle;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				else
					next_state <= idle;
				end if;
			when A =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= idle;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= idle;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				elsif command >= ascii_0 and command <= ascii_9
					then next_state <= AN;
				else
					next_state <= idle;
				end if;
			when AN =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= idle;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= idle;
				elsif command = ascii_a_cap or command = ascii_a 
					then next_state <= A;
				elsif command >= ascii_0 and command <= ascii_9
					then next_state <= ANN;
				else
					next_state <= idle;
				end if;
			when ANN =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= idle;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= idle;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				elsif command >= ascii_0 and command <= ascii_9
					then next_state <= idle;
				else
					next_state <= idle;
				end if;

			when others =>
				next_state <= idle;
			end case;
		end if;
	end process;

	--Use registed style output to ensure the success signal "isANNN", "isL" and "isP" are strictly one clock cycle.
	--Also, to avoid gliches.
	update:
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				current_state <= idle;
			else
				current_state <= next_state;
			end if;
		end if;
	end process;
	
	output_logic:
	process(current_state, enable, command)
	begin
		--Assign first, to avoid latch.
		isANNN <= '0';
		isL <= '0';
		isP <= '0';
		
		if enable = '1' then
			if command = ascii_l or command = ascii_l_cap then
				isANNN <= '0';
				isL <= '1';
				isP <= '0';
			elsif command = ascii_p or command = ascii_p_cap then
				isANNN <= '0';
				isL <= '0';
				isP <= '1';
			end if;
			
			if current_state = ANN then
				if command >= ascii_0 and command <= ascii_9 then
					isANNN <= '1';
					isL <= '0';
					isP <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture;

/*
Firstly drafted on a certain day in early Feburary.

Updated on 26/02/2026:
Commitment:
	Change style from Moore one to Mealy one.
	At this stage, the function works as expected.
	However, there are gliches among outputs, can be later solved by:
		1. Clocked Mealy FSM output to stablise output every clocking posedge
		2. A fully guaranteed up-stream input.
	Currently, not sure if the first solution and enable signal couple well or not.
	Also, a limited coverage is conducted, enable signal is not considered.
*/