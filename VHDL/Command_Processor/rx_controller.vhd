--It's a wrapper file, aiming to synthesis the small submodules together.
--Therefore, the usage of external ports should be via this entity instead of the inside one.

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity rx_controller is
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
end entity;

architecture comb of rx_controller is
	component dispatcher is
		port(
			--Control.
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
	
			--To FIFO.
			isEmpty: in STD_LOGIC;
			dequeue_req: out STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(7 downto 0);

			--To parser.
			parser_en: out STD_LOGIC;

			--An unified output channel of data
			data_out: out STD_LOGIC_VECTOR(7 downto 0);

			--To transmitter side.
			echo_req: out STD_LOGIC;
			echo_ack: in STD_LOGIC
		);
	end component;

	component fifo is
		port(
			reset: in STD_LOGIC;
			clk: in STD_LOGIC;
			enqueue: in STD_LOGIC;
			dequeue: in STD_LOGIC;
			isEmpty: out STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR (7 downto 0);
			data_out: out STD_LOGIC_VECTOR (7 downto 0)
		);
	end component;

	component rx_handshaker is
		port(
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
		
			--To receiver.
			oe: in STD_LOGIC;
			fe: in STD_LOGIC;

			valid: in STD_LOGIC;
			done: out STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(7 downto 0);

			--To FIFO.
			enqueue_req: out STD_LOGIC;
			data_out: out STD_LOGIC_VECTOR(7 downto 0)
		);
	end component;
	signal enqueue_sig, dequeue_sig, isEmpty_sig: STD_LOGIC;
	signal handshaker_fifo_bus: STD_LOGIC_VECTOR(7 downto 0);
	signal fifo_dispatcher_bus: STD_LOGIC_VECTOR(7 downto 0);
begin
	connectA: rx_handshaker port map (
		clk => clk,
		reset => reset,
		oe => oe,
		fe => fe,
		valid => valid,
		done => done,
		data_in => data,
		enqueue_req => enqueue_sig,
		data_out => handshaker_fifo_bus
	);

	connectB: fifo port map(
		reset => reset,
		clk => clk,
		enqueue => enqueue_sig,
		dequeue => dequeue_sig,
		isEmpty => isEmpty_sig,
		data_in => handshaker_fifo_bus,
		data_out => fifo_dispatcher_bus
	);

	connectC: dispatcher port map(
		clk => clk,
		reset => reset,
		isEmpty => isEmpty_sig,
		dequeue_req => dequeue_sig,
		data_in => fifo_dispatcher_bus,
		parser_en => parser_en,
		data_out => data_out,
		echo_req => echo_req,
		echo_ack => echo_ack
	);
end architecture;

--Firstly drafted on 27/02/2026
--
--Commitment at 12.30pm, 27/02/2026:
--	Finished connecting.
--	Not carefully checked at this stage.
--
