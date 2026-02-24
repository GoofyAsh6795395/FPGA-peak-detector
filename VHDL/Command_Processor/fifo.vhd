library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity fifo is
	port(
		reset: in STD_LOGIC;
		clk: in STD_LOGIC;
		enqueue: in STD_LOGIC;
		dequeue: in STD_LOGIC;
		isEmpty: out STD_LOGIC;
		data_in: in STD_LOGIC_VECTOR (7 downto 0);
		data_out: out STD_LOGIC_VECTOR (7 downto 0)
	);
end entity;

architecture synth of fifo is
	--Declare the fifo type and  
	type memory_type is  array (0 to 7) of STD_LOGIC_VECTOR (7 downto 0);
	signal memory: memory_type;
	signal head, tail: integer range 0 to 7 := 0;
	signal head_reg, tail_reg: integer range 0 to 7 := 0;
	signal counter, counter_reg: integer range 0 to 7 : = 0;
begin
	data_out <= memory(head);
	isEmpty <= '1' when counter = 0 else '1';

	counter_update:
	process
		
	begin

	end process;
	
	readLogic:
	process
	begin

	end process;

	push_pop_logic:
	process(clk, reset)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				head <= 0;
				tail <= 0;
				counter <= 0;
			else
				if(enqueue = '1')then
					--New data will be dumped if fifo is full.
					--Take care of the combinational loop here, don't use counter_next signal.
					if counter < 8 then
						memory(tail) <= data_in;
						tail <= (tail + 1) mod 8;
					end if;
				end if;
				
			end if;
		end if;
	end process;

end architecture;