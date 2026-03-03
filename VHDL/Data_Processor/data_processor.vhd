library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity data_processor is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;

		--To dataGen:
		ctrl1: out STD_LOGIC;
		ctrl2: in STD_LOGIC;
		data: in STD_LOGIC_VECTOR(7 downto 0);
		
		--To cmdProc:
		start: in STD_LOGIC;
		numWords: in STD_LOGIC_VECTOR(11 downto 0);
		seqDone: out STD_LOGIC;
		dataReady: out STD_LOGIC;

		--Data:
		maxIndex: out STD_LOGIC_VECTOR(11 downto 0);	--BCD encoding
		dataResults: out STD_LOGIC_VECTOR(55 downto 0);	--Binary sequence, using 2's complement
		byte: out STD_LOGIC_VECTOR(7 downto 0)
	);
end entity;

architecture synth of data_processor is
	type stateType is (idle, request, processing, response);
	type memory is array (0 to 6) of STD_LOGIC_VECTOR(7 downto 0);
	signal buf, buf_next: memory := (others => (others => '0'));
	signal result, result_next: memory := (others => (others => '0'));

	signal current_state, next_state: stateType := idle;
	signal ctrl2_delayed: STD_LOGIC;
	signal finished, finished_reg: STD_LOGIC := '1';
	signal NNN, NNN_reg: integer := 0;

	signal max, max_index: integer := 0;
	signal max_reg, max_index_reg: integer := 0;
	signal counter, counter_next: integer := 0;
	signal ctrl1_reg: STD_LOGIC := '0';
		--To flip ctrl1, a register must be required to store the latest value.

begin
	--Always connect the output of ctrl_1 register to port ctrl1.
	ctrl1 <= ctrl1_reg;

	--If the data on byte port is received by down-stream is determined by dataReady signal.
	--Therefore, dataReady should still be 0 for the case when current state is "response" but counter less than 3.
	byte <= buf(3);

	dataResults(55 downto 48) <= result(0);
	dataResults(47 downto 40) <= result(1);
	dataResults(39 downto 32) <= result(2);
	dataResults(31 downto 24) <= result(3);
	dataResults(23 downto 16) <= result(4);
	dataResults(15 downto 8) <= result(5);
	dataResults(7 downto 0) <= result(6);

	BCD_convert:
	process(max_index)
	variable hundreds, tens, ones: integer := 0;
	--Used to convert the integer of max index to BCD.
	begin
		hundreds := (max_index / 100) mod 10;
		tens := (max_index / 10) mod 10;
		ones := max_index mod 10;
		maxIndex(11 downto 8) <= std_logic_vector(to_unsigned(hundreds, 4));
		maxIndex(7 downto 4) <= std_logic_vector(to_unsigned(tens, 4));
		maxIndex(3 downto 0) <= std_logic_vector(to_unsigned(ones, 4));
	end process;

	state_transition_logic:
	process(current_state, start, counter, ctrl2_delayed, ctrl2)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>
				if start = '1' then
					next_state <= request;
				end if;
			when request =>
				if (ctrl2 xor ctrl2_delayed) = '1' then
					next_state <= processing;
				else
					next_state <= request;
				end if;
			when processing =>
				if counter >= NNN and counter < (NNN + 3) then
					--stall.
					next_state <= processing;
				else
					next_state <= response;
				end if;
			when response =>
				next_state <= idle;
			when others =>
				next_state <= idle;
		end case;
	end process;

	--In datapath process, the counter_next, buf_next, result_next, max_reg, finished_reg 
	datapath:
	process(current_state, NNN, counter, finished, max, max_index, buf, result, data, numWords)
	variable ones, tens, hundreds: integer := 0;
		--Used to slice the input BCD numwords.
	begin
		--Avoid latch inference.
		ones := 0;
		tens := 0;
		hundreds := 0;
		NNN_reg <= NNN;
		counter_next <= counter;
		finished_reg <= finished;

		max_reg <= max;
		max_index_reg <= max_index;

		buf_next <= buf;
		result_next <= result;
		
		--For single cycle pulse.
		dataReady <= '0';
		seqDone <= '0';
		
		case current_state is
			--Explicitly indicating the behaviour under other state is also required.
			--To satisfy the syntax check, use "null";
			when idle =>
				if start = '1' then
					if finished = '1' then
						--This means that, the last cycle is end and now a new cycle start.
						finished_reg <= '0';

						--Flush the stored data
						counter_next <= 0;
						max_reg <= 0;
						max_index_reg <= 0;
						result_next <= (others => (others => '0'));
						buf_next <= (others => (others => '0'));
						
						--Slice BCD
						hundreds := to_integer(unsigned(numWords(11 downto 8)));
						tens := to_integer(unsigned(numWords(7 downto 4)));
						ones := to_integer(unsigned(numWords(3 downto 0)));
						NNN_reg <= (hundreds * 100 + tens * 10 + ones);
					else
						counter_next <= counter + 1;
					end if;
				end if;
			when request => 
				null;
			when processing =>
				--Shift the buffer by one.
				buf_next(0) <= buf(1);
				buf_next(1) <= buf(2);
				buf_next(2) <= buf(3);
				buf_next(3) <= buf(4);
				buf_next(4) <= buf(5);
				buf_next(5) <= buf(6);

				--Append the retrieved data or padding value.
				if counter >= 0 and counter < NNN then
					buf_next(6) <= data;
				elsif counter >= NNN and counter < (NNN + 3) then
					buf_next(6) <= "10000000";
					--Consider later, 03/03/2026.
					counter_next <= counter + 1;
				end if;

				if counter = (NNN + 3) then
					--Finished both processing NNN data and padding extra 3.
					finished_reg <= '1';
				end if;
				
				--Check if max value is found or not.
				if counter = 4 then
					--First number case: initialise everything.
					max_reg <= to_integer(signed(buf_next(3)));
					max_index_reg <= 0;
					--Initialise result buffer and max_value;
					--What's contained in buf_next: (0, 0, 0, 1st_val, 2nd_val, 3rd_val, 4th_val).
					result_next(0) <= buf_next(0);
					result_next(1) <= buf_next(1);
					result_next(2) <= buf_next(2);
					result_next(3) <= buf_next(3);
					result_next(4) <= buf_next(4);
					result_next(5) <= buf_next(5);
					result_next(6) <= buf_next(6);

				elsif counter > 4 then
					if max_reg < signed(buf_next(3)) then
						--Max value updated.
						max_reg <= to_integer(signed(buf_next(3)));
						max_index_reg <= counter - 4;

						result_next(0) <= buf_next(0);
						result_next(1) <= buf_next(1);
						result_next(2) <= buf_next(2);
						result_next(3) <= buf_next(3);
						result_next(4) <= buf_next(4);
						result_next(5) <= buf_next(5);
						result_next(6) <= buf_next(6);
					end if;
				end if;
					
			when response =>
				if counter >= 4 then 
					dataReady <= '1';
				end if;
				if finished = '1' then
					seqDone <= '1';
				end if;
		end case;
	end process;
		
	clock:
	process(clk, reset, current_state, max_reg, ctrl2, counter_next, finished_reg, NNN_reg, ctrl1_reg)
	--To avoid mistakes in simulation, put every signal involved in RHS of assignment and conditions, into the sensitivity list.
	begin
		if rising_edge(clk) then
			if reset = '1' then
				NNN <= 0;
				finished <= '0';
				counter <= 0;
				ctrl2_delayed <= '0';
				
				dataResults <= (others => '0');
				max_index <= 0;
				max <= 0;
				result <= (others => (others => '0'));
				buf <= (others => (others => '0'));
				current_state <= idle;
				--Initialise
			else
				--If reset is considered...
				buf <= buf_next;
				max <= max_reg;
				max_index <= max_index_reg;
				ctrl2_delayed <= ctrl2;
				counter <= counter_next;
				finished <= finished_reg;
				NNN <= NNN_reg;
				current_state <= next_state;
				
				if current_state = idle and start = '1' then
					ctrl1_reg <= not ctrl1_reg;
					--Ctrl1 would be delayed by one cycle, check it later.
				end if;
			end if;
			
		end if;
	end process;
