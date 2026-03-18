library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity scheduler is
	port(
		--External control:
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;
		
		--To parser.
		isANNN: in STD_LOGIC;
		isL: in STD_LOGIC;
		isP: in STD_LOGIC;
		NNN: in STD_LOGIC_VECTOR(11 downto 0);		--12 bit BCD.

		--To transmitter side.
		data_out: out STD_LOGIC_VECTOR(7 downto 0);	--8 bit sequence, ASCII encoded.
			--Now it's a voltage level signal, no idea if the possible glich matters or not, 01/03/2026.
		print_req: out STD_LOGIC;
		print_ack: in STD_LOGIC;			--Single cycle pulse.

		--To data processor

		start: out STD_LOGIC;
		dataReady: in STD_LOGIC;
		seqDone: in STD_LOGIC;

		numWords: out STD_LOGIC_VECTOR(11 downto 0);
		byte: in STD_LOGIC_VECTOR(7 downto 0);		--8 bit binary sequence

		dataResults: in STD_LOGIC_VECTOR(55 downto 0);
		maxIndex: in STD_LOGIC_VECTOR(11 downto 0)
	);
end entity;

architecture synth of scheduler is
	type stateType is (idle, run, printData, printL, printP);
	signal current_state, next_state: stateType := idle;
	signal NNN_reg: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal NNN_int: integer range 0 to 1023 := 0;
		--Hold the received NNN from parser.
		--This is a integer instead of vector, 
		--Managed in clock process with conditon that state is idle and isANNN is received.

	--The subsequent counters denotes the accumulated times for print to be finished.
	--Clearly check if there is off-by-one is important.
	signal counterL: integer range 0 to 20 := 0;
	signal counterP: integer range 0 to 6 := 0;
	signal counterData: integer range 0 to 3 := 0;
		--Literally, count the time of print
		--Automatically reset to 0 once a print task is totally finished, by mod operation.
		--The range is explicitly given to avoid the waste of resources and optimise fan in/ out.
		--Updated in clocked process, and used in state-transition logic & datapath logic
			--To determine both next state and respective output.

	signal printing: STD_LOGIC := '0';		
		--Maintained in clock process but used in datapath to determine the request signal.
		--If high, means that the request is already sent, reset to 0 until print_ack is captured.
		--Consider the last time of printing, if print_ack is receviced:
			--The printing signal is updated to 0 at next posedge clk.
			--The state transition happens in parllel
			--So no need to worry about if it will be pull up again by accident.
			--Also, the request signal should not be triggered.

	signal data: STD_LOGIC_VECTOR(7 downto 0);		
		--It's binary sequence, same with byte, maintained in datapath process.

	signal finished: STD_LOGIC := '0';				
		--An indicator of seqDone, updated in clock process.
		
	signal data_mistake: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal mistake: STD_LOGIC := '0';	
		--An indicator of whether another dataReady is received even I pull down the signal "start."
		--It's all of the fault of university and such circumstance is definitely not allowed in our data processor design.

