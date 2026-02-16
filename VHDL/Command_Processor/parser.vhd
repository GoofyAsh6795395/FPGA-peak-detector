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
	type recorded is (idle, A, AN, ANN, ANNN, L, P);
	signal current_state, next_state: recorded := idle;

	constant ascii_a: STD_LOGIC_VECTOR (7 downto 0) := x"61";
	constant ascii_a_cap: STD_LOGIC_VECTOR (7 downto 0) := x"41";
	constant ascii_l: STD_LOGIC_VECTOR (7 downto 0) := x"6C";
	constant ascii_l_cap: STD_LOGIC_VECTOR (7 downto 0) := x"4C";
	constant ascii_p: STD_LOGIC_VECTOR (7 downto 0) := x"50";
	constant ascii_p_cap: STD_LOGIC_VECTOR (7 downto 0) := x"70";
	constant ascii_0: STD_LOGIC_VECTOR (7 downto 0) := x"30";
	constant ascii_9: STD_LOGIC_VECTOR (7 downto 0) := x"39";

	signal ANNN_found, L_found, P_found: STD_LOGIC := '0';
	signal ANNN_next, L_next, P_next: STD_LOGIC := '0';
begin
	next_state_logic:
	process(enable, command, current_state)
	begin
		next_state <= current_state;
		if enable = '1' then
			case current_state is
			when idle =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				else
					next_state <= idle;
				end if;
			when A =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				elsif command >= ascii_0 and command <= ascii_9
					then next_state <= AN;
				else
					next_state <= idle;
				end if;
			when AN =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a 
					then next_state <= A;
				elsif command >= ascii_0 and command <= ascii_9
					then next_state <= ANN;
				else
					next_state <= idle;
				end if;
			when ANN =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				elsif command >= ascii_0 and command <= ascii_9
					then next_state <= ANNN;
				else
					next_state <= idle;
				end if;
			when ANNN =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				else
					next_state <= idle;
				end if;
			when L =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				else
					next_state <= idle;
				end if;
			when P =>
				if command = ascii_l or command = ascii_l_cap
					then next_state <= L;
				elsif command = ascii_p or command = ascii_p_cap
					then next_state <= P;
				elsif command = ascii_a_cap or command = ascii_a
					then next_state <= A;
				else
					next_state <= idle;
				end if;
			when others =>
				next_state <= idle;
			end case;
		end if;
	end process;

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
	process(current_state, enable)
	begin
		if enable = '0' then
			isANNN <= '0';
			isL <= '0';
			isP <= '0';
		else
			case current_state is
			when idle =>
				isANNN <= '0';
				isL <= '0';
				isP <= '0';
			when A =>
				isANNN <= '0';
				isL <= '0';
				isP <= '0';
			when AN =>
				isANNN <= '0';
				isL <= '0';
				isP <= '0';
			when ANN =>
				isANNN <= '0';
				isL <= '0';
				isP <= '0';
			when ANNN =>
				isANNN <= '1';
				isL <= '0';
				isP <= '0';
			when L =>
				isANNN <= '0';
				isL <= '1';
				isP <= '0';
			when P =>
				isANNN <= '0';
				isL <= '0';
				isP <= '1';
			end case;
		end if;
	end process;
end architecture;