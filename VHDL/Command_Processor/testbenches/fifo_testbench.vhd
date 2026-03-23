library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity fifo_tb is
	port(
		reset: in STD_LOGIC;
		clk: in STD_LOGIC;
		enqueue: in STD_LOGIC;
		dequeue: in STD_LOGIC;
		isEmpty: out STD_LOGIC;
		data_in: in STD_LOGIC_VECTOR (7 downto 0);
		data_out: out STD_LOGIC_VECTOR (7 downto 0)
	);
end entity;

architecture sim of fifo_tb is
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
	signal reset_tb, clk_tb, enqueue_tb, dequeue_tb, isEmpty_tb: STD_LOGIC := '0';
	signal data_in_tb, data_out_tb: STD_LOGIC_VECTOR(7 downto 0) := "00000000";
begin
	dut: fifo port map (reset_tb, clk_tb, enqueue_tb, dequeue_tb, isEmpty_tb, data_in_tb, data_out_tb);
	clk_tb <= not clk_tb after 5 ns;
	process
	begin
		wait for 5 ns;
		enqueue_tb <= '1';
		data_in_tb <= "00000001";
		wait for 10 ns;

		enqueue_tb <= '1';
		data_in_tb <= "00000010";
		wait for 10 ns;

		enqueue_tb <= '1';
		data_in_tb <= "00000011";
		wait for 10 ns;

		enqueue_tb <= '0';
		data_in_tb <= "00000100";
		wait for 10 ns;

		enqueue_tb <= '1';
		data_in_tb <= "00000101";
		wait for 10 ns;

		enqueue_tb <= '1';
		data_in_tb <= "00000110";
		wait for 10 ns;

		dequeue_tb <= '1';
		wait for 10 ns;

		enqueue_tb <= '0';
		dequeue_tb <= '0';
		wait for 10 ns;

		dequeue_tb <= '1';
		wait for 10 ns;

		dequeue_tb <= '1';
		wait for 10 ns;

		dequeue_tb <= '0';
		wait for 10 ns;

		dequeue_tb <= '1';
		wait for 10 ns;

		dequeue_tb <= '0';
		wait for 10 ns;
		
		wait;
	end process;
end architecture;