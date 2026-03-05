library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dispatcher_testbench is
end entity;


architecture sim of dispatcher_testbench is
	component dispatcher is
		port(
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;

			isEmpty: in STD_LOGIC;
			dequeue_req: out STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(7 downto 0);

			parser_en: out STD_LOGIC;

			data_out: out STD_LOGIC_VECTOR(7 downto 0);

			echo_req: out STD_LOGIC;
			echo_ack: in STD_LOGIC

		);
	end component;


	signal clk_tb, reset_tb: STD_LOGIC := '0';
	signal isEmpty_tb: STD_LOGIC := '0';
	signal dequeue_req_tb: STD_LOGIC := '0';
	
	signal data_in_tb: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	signal parser_en_tb: STD_LOGIC;
	signal data_out_tb: STD_LOGIC_VECTOR(7 downto 0);
	signal echo_req_tb, echo_ack_tb: STD_LOGIC := '0';
	
begin
	dut: dispatcher port map (
			clk => clk_tb,
			reset => reset_tb,

			isEmpty => isEmpty_tb, 
			dequeue_req => dequeue_req_tb,
			data_in => data_in_tb,

			parser_en => parser_en_tb,

			data_out => data_out_tb,

			echo_req => echo_req_tb,
			echo_ack => echo_ack_tb
	);
	clk_tb <= not clk_tb after 5 ns;
	--clock period is set to 10 ns;
	process
	begin
		wait for 5 ns;
		
		data_in_tb <= "00000001";
		wait for 10 ns;

		isEmpty_tb <= '1';
		data_in_tb <= "00000010";
		wait for 10 ns;

		isEmpty_tb <= '0';
		data_in_tb <= "00000011";
		wait for 10 ns;
		
		echo_ack_tb <= '1';
		wait for 10 ns;

		echo_ack_tb <= '0';
		data_in_tb <= "00000100";
		wait for 10 ns;
		
		echo_ack_tb <= '1';
		data_in_tb <= "00000101";
		wait for 10 ns;
	
		isEmpty_tb <= '1';
		wait;
	end process;

end architecture;