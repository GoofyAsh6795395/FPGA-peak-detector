library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity rx_ctrl_tb is
end entity;

architecture sim of rx_ctrl_tb is
	component rx_control is
		port(
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
		
			oe: in STD_LOGIC;
			fe: in STD_LOGIC;

			valid: in STD_LOGIC;
			done: out STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(7 downto 0);
			enqueue_req: out STD_LOGIC;
			data_out: out STD_LOGIC_VECTOR(7 downto 0)
		);
	end component;
	signal clk_tb, reset_tb, oe_tb, fe_tb, valid_tb, done_tb, euqueue_req_tb: STD_LOGIC := '0';
	signal data_in_tb, data_out_tb: STD_LOGIC_VECTOR(7 downto 0) := "00000000";
begin
	dut: rx_control port map (clk_tb, reset_tb, oe_tb, fe_tb, valid_tb, done_tb, data_in_tb, euqueue_req_tb, data_out_tb);

	clk_tb <= not clk_tb after 5 ns;
	process
	begin
		--To sync the input with clock.
		wait for 5 ns;
		
		valid_tb <= '1';
		data_in_tb <= "00000001";
		wait for 10 ns;
	
		valid_tb <= '0';
		wait for 10 ns;

		valid_tb <= '1';
		data_in_tb <= "00000011";
		wait for 10 ns;



		valid_tb <= '0';
		data_in_tb <= "00000100";
		wait for 10 ns;

		valid_tb <= '1';
		data_in_tb <= "00000101";
		wait for 10 ns;

		valid_tb <= '0';
		data_in_tb <= "00000110";
		wait for 10 ns;

		fe_tb <= '1';
		data_in_tb <= "00000110";
		wait for 10 ns;

		fe_tb <= '0';
		data_in_tb <= "00000110";
		wait for 10 ns;


		wait;
	end process;
end architecture;