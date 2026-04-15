library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity renyuan is 
	port(
		clk : in STD_LOGIC;
		output : out integer
	);
end entity;
 
architecture sim of renyuan is
	type state is (s0, s1, s2, finished);
    	signal current_state, next_state : state := s0;
	signal cnt, cnt_next : integer := 0;
 
begin
 
	update: process(clk)
	begin
		if rising_edge(clk) then
			current_state <= next_state;
			cnt <= cnt_next;
		end if;
	end process;
	next_state_logic: process(current_state, cnt)  
	begin
	-- No initial value assigned
		case current_state is
			when s0 => 
				next_state <= s1;
			when s1 => 
				if cnt > 7 then next_state <= s2; 
				end if;
			--No other branch indicated, not closure actually.
			when s2 => 
				if cnt >11 then next_state <= finished; 
				end if;
			when finished => 
				next_state <= s0;
			when others => 
				next_state <= s0;
		end case;
	end process;
		
	counter_logic: process(current_state, cnt) 
	begin
		case current_state is 
			when s0	=> cnt_next <= 1; 
				output <= 0;
			when s1 => 
				--Equal or less than ????
				if cnt<=7 then cnt_next <=cnt +1;
				else cnt_next <= cnt + 1; --????
				end if;
				output <=0;
			when s2 =>
				if cnt <= 11 then cnt_next <=cnt +1;
				else cnt_next <= cnt + 1; --Same
				end if;
				--Some problem seems to be here?
				output <= 0;
			when finished => cnt_next <= 0; output <=1;
			when others => output <=0;
		end case;
	end process;
end architecture;
