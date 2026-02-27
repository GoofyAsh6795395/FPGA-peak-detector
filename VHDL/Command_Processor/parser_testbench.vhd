library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity parser_tb is

end entity;

architecture sim of parser_tb is
	component parser is
		port(
			clk: in STD_LOGIC;
			reset: in STD_LOGIC;
			command: in STD_LOGIC_VECTOR (7 downto 0);
			enable: in STD_LOGIC;
			NNN: out STD_LOGIC_VECTOR (11 downto 0);
			isANNN: out STD_LOGIC;
			isL: out STD_LOGIC;
			isP: out STD_LOGIC
		);
	end component;
	signal clk_tb, reset_tb, isANNN_tb, isL_tb, isP_tb: STD_LOGIC := '0';
	signal command_tb: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal enable_tb: STD_LOGIC := '0';
	signal NNN_tb: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');


	constant ascii_a: STD_LOGIC_VECTOR (7 downto 0) := x"61";
	constant ascii_a_cap: STD_LOGIC_VECTOR (7 downto 0) := x"41";
	constant ascii_l: STD_LOGIC_VECTOR (7 downto 0) := x"6C";
	constant ascii_l_cap: STD_LOGIC_VECTOR (7 downto 0) := x"4C";
	constant ascii_p: STD_LOGIC_VECTOR (7 downto 0) := x"50";
	constant ascii_p_cap: STD_LOGIC_VECTOR (7 downto 0) := x"70";
	constant ascii_0: STD_LOGIC_VECTOR (7 downto 0) := x"30";
	constant ascii_9: STD_LOGIC_VECTOR (7 downto 0) := x"39";

begin
	deviceUnderTest: parser port map (clk_tb, reset_tb, command_tb, enable_tb, NNN_tb, isANNN_tb, isL_tb, isP_tb);
	clk_tb <= not clk_tb after 5 ns;
	process 
	begin

	wait for 5 ns;
	enable_tb <= '1';

	command_tb <= ascii_l;
        wait for 10 ns;
        
	command_tb <= ascii_l_cap;
        wait for 10 ns;
        
	command_tb <= ascii_p;
        wait for 10 ns;
        
	command_tb <= ascii_a;
        wait for 10 ns;
        
        wait for 10 ns;
        
	command_tb <= x"31";
        wait for 10 ns;
        
	--interrupt
	enable_tb <= '0';
	wait for 10 ns;

	enable_tb <= '1';
	command_tb <= x"39";
        wait for 10 ns;
        
	command_tb <= x"32";
        wait for 10 ns;
        
	--interrupt
	enable_tb <= '0';
	command_tb <= ascii_a ;
	wait for 10 ns;
	
	enable_tb <= '1';
        wait for 10 ns;
        
	command_tb <= x"35";
        wait for 10 ns;
        
	command_tb <= ascii_0;
        wait for 10 ns;
        
	command_tb <= ascii_0;
        wait for 10 ns;
        
	command_tb <= ascii_a;
        wait for 10 ns;
        
	command_tb <= x"39";
        wait for 10 ns;

	command_tb <= x"37";
	wait for 10 ns;
        
	--interrupt
	command_tb <= x"75";
	wait for 10 ns;

	command_tb <= x"34";
	wait for 10 ns;
	
	command_tb <= ascii_l_cap;
        wait for 10 ns;

	enable_tb <= '0';
        
        wait;
	end process;
end architecture;