end architecture;


--
--Log:
--
--Firstly drafted on 24/02/2026
--Commitment:
--	Please take actions on:
--	1. Reset manipulations...
--	2. Data type of maxIndex, maxValue and their corresponding registered signal.
--			Whether binary vector or integer?
--			How will it be compared with number from buffer?
--	3. Integer -> BCD while send the result and data back, ranging from index, byte and result...
--	4. How to initialise memory grid to be 0, 0, ....
--	5. Check sensitivity list, from datapath to state-transition logic.
--	6. Assign in advance at each process to avoid latch inferrence, including the memory grid.
--	7. Don't forget to update every registered signal at clock rising_edge.
--	8. Naming suffix: REG or NEXT?
--	9. How to toggle ctrl1 signal? (current one doesn't work because...)
--	10. Check boundary conditions...
--	11. Avoid multiple drive.
--	12. Take care of combinational loop...
--	13. Priority: Byte signal is not used at all.
--	
--	Other suggestions beyond code:
--	1. A corresponding ASM chart maybe required.
--		Try Microsoft Visio.
--	2. Try HLS(High Level Synthesis)! to have a double check.
--End commitment;
--
--Modified on 26/02/2026
--Commitment:
--	Correct the commit style to satisfy IDE requirement.
--
--Reminder on 28/02/2026:
--	Take care of the variables, they may also cause latch inferrence if assigned not properly.
--	Please use a better naming logic instead of taking time on distinguishing their suffix.
--
--Checked on 02/03/2026:
--	Check line 116, 132, 165 is this right?
--	Which process and state do you want to drive counter?
--
--Corrections at 11am, 03/03/2026:
--	Conditionally send dataReady.
--	Byte is now connected.
--
--Problems identified at 2pm, 03/03/2026
--	The buffer is forgetten to not update, already correct.
--	Rename: max_index, max_value, max_value_reg.
--  State transition is forgetten in clocked process, corrected.
--  Line 174, should use signal "finished_reg" instead of "finished" here.
--  To optimise:
--      indicate the range of every integer to save resources and improve possible delay.
--      Code can be simplified to enhance the readability.

