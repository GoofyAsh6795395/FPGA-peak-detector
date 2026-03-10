library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity wrapper is
	port(
		clk: in STD_LOGIC;
		data_out: out integer range 0 to 15
	);
end entity;

architecture sim of wrapper is
	component caller is
		port(
			clk: in STD_LOGIC;
			req: out STD_LOGIC;
			ack: in STD_LOGIC
		);
	end component;

	component callee is
		port(
			clk: in STD_LOGIC;
			req: in STD_LOGIC;
			ack: out STD_LOGIC;
			data: out integer range 0 to 15
		);
	end component;
	
	signal req_bus, ack_bus: STD_LOGIC;
begin
	connectA: caller port map (
		clk => clk, 
		req => req_bus,
		ack => ack_bus
	);
	connectB: callee port map(
		clk => clk, 
		req => req_bus,
		ack => ack_bus,
		data => data_out
	);
end architecture;