begin
	numWords <= NNN_reg;
	--The output of numWords is directly connected to the internal register of "NNN_reg";
	--Not use the input from parser directly in case of glitches.
	--No need to worry about the type of this output because there is another type-conversion wrapper outside.

	state_transition_logic:
	process(current_state, isL, isP, isANNN, finished, counterL, counterP, counterData, print_ack, dataReady, mistake)
	begin
		next_state <= current_state;
		case current_state is
			when idle => 
				--Assume the upstream isANNN, isL, isP is one hot.
				if isANNN = '1' then
					next_state <= run;
				elsif isP = '1' then
					next_state <= printP;
				elsif isL = '1' then
					next_state <= printL;
				end if;
			when run =>
				if dataReady = '1' then
					next_state <= printData;
				else
					next_state <= run;
				end if;
			when printData =>
				--Start state transiton if counter condition is met.
				if counterData = 2 and print_ack = '1' and mistake = '0' then
					--This means that two data have already been sent previously, and the latest one just be sent.
					--So state can be updated to next one now.
					--If there isn't anything awaiting print, even it should not exist.
					if finished = '0' then
						next_state <= run;
					elsif isP = '1' then
						next_state <= printP;
					elsif isL = '1' then
						next_state <= printL;
					else
						next_state <= idle;
					end if;
				else
					next_state <= printData;
				end if;
			when printL =>
				if counterL = 19 and print_ack = '1' then
					next_state <= idle;
				else
					next_state <= printL;
				end if;
			when printP =>
				if counterP = 5 and print_ack = '1' then
					next_state <= idle;
				else
					next_state <= printP;
				end if;
			when others =>
				next_state <= idle;
		end case;
	end process;

	--Too many signals are involved in this process.
	--I don't want to waste my time figuring out waht's contained in the sensitivity list.
	--Similar with the process(all) syntax in VHDL-2008, here, I'll manually list all of them to avoid errors.
	--Same happens below.
	datapath:
	process(current_state, dataReady, printing, data, byte, counterL, counterP, counterData, dataResults, maxIndex, mistake, data_mistake)
		variable lsb, msb: integer range 0 to 31 := 0;
		variable lsb_ascii, msb_ascii: integer range 0 to 255 := 0;	--Defined as integer, converted to vector when output.
		
		variable upper, lower: integer range 0 to 55 := 0;		--For L command to slice the required pieces.
	begin
		--Voltage level, but avoid latch inferrence.
		data_out <= (others => '0');
		print_req <= '0';
		lsb := 0;
		msb := 0;
		lsb_ascii := 0;
		msb_ascii := 0;
		upper := 0;
		lower := 0;
		
		--Single pulse:
		start <= '0';
		
		case current_state is
			when idle =>
				--Operations are listed in clocked signal so here, nothing.
				null;
			when run => 
				start <= '1';
				
			when printData =>
				--Request signal follows the printing one, instead of single cycle pulse
				if printing = '1' then
					print_req <= '1';

					--Convert binary to ascii.
					--The generated data is capital, so the range of corresponding integer is:
						--0 to 9: original
						--A to F: 10 to 15
					--Use unsigned convert to interpret data because ASCII code is unsigned.
						--0 to 9: unsigned vector ranging from 48 to 57
						--A to F: u-vec from 65 to 90

					msb := to_integer(unsigned(data(7 downto 4)));
					lsb := to_integer(unsigned(data(3 downto 0)));
					
					if msb <= 9 then
						msb_ascii := msb + 48;			--48 = 48 - 0 = 49 - 1 = ...
					else						--It's a capital letter.
						msb_ascii := msb + 55;			--55 = 65 - 10 = 66 - 11 = ...
					end if;

					if lsb <= 9 then
						lsb_ascii := lsb + 48;
					else						--It's a letter.
						lsb_ascii := lsb + 55;
					end if;

					case counterData is
						when 0 =>
							data_out <= std_logic_vector(to_unsigned(msb_ascii, 8));
						when 1 =>
							data_out <= std_logic_vector(to_unsigned(lsb_ascii, 8));
						when 2 =>
							data_out <= "00100000";		--Ascii code of " " 
						when others =>
							null;
					end case;
				else
					print_req <= '0';
				end if;
				
			when printL =>
				if printing = '1' then
					print_req <= '1';

					--Because the output is big endian priority, so index decreases.
					upper := 55 - counterL * 8;
					lower := 47 - counterL * 8;
					
					--Slice.
					msb := to_integer(unsigned(dataResults(upper downto upper - 3)));
					lsb := to_integer(unsigned(dataResults(lower + 3 downto lower)));

					--Convert.
					if msb <= 9 then
						msb_ascii := msb + 48;
					else						--It's a letter.
						msb_ascii := msb + 55;
					end if;

					if lsb <= 9 then
						lsb_ascii := lsb + 48;
					else						--It's a letter.
						lsb_ascii := lsb + 55;
					end if;

					--Output assignment.
					case (counterL mod 3) is
						when 0 =>
							data_out <= std_logic_vector(to_unsigned(msb_ascii, 8));
						when 1 =>
							data_out <= std_logic_vector(to_unsigned(lsb_ascii, 8));
						when 2 =>
							data_out <= "00100000";		
						when others =>
							null;
					end case;
				else
					print_req <= '0';
				end if;

			when printP =>
				if printing = '1' then
					print_req <= '1';

					--Read the peak value out.
					msb := to_integer(unsigned(dataResults(31 downto 28)));
					lsb := to_integer(unsigned(dataResults(27 downto 24)));
					
					if msb <= 9 then
						msb_ascii := msb + 48;
					else						--It's a letter.
						msb_ascii := msb + 55;
					end if;

					if lsb <= 9 then
						lsb_ascii := lsb + 48;
					else						--It's a letter.
						lsb_ascii := lsb + 55;
					end if;

					--Hint: the BCD encoding gives the same last 4 bits with ASCii
					--Therefore, directly use combine operator to form the output Ascii code.
					--Prefix is "0011", observed from table.
					case counterP is
						when 0 =>
							data_out <= std_logic_vector(to_unsigned(msb_ascii, 8));
						when 1 =>
							data_out <= std_logic_vector(to_unsigned(lsb_ascii, 8));
						when 2 =>
							data_out <= "00100000";	
						when 3 =>
							--Follow the convention of order, print the MSB, with index range from 11 to 8, at beginning.
							data_out <= "0011" & maxIndex(11 downto 8);
						when 4 =>
							data_out <= "0011" & maxIndex(7 downto 4);
						when 5 =>
							data_out <= "0011" & maxIndex(3 downto 0);
						when others =>
							null;
					end case;
				else
					print_req <= '0';
				end if;
		end case;
	end process;

	control:
	process(clk, reset, isANNN, seqDone, printing, print_ack, finished, mistake)
		variable hundreds, tens, ones: integer range 0 to 9 := 0;
	begin
		hundreds := 0;
		tens := 0;
		ones := 0;         --To avoid latch inference
	
		if rising_edge(clk) then
			if reset = '1' then
				finished <= '0';
				counterL <= 0;
				counterP <= 0;
				counterData <= 0;
				NNN_int <= 0;
				NNN_reg <= (others => '0');
				printing <= '0';
				data <= (others => '0');
				current_state <= idle;
				data_mistake <= (others => '0');
				mistake <= '0';
				
			else
				current_state <= next_state;
				if seqDone = '1' then
					finished <= '1';
					--Keep high after seqDone appears, reset until idle.
				end if;

				case current_state is
					when idle =>
						--Flush
						counterL <= 0;
						counterP <= 0;
						counterData <= 0;
						if isANNN = '1' then
							--Finished signal does not used anymore after running state
							--It's a good idea to keep its natural semantics.
							--So pull down if next ANNN cycle starts.
							--Also, because while NNN data is not finished, it will not turn to idle state
							--So no need to worry if this clean operation will interrupt NNN iterations.
							finished <= '0';
							NNN_reg <= NNN;
							--Capture the NNN into a register to avoid it changing later.

							--Convert BCD to integer, then hold this value to control iteration times.
							hundreds := to_integer(unsigned(NNN(11 downto 8)));
							tens := to_integer(unsigned(NNN(7 downto 4)));
							ones := to_integer(unsigned(NNN(3 downto 0)));
					
							NNN_int <= hundreds * 100 + tens * 10 + ones;
						end if;
						
					when run =>
						if dataReady = '1' then
							--Immediately store the byte signal once it's ready.
							data <= byte;
						end if;
					
					when printData =>
						if dataReady = '1' then
							--It means that another dataReady is received while printing current data.
							--It's regarded as a mistake caused by universities' trash data processor
							--To deal with it, use a flag and a temporary register to capture the wrong byte input.
							--In case that it is dumped by mistake.
							mistake <= '1';
							data_mistake <= byte;
						end if;
						
						if print_ack = '1' and counterData = 2 and mistake = '1' then
							--It means that three ascii code has been already sent and mistake happens.
							--In this scenario, the right generated data is fully printed.
