library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity scheduler_testbench is
end entity;

architecture sim of scheduler_testbench is
	component scheduler is
		port(
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
	end component;

	signal clk_tb, reset_tb: STD_LOGIC := '0';
	signal isANNN_tb, isL_tb, isP_tb: STD_LOGIC := '0';
	signal NNN_tb: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal print_req_tb: STD_LOGIC;
	signal print_ack_tb: STD_LOGIC := '0';
	signal data_out_tb: STD_LOGIC_VECTOR(7 downto 0);
	signal start_tb: STD_LOGIC;
	signal dataReady_tb, seqDone_tb: STD_LOGIC := '0';
	signal numWords_tb: STD_LOGIC_VECTOR(11 downto 0) := (others => '0' );
	signal byte_tb: STD_LOGIC_VECTOR(7 downto 0) := (others => '0' );	
	signal dataResults_tb: STD_LOGIC_VECTOR(55 downto 0) := (others => '0' );
	signal maxIndex_tb: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	
	
begin
	dut: scheduler port map(
		clk => clk_tb,
		reset => reset_tb,

		isANNN => isANNN_tb,
		isL => isL_tb,
		isP => isP_tb,
		NNN => NNN_tb,

		data_out => data_out_tb,
		print_req => print_req_tb,
		print_ack => print_ack_tb,

		start => start_tb,
		dataReady => dataReady_tb,
		seqDone => seqDone_tb,

		numWords => numWords_tb,
		byte => byte_tb,

		dataResults => dataResults_tb,
		maxIndex => maxIndex_tb
	);
	
	clk_tb <= not clk_tb after 5 ns;
	process
	begin
		wait for 5 ns;

		wait for 10 ns;
	
		isP_tb <= '1';
		maxIndex_tb <= "001001000011";
		dataResults_tb <= (31 downto 24 => '1', others => '0');
		wait for 10 ns;

		wait for 10 ns;

		wait for 10 ns;

		print_ack_tb <= '1';
		wait for 10 ns;

		print_ack_tb <= '0';
		wait for 10 ns;

		print_ack_tb <= '1';
		wait for 10 ns;

		print_ack_tb <= '0';
		wait for 10 ns;

		print_ack_tb <= '1';
		wait for 10 ns;

		print_ack_tb <= '0';
		wait for 10 ns;

		print_ack_tb <= '1';
		wait for 10 ns;

		print_ack_tb <= '0';
		wait for 10 ns;

		print_ack_tb <= '1';
		wait for 10 ns;

		print_ack_tb <= '0';
		wait for 10 ns;

		print_ack_tb <= '1';
		wait for 10 ns;

		print_ack_tb <= '0';
		wait for 10 ns;

		--Six times of print_ack;

		wait;
	end process;
end architecture;