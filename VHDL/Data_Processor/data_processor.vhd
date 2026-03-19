library IEEE;
use work.common_pack.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity dataConsume is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;

		--To dataGen:
		ctrlOut: out STD_LOGIC;
		ctrlIn: in STD_LOGIC;
		data: in STD_LOGIC_VECTOR(7 downto 0);
		
		--To cmdProc:
		start: in STD_LOGIC;
		numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
		seqDone: out STD_LOGIC;
		dataReady: out STD_LOGIC;

		--Data:
		maxIndex: out BCD_ARRAY_TYPE(2 downto 0);	--BCD encoding
		dataResults: out CHAR_ARRAY_TYPE(0 to 6);	--Binary sequence, using 2's complement
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
	signal NNN, NNN_reg: integer range 0 to 1000 := 0;

	signal max, max_reg: integer range -256 to 255 := 0;
		--The range is indicated to be exactly same with how large/small a 8 bit 2's complement signed integer could be.
	signal max_index, max_index_reg: integer range 0 to 1000 := 0;
	
	signal counter, counter_next: integer range 0 to 1000 := 0;
		--Based on the update condition of counter, this signal means which number is currently being processed.
		--Thus, its valid value ranges from 1, 2, 3, ...., NNN

	signal ctrlIn_delayed: STD_LOGIC;
	signal ctrlOut_reg: STD_LOGIC := '0';
		--To flip ctrl1, a register must be required to store the latest value.
	signal start_reg: STD_LOGIC := '0';
	signal data_reg: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin
	--Always connect the output of ctrl_1 register to port ctrl1.
	ctrlOut <= ctrlOut_reg;

	--Whether the data on byte port should be received by down-stream or not is determined by dataReady signal.
	--Therefore, dataReady should still be 0 for the case when current state is "response" but counter less than 3.
	byte <= buf(6);

	dataResults(6) <= result(0);
	dataResults(5) <= result(1);
	dataResults(4) <= result(2);
	dataResults(3) <= result(3);
	dataResults(2) <= result(4);
	dataResults(1) <= result(5);
	dataResults(0) <= result(6);
	--Based on our assignment style of "buf" or "result", it hints that the latest number is stored in 
	--the final index of this array.
	--Namely, 

	integer_to_BCD:
	process(max_index)
		variable hundreds, tens, ones: integer range 0 to 10 := 0;
		--Used to convert the integer of max index to BCD.
	begin
		hundreds := (max_index / 100) mod 10;
		tens := (max_index / 10) mod 10;
		ones := max_index mod 10;
		maxIndex(2) <= std_logic_vector(to_unsigned(hundreds, 4));
		maxIndex(1) <= std_logic_vector(to_unsigned(tens, 4));
		maxIndex(0) <= std_logic_vector(to_unsigned(ones, 4));
		--Thus, following the code convention of university, the LSB of this integer is placed at index 0 of this container.
	end process;

	state_transition_logic:
	process(current_state, start, counter, ctrlIn_delayed, ctrlIn, NNN)
	begin
		next_state <= current_state;
		case current_state is
			when idle =>
				if start_reg = '0' and start = '1' then
					next_state <= request;
				end if;
			when request =>
				if (ctrlIn xor ctrlIn_delayed) = '1' then		--It means that ctrl2 is toggled.
					next_state <= processing;
				else
					next_state <= request;
				end if;
			when processing =>
				next_state <= response;
				--Unconditionally transfer to response state.
				--Since a respective operation must be conducted after one processing logic.
			when response =>
				--The counter here has a steady value, just use it.
				if counter >= NNN and counter < (NNN + 3) then
					--This means, retrieve number is finished and now, 
					--We cannot go back to idle state, instead, stall at processing state for three cycles.
					next_state <= processing;
				else
					next_state <= idle;
				end if;
			when others =>
				next_state <= idle;
		end case;
	end process;

	--In datapath process, the counter_next, buf_next, result_next, max_reg, finished_reg 
	datapath:
	process(current_state, NNN, counter, finished, max, max_index, buf, result, data, numWords_bcd, start, buf_next, max_reg)
		variable ones, tens, hundreds: integer range 0 to 10 := 0;
		--Used to slice the input BCD numwords.
		variable value_cmp: integer range -256 to 255 := 0;
		variable vector_append: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	begin
		--Avoid latch inference.
		ones := 0;
		tens := 0;
		hundreds := 0;
		
		value_cmp := 0;
		vector_append := (others => '0');
		
		NNN_reg <= NNN;
		counter_next <= counter;
		finished_reg <= finished;

		max_reg <= max;
		max_index_reg <= max_index;

		buf_next <= buf;
		result_next <= result;
		
		--For single cycle pulse, namely, pull down if a certain condition is not met.
		dataReady <= '0';
		
		case current_state is
			--Explicitly indicating the behaviour under other state is also required.
			--To satisfy the syntax check, use "null";
			when idle =>
				if finished = '1' then
					if start = '1' then
						--This means that, the last cycle is end and now a new NNN cycle starts.
						finished_reg <= '0';

						--Flush the stored data
						counter_next <= 0;			
							--Initialise the counter
						max_reg <= 0;
						max_index_reg <= 0;
						result_next <= (others => (others => '0'));
						buf_next <= (others => (others => '0'));
						
						--Slice BCD
						hundreds := to_integer(unsigned(numWords_bcd(2)));
						tens := to_integer(unsigned(numWords_bcd(1)));
						ones := to_integer(unsigned(numWords_bcd(0)));
						NNN_reg <= (hundreds * 100 + tens * 10 + ones);
					end if;
				end if;
			when request => 
				null;
			when processing =>
				
				--Append the retrieved data or padding value.
				--Use variable here since it may be used in the same process later, and it's property of immediate update helps.
				if counter >= 0 and counter < NNN then
					vector_append := data_reg;
				elsif counter >= NNN and counter < (NNN + 3) then
					vector_append := "00000000";
				end if;
				
				--Use variable here since it may be used in the same process later, and it's property of immediate update helps.
				value_cmp := to_integer(signed(buf(4)));
				
				--Shift the buffer by one.
				buf_next(0) <= buf(1);
				buf_next(1) <= buf(2);
				buf_next(2) <= buf(3);
				buf_next(3) <= buf(4);
				buf_next(4) <= buf(5);
				buf_next(5) <= buf(6);
				buf_next(6) <= vector_append;
				
				--Check if max value is found or not.
				--Don't check it if counter = (1, 2, 3)
				--The counter's interval of possible max emerge is from 3 to NNN+3;
				if counter = 3 then
					--First number case: initialise everything.
					max_reg <= value_cmp;
					max_index_reg <= 0;
					--Initialise result buffer and max_value;
					--What's contained in buf_next: (0, 0, 0, 1st_val, 2nd_val, 3rd_val, 4th_val).
					result_next(0) <= buf(1);
					result_next(1) <= buf(2);
					result_next(2) <= buf(3);
					result_next(3) <= buf(4);
					result_next(4) <= buf(5);
					result_next(5) <= buf(6);
					result_next(6) <= vector_append;			

				elsif counter > 3 then
					if max < value_cmp then
						--Max value and index should be updated.
						max_reg <= value_cmp;
						max_index_reg <= counter - 3;
						
						--Correspondingly update the result array.
						result_next(0) <= buf(1);
						result_next(1) <= buf(2);
						result_next(2) <= buf(3);
						result_next(3) <= buf(4);
						result_next(4) <= buf(5);
						result_next(5) <= buf(6);
						result_next(6) <= vector_append;
					end if;
				end if;
				
				if counter = (NNN + 2) then
					--Finished both processing NNN generated data and padding extra 3 ones.
					finished_reg <= '1';
				end if;
				
				counter_next <= counter + 1;
					--Update the counter at last to avoid the glitches.
					--And, it's new value cannot be read out in upcoming state transition.	
					--Update after actual manipulation happens, thus, the boundary should be correspondingly changes.
					--Likewise, i++, rather than ++i;				

			when response =>
				if counter <= NNN then
				--It means that waht's currently on the port "byte" is the actual generated value.
					dataReady <= '1';
				end if;
		end case;
	end process;
		
	clock:
	process(clk, reset, current_state, max_reg, ctrlIn, counter_next, finished_reg, NNN_reg, ctrlOut_reg)
	--To avoid mistakes in simulation, put every signal involved in RHS of assignment and conditions, into the sensitivity list.
	begin
		if rising_edge(clk) then
			if reset = '1' then
				NNN <= 0;
				finished <= '1';
				counter <= 0;
				ctrlIn_delayed <= '0';
				ctrlOut_reg <= '0';
				seqDone <= '0';
				
				start_reg <= '0';
				data_reg <= (others => '0');
				
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
				ctrlIn_delayed <= ctrlIn;
				counter <= counter_next;
				finished <= finished_reg;
				NNN <= NNN_reg;
				result <= result_next;
				current_state <= next_state;
				
				start_reg <= start;
				
				if current_state = request and next_state = processing then
					data_reg <= data;
				end if;
				
				if current_state = idle and start = '1' then
					--This condition will jump in for exactly NNN times and no need to worry about if excessed number are retrieved.
					--Therefore, remove the NNN judgement.
					ctrlOut_reg <= not ctrlOut_reg;
						--Ctrl1 would be delayed by one cycle, check it later.
				end if;
				if current_state = response and finished = '1' then
					--Pull up seqDone signal here, very weird, but it's the requirement of university.
					--Sun of beach, not elegant at all.
					seqDone <= '1';
				else
					seqDone <= '0';
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
--
--Reminders on 08/03/2026:
--	It's not wise an idea to directly drive a certain output port by combinational logic for the reason of stability.
--	Thus, we use result array grid and now easy to change the port name.
--
--Problems identified at 12pm, 12/03/2026:
--	The flag, "finished" should be set to '1' at initial condition.
--		We indeed have considered this point, however, we forgetten the assignment when reset, and now corrected.
--	Another problem is, there is an off-by-one problem observed from simulation, as for the maxIndex signal.
--	Hmm, actually no problem since the index starts from 0 instead of 1.
--
--Spotted at 2pm, 12/03/2026:
--	It seems that we need to immediately register the input data once detecting that the ctrlIn signal is toggled.
--	No, we already did.
--	The problem is casued by the wrong counter update logic, it should be updated as well even if it's in first round.
--
--Modified at 3pm, 12/03/2026:
--	The counter logic gets corrected, seriously.
--	Verified by a rough test.
--
--Plan for future at 9am, 15/03/2026:
--	It can be easily observed that the current output data is delayed than the generated one by three processing loops (instead of cycles).
--		It always a better idea to decouple the data printing and internal processing.
--		This is actually not that difficult in out design.
--		I'll give a trial, but maybe not tested today.
--		If any problems, no heistate reverting from Git.
--
--Modified at 10am, 15/03/2026:
--	The changes corresponding to commitment above is accommopolished.
--		Not tested fully.
--	However, another problem is identified:
--		The counter seems to be inproperly reset for another processing.
--		I'll montior the finished logic, and counter logic to debug.
--
--Modified at 11am, 15/03/2026:
--	Problems mentioned above solved.
--	But now, I want to stall the processing state by three cycles.
--		Because semantically, it don't need to explicitly go back idle, or response state and do nothing.
--		This change must be executed very carefully, and may abandon this idea if some error happens.
--
--Modified at 12pm, 15/03/2026:
--	The classical problem is spotted in datapath process when update buffer.
--	Since all updates within the same processs will submit the same time after it.
--		Therefore, it's not a good idea to let those updated signals to involve the later comparsion and assignments in the same process.
--	Now, corredted by those literally "variables".
--	I suspect it to effect the actual hardware result without appearing in simulation.
--		It's better to not verify it myself :)
--
--Updated at 12pm, 15/03/2026:
--	Explicitly indicate the range of every used signal of integer type to control fan in/out.
--	The hold time slack is now 5.4ns and previouslt is 3.8ns, with a timing constriant of 100 MHZ.
--
--Corrections at 8am, 19/03/2026:
--	Totally refine the counter logic, from semantic, to those logic associated with.
--	Now, counter augments uniformally at processing stage, and used in the state of response for the purpose of state transition.
--	Untested.
--
--Updated at 9am, 19/03/2026:
--	Problem identified from simulation with testbench from university.
--	It's not our responsibility, however, we need to modify our design to meet their wrong testbench.
--		If we don't, they will totally stop the clock and we can do nothing beyond getting stuck.
--	Now, the seqDone signal will be pull up at the state transition from response to idle.
--	Also, corrected the maxIndex logic.
--	By the way, the setup slack is now around 6 ns under a clock period of 10 ns.
--
--Updated at 10am, 19/03/2026:
--	Modify the order of assignment to char_array_type based on the result on borad.
--	Seems that now it works in order.