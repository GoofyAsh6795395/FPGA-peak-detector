library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity command_processor is
	port(
		--To Rx.
		data_receive: in STD_ULOGIC_VECTOR (7 downto 0);
		valid: in STD_ULOGIC;
		done: out STD_ULOGIC;
		oe: in STD_ULOGIC;
		fe: in STD_ULOGIC;
		
		--To Data Processor
		start: in STD_ULOGIC;
		numWords: in STD_ULOGIC (11 downto 0);
		dataReady: out STD_ULOGIC;
		byte: out STD_ULOGIC (7 downto 0);
		maxIndex: out STD_ULOGIC_VECTOR (11 downto 0);
		dataResults: out STD_ULOGIC_VECTOR (55 downto 0);
		seqDone: out STD_ULOGIC;

		--To Tx.
		data_send: out STD_LOGIC;
		txNow: out STD_ULOGIC;
		txDone: in STD_ULOGIC;
		
		clk: in STD_ULOGIC;
		reset: in STD_ULOGIC;
	);
end entity;

architecture command_processor is

begin

end architecture;