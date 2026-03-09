--This is the cmdProc wrapper.
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity cmdProc_internal is
	port(
		--To Rx.
		rxData: in STD_LOGIC_VECTOR (7 downto 0);
		rxnow: in STD_LOGIC;
		rxdone: out STD_LOGIC;
		ovErr: in STD_LOGIC;
		framErr: in STD_LOGIC;
		
		--To Data Processor
		start: out STD_LOGIC;
		numWords_bcd: out STD_LOGIC_VECTOR(11 downto 0);
		dataReady: in STD_LOGIC;
		byte: in STD_LOGIC_VECTOR (7 downto 0);
		maxIndex: in STD_LOGIC_VECTOR(11 downto 0);
		dataResults: in STD_LOGIC_VECTOR (55 downto 0);
		seqDone: in STD_LOGIC;

		--To Tx.
		txData: out STD_LOGIC_VECTOR(7 downto 0);
		txnow: out STD_LOGIC;
		txdone: in STD_LOGIC;
		
		clk: in STD_LOGIC;
		reset: in STD_LOGIC
	);
end entity;

architecture comb of cmdProc_internal is
	signal echo_req, echo_ack, parser_en: STD_LOGIC;
	signal rx_out_bus: STD_LOGIC_VECTOR(7 downto 0);
	signal parser_scheduler_bus: STD_LOGIC_VECTOR(11 downto 0);
	signal scheduler_tx_bus: STD_LOGIC_VECTOR(7 downto 0);
	signal isANNN, isP, isL: STD_LOGIC;
	signal print_req, print_ack: STD_LOGIC;
begin
	rx_controller_connect: entity work.rx_controller(comb) port map (
			--Control.
			clk => clk,
			reset => reset,

			--To Rx.
			valid => rxnow,
			done => rxdone,
			data => rxData,
			oe => ovErr,
			fe => framErr,

			--To Tx. side
			echo_req => echo_req,
			echo_ack => echo_ack,
		
			--To parser
			parser_en => parser_en,

			--An unified output bus
			data_out => rx_out_bus
	);

	parser_connect: entity work.parser(synth) port map(
			clk => clk,
			reset => reset,
			command => rx_out_bus,
			enable => parser_en,

			NNN => parser_scheduler_bus,

			isANNN => isANNN,
			isL => isL,
			isP => isP
	);

	scheduler_connect: entity work.scheduler(synth) port map(
			--External control:
			clk => clk,
			reset => reset,
		
			--To parser.
			isANNN => isANNN,
			isL => isL,
			isP => isP,
			NNN => 	parser_scheduler_bus,

			--To transmitter side.
			data_out => scheduler_tx_bus,
			print_req => print_req,
			print_ack => print_ack,

			--To data processor

			start => start,
			dataReady => dataReady,
			seqDone => seqDone,

			numWords => numWords_bcd,
			byte => byte,
			dataResults => dataResults,
			maxIndex => maxIndex
	);

	tx_controller_connect: entity work.tx_controller(synth) port map(
			clk => clk,
			reset => reset,

			--To receiver side
			echo_req => echo_req,
			echo_ack => echo_ack,
			data_echo => rx_out_bus,

			--To scheduler.
			print_req => print_req,
			print_ack => print_ack,
			data_print => scheduler_tx_bus,

			--To transmitter.
			txnow => txnow,
			txdone => txdone,
			data_out => txData
	);
end architecture;

--Firstly drafted 28/02/2026
--
--Commitment:
--	Not important, leave for last minute to double check.
--
--Modified on 01/03/2026:
--	Based on Vivado, the unused internal signal is deleted.
--
--Modified at 10am, 08/03/2026:
--	Rename the whole entity and some ports to map the provided files.
--
--Ideas at 11am, 08/03/2026:
--	A wrapper file can be used to implement type conversion, thus I don't need to change any of my internal logic.
--
--Commitment at 11am, 09/03/2026:
--	Changed the port map style.
