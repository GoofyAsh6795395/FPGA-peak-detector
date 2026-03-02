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
	signal NNN_reg: integer := 0;
	--This subsequent counters denotes the accumulated times for print to be finished.
	signal counterL, counterP, counterData: integer := 0;
	signal printing: STD_LOGIC := '0';
	signal data, data_next: STD_LOGIC_VECTOR(7 downto 0);		--It's binary sequence, same with byte.
	signal finished: STD_LOGIC := '0';
begin
	--What's managed here?
	state_transition_logic:
	process(current_state, isL, isP, isANNN, finished, counterL, counterP, counterData, print_ack)
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
				if counterData = 2 and print_ack = '1' then
					--This means that two data have already been sent previously, and the latest just be sent.
					if finished = '0' then
						next_state <= run;
					elsif isP = '1' then
						next_state <= printP;
					elsif isL = '1' then
						next_state <= printL;
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
	process(current_state, dataReady, printing, data, byte, counterL, counterP, counterData)
		variable lsb, msb: integer := 0;
		variable lsb_ascii, msb_ascii: integer := 0;	--Defined as integer, converted to vector when output.
		
		variable upper, lower: integer := 0;		--For L command to slice the required pieces.
	begin
		--Register updates:
		data_next <= data;

		--Voltage level, but avoid latch inferrence.
		data_out <= (others => '0');
		print_req <= '0';
		lsb := 0;
		msb := 0;
		lsb_ascii := 0;
		msb_ascii := 0;
		
		--Single pulse:
		start <= '0';
		
		case current_state is
			when idle =>
				--Operations are listed in clocked signal so here, nothing.
				null;
			when run => 
				start <= '1';
				if dataReady = '1' then
					--Immediately store the byte signal once it's ready.
					data_next <= byte;
				end if;
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
						msb_ascii := msb + 48;
					else						--It's a letter.
						msb_ascii := msb + 55;
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
			when others =>
		end case;
	end process;

	control:
	process(clk, reset, isANNN, seqDone, printing, print_ack, finished)
		variable hundreds, tens, ones: integer := 0;
	begin
		if rising_edge(clk) then
			if reset = '1' then
				finished <= '0';
				counterL <= 0;
				counterP <= 0;
				counterData <= 0;
				NNN_reg <= 0;
				numWords <= (others => '0');
				printing <= '0';
				data <= (others => '0');
			else
				data <= data_next;
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
							finished <= '0';

							--Output is here.
							numWords <= NNN;

							--Convert BCD to integer, then hold this value to control iteration times.
							hundreds := to_integer(unsigned(NNN(11 downto 8)));
							tens := to_integer(unsigned(NNN(11 downto 8)));
							ones := to_integer(unsigned(NNN(11 downto 8)));
					
							NNN_reg <= hundreds * 100 + tens * 10 + ones;
						end if;
						
					when printData =>
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
--Commitment at 11.45pm, 27/02/2026
--	Compile succesfully
--	Quite a lot functions integrated, test it later.
--	Git submitted.