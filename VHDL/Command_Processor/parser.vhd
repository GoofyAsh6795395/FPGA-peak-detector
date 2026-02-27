library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity parser is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;
		command: in STD_LOGIC_VECTOR (7 downto 0);
		enable: in STD_LOGIC;

		NNN: out STD_LOGIC_VECTOR(11 downto 0);		--BCD encoding is used.

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

	signal NNN_reg: STD_LOGIC_VECTOR(11 downto 0);

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
	NNN <= NNN_reg;

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
	
	clock_controlled_datapath:
	process(clk, reset, current_state, enable, command)
		variable command_bcd: STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	begin
		if rising_edge(clk) then
			if reset = '1' then
				NNN_reg <= (others => '0');	--Use aggregate style assignment.
				isANNN <= '0';
				isL <= '0';
				isP <= '0';
			else
				--Assign first, to keep exactly one cycle pulse output.
				isANNN <= '0';
				isL <= '0';
				isP <= '0';
		
				if enable = '1' then
					--Let's count the cycles to check how output is effected by enable.
					--At k clocking edge, enable gets high level, start detecting
					--At k+1 clocking edge, enable gets low, but the output will be seriously cleaned at K+2 clock period.
					--However, the output is already determined at K+1 cycle, and it will successfully propagate.
					
					if command = ascii_l or command = ascii_l_cap then
						isANNN <= '0';
						isL <= '1';
						isP <= '0';
					elsif command = ascii_p or command = ascii_p_cap then
						isANNN <= '0';
						isL <= '0';
						isP <= '1';
					end if;

					--Encode BCD code firstly.
					--Command is encoded by binary ascii code, with bitwidth of 8.
					--Hint: the last 4 digits of ascii code of a number is coinsidently its binary.
					command_bcd := command(3 downto 0);

					case current_state is
						when idle =>
							NNN_reg <= (others => '0');		--Flush the recorded data if NNN sequence is interrupted.
						when A =>
							if command >= ascii_0 and command <= ascii_9 then
								NNN_reg(11 downto 8) <= command_bcd;
							else
								NNN_reg <= (others => '0');	--Flush.
							end if;
						when AN =>
							if command >= ascii_0 and command <= ascii_9 then
								NNN_reg(7 downto 4) <= command_bcd;
							else
								NNN_reg <= (others => '0');	--Flush.
							end if;
						when ANN =>
							if command >= ascii_0 and command <= ascii_9 then
								isANNN <= '1';
								isL <= '0';
								isP <= '0';

								NNN_reg(3 downto 0) <= command_bcd;
							else
								NNN_reg <= (others => '0');	--Flush.
							end if;
					end case;
				else				--Not enabled.
					isANNN <= '0';
					isL <= '0';
					isP <= '0';
				end if;

			end if;
		end if;
	end process;
end architecture;


--Log:
--Firstly drafted on a certain day in early Feburary.
--
--Updated on 26/02/2026:
--Commitment:
--	Change style from Moore one to Mealy one.
--	At this stage, the function works as expected.
--	However, there are gliches among outputs, can be later solved by:
--		1. Clocked Mealy FSM output to stablise output every clocking posedge
--		2. A fully guaranteed up-stream input.
--	Currently, not sure if the first solution and enable signal couple well or not.
--	Also, a limited coverage is conducted, enable signal is not considered.
--
--Spotted at 2pm, 27/02/2026:
--	A output databus is required to tell what's specifically NNN is.
--	Enable signal is not tested yet.
--	As mealy machine, the success signal is send immediately once condiction is met.
--	However, the register will have one cycle latency to read out.
--	Maybe make the success signal to be also an output of a register will solve, I'll have a try.
--
--Modified at 3pm, 27/02/2026:
--	Correspondingly change the pulse style, and add the NNN output.
--	Compile successfully, not tested.
--
--Commitment at 3.30pm, 27/02/2026
--	Roughly tested, identified that BCD sequence is reversed.
--	Already corrected this error and work in order.
--	More test may be better.