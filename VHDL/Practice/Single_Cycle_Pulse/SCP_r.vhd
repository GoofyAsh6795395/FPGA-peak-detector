------260218
library ieee;
use ieee.std_logic_1164.all;
 
entity fsm is 
	port(
		clk: in std_logic;
		input: in std_logic;
		output : out std_logic
);
end entity;
 
 
architecture sim of fsm is
type state is (r1,r2);
signal cur_state, next_state :state;
begin
process(clk)
	begin
		if rising_edge(clk) then
			cur_state <= next_state;
		end if;
	end process;	

process(cur_state, input)
begin 
	case cur_state is
	when r1 =>
		if input = '1' then
			next_state <= r2;
		else 
			next_state <= r1;
		end if;
	when r2 => next_state <=r2;
	when others => next_state <=r1;
	end case;
end process;

process(cur_state,input,clk)
begin
	if rising_edge(clk) then
		if cur_state <= r1 and input = '1' then output <= '1';
		else output <= '0';end if;
	end if;
end process;
end architecture;
 
 
architecture sim of fsm is
type state is (r1,r2);
signal cur_state, next_state :state;
signal sent : std_logic := '0';
begin
	process(clk)
	begin
		if rising_edge(clk) then
			cur_state <= next_state;
		end if;
	end process;	
 
	process(cur_state, input)
	begin 
		case cur_state is
			when r1 =>
				if input = '1' then
					next_state <= r2;
				else 
					next_state <= r1;
				end if;
			when r2 => next_state <=r2;
			when others => next_state <=r1;
		end case;
	end process;
 
	process(cur_state,input,clk)
	begin
		if rising_edge(clk) then
			if cur_state <= r2 then
				if sent = '0' then
					output <= '1';
					sent <= '1';
					--Great chioce to assign the "sent" variable here in the clocked process, but why?
				end if;
			else output <= '0';end if;
		end if;
	end process;
end architecture;

--Classical implementation of single-cycle-pulse, well done.
--However, do not use same name for multiple architectures.
architecture sim of fsm is
type state is (r1,R,r2);
signal cur_state, next_state :state;
signal sent : std_logic := '0';
begin
	process(clk)
	begin
		if rising_edge(clk) then
			cur_state <= next_state;
		end if;
	end process;	

	process(cur_state, input)
	begin 
		case cur_state is
			when r1 =>
				if input = '1' then
					next_state <= R;
				else 
					next_state <= r1;
				end if;
			when R => next_state <= r2;
			when r2 => next_state <=r2;
			when others => next_state <=r1;
		end case;
	end process;

	process(cur_state,input)
	begin
		if cur_state = R then
            		output <= '1';
		else output <= '0';
		end if;
	end process;
end architecture;
