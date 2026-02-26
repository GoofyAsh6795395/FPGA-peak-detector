----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.02.2026 08:21:56
-- Design Name: 
-- Module Name: FSM_testbench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity group_testbench is
--  Port ( );
end group_testbench;

architecture Behavioral of group_testbench is
    component renyuan is
        port(
            clk: in STD_LOGIC;
            output: out integer
        );
    end component;
    signal clk_tb: STD_LOGIC;
    signal output_tb: integer := 0;
begin
    dut: renyuan port map(clk_tb, output_tb);
    process
    begin
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        clk_tb <= '0';
        wait for 10 ns;
        
        clk_tb <= '1';
        wait for 10 ns;
        
        wait;
    end process;
end Behavioral;