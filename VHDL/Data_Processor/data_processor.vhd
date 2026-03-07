library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity dataConsume is
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

architecture synth of dataConsume is
	type stateType is (idle, request, processing, response);
	type memory is array (0 to 6) of STD_LOGIC_VECTOR(7 downto 0);
	signal buf, buf_next: memory := (others => (others => '0'));
	signal result, result_next: memory := (others => (others => '0'));

	signal current_state, next_state: stateType := idle;

	signal finished, finished_reg: STD_LOGIC := '1';	--The initial value must be set to 1, it means no work is unfinished without doing any operation.
	signal NNN, NNN_reg: integer := 0;

	signal max, max_index: integer := 0;
	signal max_reg, max_index_reg: integer := 0;
	signal counter, counter_next: integer := 0;
		--Based on the update condition of counter, this signal means which number is currently being processed.
		--Thus, its valid value ranges from 1, 2, 3, ...., NNN

	signal ctrl2_delayed: STD_LOGIC;
	signal ctrl1_reg: STD_LOGIC := '0';
		--To flip ctrl1, a register must be required to store the latest value.

begin
	--Always connect the output of ctrl_1 register to port ctrl1.
	ctrl1 <= ctrl1_reg;

	--Whether the data on byte port should be received by down-stream or not is determined by dataReady signal.
	--Therefore, dataReady should still be 0 for the case when current state is "response" but counter less than 3.
	byte <= buf(3);

	dataResults(55 downto 48) <= result(0);
	dataResults(47 downto 40) <= result(1);
	dataResults(39 downto 32) <= result(2);
	dataResults(31 downto 24) <= result(3);
	dataResults(23 downto 16) <= result(4);
	dataResults(15 downto 8) <= result(5);
	dataResults(7 downto 0) <= result(6);

	integer_to_BCD:
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
	process(current_state, start, counter, ctrl2_delayed, ctrl2, NNN)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>
				if start = '1' then
					next_state <= request;
				end if;
			when request =>
				if (ctrl2 xor ctrl2_delayed) = '1' then		--It means that ctrl2 is toggled.
					next_state <= processing;
				else
					next_state <= request;
				end if;
			when processing =>
				next_state <= response;
			when response =>
				next_state <= idle;
			when others =>
				next_state <= idle;
		end case;
	end process;

	--In datapath process, the counter_next, buf_next, result_next, max_reg, finished_reg 
	datapath:
	process(current_state, NNN, counter, finished, max, max_index, buf, result, data, numWords, start, buf_next, max_reg)
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
		
		--For single cycle pulse, namely, pull down if a certain condition is not met.
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
				if counter >= 1 and counter <= NNN then
					buf_next(6) <= data;
				elsif counter > NNN and counter <= (NNN + 3) then
					buf_next(6) <= "10000000";
				end if;

				if counter = (NNN + 3) then
					--Finished both processing NNN generated data and padding extra 3 ones.
					finished_reg <= '1';
				end if;
				
				--Check if max value is found or not.
				--Don't check it if counter = (1, 2, 3)
				--The counter's interval of possible max emerge is from 3 to NNN+3;
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
					if max < signed(buf_next(3)) then
						--Max value and index should be updated.
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
				--It means that waht's currently on the port "byte" is the actual generated value.
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
				ctrl1_reg <- '0';
				
				max_index <= 0;
				max <= 0;
				buf <= (others => (others => '0'));
				result <= (others => (others => '0'));
				current_state <= idle;
				--Initialise
			else
				buf <= buf_next;
				max <= max_reg;
				max_index <= max_index_reg;
				ctrl2_delayed <= ctrl2;
				counter <= counter_next;
				finished <= finished_reg;
				NNN <= NNN_reg;
				result <= result_next;
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
--Firstly drafted on 24/02/2026:
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
--	1. A corresponding ASM chart may be required.
--		Try Microsoft Visio.
--	2. Try HLS(High Level Synthesis)! to have a double check.
--End commitment;
--
--Modified on 26/02/2026:
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
--Problems identified at 2pm, 03/03/2026:
--	The buffer is forgetten to not update, already correct.
--	Rename: max_index, max_value, max_value_reg.
--	State transition is forgetten in clocked process, corrected.
--	Line 174, should use signal "finished_reg" instead of "finished" here.
--	To optimise:
--		Indicate the range of every integer to save resources and improve possible delay.
--		Code can be simplified to enhance the readability.
--		The integer-BCD conversion can be more elegant by shift operatior.
--   
--Modified at 6pm, 03/03/2026:
--	The name of entity and ports, their respective dataType is required changing to match the testbench's.
--  
--Suggestions at 7pm, 03/03/2026:
--	The finished signal should be totally moved in the clock process
--		A. It's used only twice and doesn't rely on a complicated condition.
-- 		B. To decrease the number of internal signals is to decrease complexity.
--	Similar reason and action is suggested taking on the signal "counter"
--	The maxIndex name should be changed to avoid the conflict between internal signals and output port.
--
--Modified at 8pm, 03/03/2026:
--	Multiple-drive problem of ports is solved.
--		Reported by Vivado.
--	The result is forgetten updating in clocking process, corrected.
--	Spotted in Vivado Messages: drive by constant 0.
--
--Thoughts at 10pm, 03/03/2026:
--	To optimise timing & delay
--		1. Expand the if-elsif chain to avoid cascaded LUT.
--			Lots of time the we don't need priority information.
--		2. Decrease fan in/out to make the equivalent capacitor smaller
--			Thus, the slew rate is increased.
--			Especially the integer type, indicate it's range.
--		3. The arithmetic operations, decrease the bitwidth
--			To avoid carry-ripple-adder as I remember?
--
--Modified at 3pm, 04/03/2026:
--	Corrected the timing-loop of combinational logic of signal "max".
--		Notified by Vivado.
--
--Suggestions at 23pm, 04/03/2026:
--	To correct the port type and their name.
--	To indicate the integer range
--	To simplify the if-elsif logic
--	To simplify the vector-assignment logic
--	Awaiting finishing in next group work session expected on 10th, March.
--
--Modified on 05/03/2026:
--	Ths nasty indentation generated by Vivado is corrected.
--		Maybe do not use Vivado editor to make changes on code anymore.
--
--Commitment at 6pm, 06/03/2026:
--	Condition on line 91, namely, determining the next_state by counter, maybe result in off by one error.
--		Considering where the counter updates?
--		If the counter is updated within a certain state:
--			The next_state process is happening concurrently.
--			But it's new value cannot be read out, in the next_state logic.
--		Two solutions:
--			A. Use an off-by-one condition.
--			B. Use counter_next to check ahead.
--		Here, I will select A, because the state transition logic in essence also the update logic of dependent signal "counter":
--			This is something referred to as combinational loop if
--			we use the value of voltage level "counter_next" to determine it's new value. 
--			Maybe not severe as I think, but it's better to avoid it.
--	Actually, the procedure now is totally wrong and I'll give related commits once corrected.
--
--Updated at 7pm, 06/03/2026:
--	The problem now is, during the final stage of padding three extra value, the state cannot always be the "processing" one 
--	for the purpose of printing last three numbers.
--	I think, perhaps we don't a explicit stall of printing system.
--		Just keep working, until an iteration of NNN + 3 is accompolished.
--	Thus, the current state-transition logic is, turn to "response" unconditionally as the next one of "processing".
--	Because we don't stay in processing state for extra three cycles any more,
--		The redundant counter update within "processing" is also correspondingly removed.
--
--	The counter logic:
--	Since we're using (++ counter) instead of (counter ++).
--	In other words, counter is updated before checked, so it has no chance to be "0" in every comparison.
--	That's the reason I changed the iteration condition.
--
--Updated at 8pm, 06/03/2026:
--	Rename the entity to match the component name is testbench.
--	Setup and hold slack now: 3.59ns, 0.139ns.
--
--Updated at 9pm, 06/03/2026:
--	The reset logic of ctrlOut signal is added.
--	No need to worry about the circumstance that a toggle is mistakenly detected by down-stream data generator when the ctrlOut is '1' before reset and '0' after.
--		Since I have checked the down-stream design and found it has also flush the registered my ctrlOut by '0'.
--
--Suggestions on 07/03/2026:
--	Consider the assignments in processing state.
--	Seems that there is a servere combinational dependent logic and it exactly forms the critical path.
--	In other words, cascaded, and i don't find its necessity.