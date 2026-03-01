--This is the cmdProc wrapper.
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity command_processor is
	port(
		--To Rx.
		data_in: in STD_LOGIC_VECTOR (7 downto 0);
		valid: in STD_LOGIC;
		done: out STD_LOGIC;
		oe: in STD_LOGIC;
		fe: in STD_LOGIC;
		
		--To Data Processor
		start: out STD_LOGIC;
		numWords: out STD_LOGIC_VECTOR (11 downto 0);
		dataReady: in STD_LOGIC;
		byte: in STD_LOGIC_VECTOR (7 downto 0);
		maxIndex: in STD_LOGIC_VECTOR (11 downto 0);
		dataResults: in STD_LOGIC_VECTOR (55 downto 0);
		seqDone: in STD_LOGIC;

		--To Tx.
		data_out: out STD_LOGIC_VECTOR(7 downto 0);
		txNow: out STD_LOGIC;
		txDone: in STD_LOGIC;
		
		clk: in STD_LOGIC;
		reset: in STD_LOGIC
	);
end entity;

architecture synth of command_processor is
	component rx_controller is
		port(
			--Control.
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;

			--To Rx.
			valid: in STD_LOGIC;
			done: out STD_LOGIC;
			data: in STD_LOGIC_VECTOR(7 downto 0);
			oe: in STD_LOGIC;
			fe: in STD_LOGIC;

			--To Tx. side
			echo_req: out STD_LOGIC;
			echo_ack: in STD_LOGIC;
		
			--To parser
			parser_en: out STD_LOGIC;

			--An unified output bus
			data_out: out STD_LOGIC_VECTOR(7 downto 0)
		);
	end component;

	component parser is
		port(
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
			command: in STD_LOGIC_VECTOR (7 downto 0);
			enable: in STD_LOGIC;

			NNN: out STD_LOGIC_VECTOR(11 downto 0);		--BCD encoding is used.

			isANNN: out STD_LOGIC;
			isL: out STD_LOGIC;
			isP: out STD_LOGIC
		);
	end component;

	component scheduler is
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
	end component;
	
	component tx_controller is
		port(
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;

			--To receiver side
			echo_req: in STD_LOGIC;
			echo_ack: out STD_LOGIC;
			data_echo: in STD_LOGIC_VECTOR(7 downto 0);

			--To scheduler.
			print_req: in STD_LOGIC;
			print_ack: out STD_LOGIC;
			data_print: in STD_LOGIC_VECTOR(7 downto 0);

			--To transmitter.
			txNow: out STD_LOGIC;
			txDone: in STD_LOGIC;
			data_out: out STD_LOGIC_VECTOR(7 downto 0)
		);
	end component;
	signal echo_req, echo_ack, parser_en: STD_LOGIC;
	signal rx_out_bus: STD_LOGIC_VECTOR(7 downto 0);
	signal parser_scheduler_bus: STD_LOGIC_VECTOR(11 downto 0);
	signal scheduler_tx_bus: STD_LOGIC_VECTOR(7 downto 0);
	signal isANNN, isP, isL: STD_LOGIC;
	signal print_req, print_ack: STD_LOGIC;
begin
	connectA: rx_controller port map (
			--Control.
			clk => clk,
			reset => reset,

			--To Rx.
			valid => valid,
			done => done,
			data => data_in,
			oe => oe,
			fe => fe,

			--To Tx. side
			echo_req => echo_req,
			echo_ack => echo_ack,
		
			--To parser
			parser_en => parser_en,

			--An unified output bus
			data_out => rx_out_bus
	);

	connectB: parser port map(
			clk => clk,
			reset => reset,
			command => rx_out_bus,
			enable => parser_en,

			NNN => parser_scheduler_bus,

			isANNN => isANNN,
			isL => isL,
			isP => isP
	);

	connectC: scheduler port map(
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

			numWords => numWords,
			byte => byte,
			dataResults => dataResults,
			maxIndex => maxIndex
	);

	connectD: tx_controller port map(
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
			txNow => txNow,
			txDone => txDone,
			data_out => data_out
	);
end architecture;

--Firstly drafted 28/02/2026
--
--Commitment:
--	Not important, leave for last minute to double check.
--
--Modified on 01/03/2026
--  Based on Vivado, the unused internal signal is deleted.