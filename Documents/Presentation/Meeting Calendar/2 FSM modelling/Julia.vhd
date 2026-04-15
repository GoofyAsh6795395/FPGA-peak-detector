
LIBRARY ieee;

USE ieee.std_logic_1164.ALL;
 
--Information from the wave in simulation:
--Maybe problem of state_transition (especially s1 to s2)
--Maybe problem in output logic?
--Take care of garbge value and avoid them by assigning an initial one.
--


 
entity julia is

  port (

   clk    : in  std_logic;

   output : out integer

  );

end entity;
 
Architecture rtl of julia is 

type state_t is (S0, S1, S2, S3);

  signal current_state, next_state: state_t;

  signal counter,counter_next:integer;

begin

---:

process(current_state,counter_next)

begin
	
      case current_state is

	when S0 =>

		next_state <= S1;
 
	when S1=>

		if counter >= 6 then

		next_state <= S2;  

			counter_next <= counter+1;      

		else
			
        		next_state <= current_state;
		-- And how about the counter here?
		end if;

	when S2=>

		if counter >= 10 then

			next_state <= S3;  

			counter_next <= counter+1;      

		else

			next_state <= current_state;    

		end if;

	when others =>  

			next_state <= S0;      

	end case;

end process;

---



process(clk)

begin

	if rising_edge(clk) then
	-- What about counter...

		current_state <= next_state;

	end if;

end process;

-----

process(current_state)

begin

		if current_state <= S0 then output <=0; end if;

		if current_state <= S1 then output <=1; end if;

		if current_state <= S2 then output <=2;

		else output <= 3;

		end if;

end process;

end architecture;
 