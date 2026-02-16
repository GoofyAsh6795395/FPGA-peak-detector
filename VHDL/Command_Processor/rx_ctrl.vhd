library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity fifo is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;

		valid: in STD_LOGIC;
		oe: in STD_LOGIC;
		fe: in STD_LOGIC;
		
		data_in: in STD_LOGIC_VECTOR (7 downto 0);
		data_out: out STD_LOGIC_VECTOR (7 downto 0);
		
		echo: out STD_LOGIC;
		transmitted: in STD_LOGIC;
		done: out STD_LOGIC
	);
end entity;

architecture synth of fifo is
	signal data_reg, data_reg_new: STD_LOGIC_VECTOR (7 downto 0);
	type state is (idle, receive, dispatch);
	signal current_state, next_state: state;
begin
	next_state_logic:
	process(current_state, valid)
	begin
		next_state <= current_state;
		data_reg_new <= data_reg;
		case current_state is
			when idle =>
				if valid = '1' then
					next_state <= receive;
				else
					next_state <= idle;
				end if;
			when receive =>
				next_state <= dispatch;
				data_reg_new <= data_in;
			when dispatch =>
				if transmitted = '1' then
					next_state <= idle;
				else
					next_state <= dispatch;
				end if;
		end case;
	end process;
	
	output_logic:
	process(current_state)
	begin
		done <= '0';
		data_out <= "00000000";
		echo <= '0';
		case current_state is
			when idle =>
				
			when receive =>
				done <= '1';
			when dispatch =>
				echo <= '1';
				data_out <= data_reg;
		end case;
	end process;
	
	update:
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				data_reg <= "00000000";
				current_state <= idle;
			else
				data_reg <= data_reg_new;
				current_state <= next_state;
			end if;
		end if;
	end process;
end architecture;