--							--And there is another wrong one but still requires printing out.
							
							data <= data_mistake;
							mistake <= '0';
						end if;
						
						if printing = '0' then
							--When counter condition is satifsied, the state should be transferred to next one.
							--So don't worry if the printing flag is set wrong.
							printing <= '1';
						elsif print_ack = '1' then
							printing <= '0';
							counterData <= (counterData + 1) mod 3;
						end if;

					when printL =>
						if printing = '0' then
							printing <= '1';
						elsif print_ack = '1' then
							printing <= '0';
							counterL <= (counterL + 1) mod 20;
							--3 * 7 = 21, start from 0, so maximum value of this counter is 20.
						end if;
					when printP =>
						if printing = '0' then
							printing <= '1';
						elsif print_ack = '1' then
							printing <= '0';
							counterP <= (counterP + 1) mod 6;
							--two digit for value, one for space, three for indices, so maximum value of this counter is 6.
						end if;
					when others =>
						null;
				end case;
			end if;
		end if;
	end process;
end architecture;


--Log:
--
--Firstly drafted on 27/02/2026
--
--Commitment at 6pm, 27/02/2026:
--	So many details are ignored in the previous ASM chart
--	A fully refreshed ASM is now working on.
--	For the print process, at least extra "requested" and counter are required
--		I will take some time to manage those clutters, kinda confusing.
--		Implementation may be pending.
--
--Commitment at 7.30pm, 27/02/2026:
--	Now, use three signal: printing, print_ack and counter to control the iteration time.
--		The counter and printing are registeres
--		The print_ack is a single cycle pulse.
--		The print_req is controlled in datapath process.
--		The data_out is updated in datapath process.
--		The counter is updated in clocking process to remove the complexity of extra temporary signal.
--			Augment or hold, conditionally.
--		The printing signal is updated in clocking process.
--
--Ideas at 8.40pm, 27/02/2026:
--	Maybe there are better way to control data_next & data signals, like direct-link to byte.
--	Consider it later.
--
--Commitment at 11pm, 27/02/2026:
--	Code finished, checking details.
--	Found that the seqDone signal is totally forgetten, lol.
--
--Commitment at 11.30pm, 27/02/2026:
--	Nearly finished.
--	The total counter is abandoned, now use a strcky flag "finished" to hold seqDone signal.
--	Correcting the sensitivity list now.
--
--Commitment at 11.45pm, 27/02/2026:
--	Compile succesfully.
--	Quite a lot functions integrated, test it later.
--	Git submitted.
--
--Commitment at 3pm, 01/03/2026:
--	Try to identify the problems manually.
--		Found that latches may inferred for some variables, corrected.
--	Internal signals are checked ok.
--	More commitments are respectively added around signal definations, can be easily found in Git Blame.
--
--Reminder at 9pm, 01/03/2026:
--	DataResults, maxIndex signals, I'm not sure if they should be immediately registered or not in somewhere once we got seqDone.
--	Check upstream data processor, if not, they mustn't clear it.
--
--Modified at 11pm, 01/03/2026:
--	Identified from Vivado that the start signal is always ground.
--	Found that the current_state is forgetten to assign in clock process
--	Corrected.
--
--Modified at 11am, 05/03/2026:
--	Adjusted the sensitivity list on line 72 & 127, based on Vivado's suggestion.
--	Renamed signal "NNN_reg" to "NNN_int"
--	Changed the output logic of numWords
--
--Modified at 12am, 05/03/2026:
--	Use another registered signal NNN_reg to capture NNN conditionally.
--
--Modified at 1pm, 05/03/2026:
--	NNN integer and the logic related to should be removed, like BCD slicing, no need to store.
--	However, at this stage, for the purpose of tracking what's happening inside to debug and maintain, leave it.
--	It will not shown in schematics since it doesn't used in any internal assignment or comparison.
--
--Commitment at 5pm, 05/03/2026:
--	Function of P print is tested working in order.
--		However, the behaviour of down-stream cannot be fully simulated by testbench.
--		Thus, this point worth double checking if there is something wrong when simulating everything together.
--
--Spotted at 11pm, 05/03/2026:
--	It seems to be better to define the internal indicator "printing" as a volatge-level instead of resigering it.
--		Now, the impact is, the start-up printing after state transition is stalling for 1 more cycle.
--			Which means that totally two clock cycles are used for print to start up.
--		However, I'll choose to leave it here, at this stage because:
--			A. Not a function disaster and the impact is limited.
--			B. A serious change in whole structure is required rewriting if the "printing" logic gets different.
--
--Suggestions at 6pm, 09/03/2026:
--	I have no idea if the start signal should be registered or not.
--	It depends on if it will cause a combinational loop with downstream machine.
--	Check the "dataReady" signal of downstream later to evaluate this risk.
--	I have tracked the "start" signal and found the "dataReady" does not directly rely on it.
--		It directly depends on state register and counter logic.
--
--Problems identified at 10pm, 09/03/2026:
--	The university provided data processor may send dataReady twice even after we pull down the signal "start".
--	Fuck,
--
--Modified at 2am, 10/03/2026:
--	Now this code could successfully deal with a unstable upstream source.
--	A flag "mistake" is used to capture if another dataReady is received while printing.
--		This flag is clean when printing has been executed for totally 3 time, and the flag is still high level.
--	Another signal, data_mistake, is also declared, to capture the byte signal at a wrong time.
--	Both of them are managed in clocking process.
--	The function is verified by simulation, as expected.
--		However, seems that the simulation only involve a normal ANNN and corresponding task.
--		More complex operations, like L command, P command, echo interrupt are scheduled in future.
--			To test the behaviour under such operations in real hardware.
--
--Modified on 16/03/2026:
--	The problem of termination is identified and it's found to be caused by the incomplete state transition logic.
--	Now corrected and give another trial.
