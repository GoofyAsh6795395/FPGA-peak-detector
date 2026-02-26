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

entity FSM_testbench is
--  Port ( );
end FSM_testbench;

architecture Behavioral of FSM_testbench is
    component FSM_sample is
        port(
            clk: in STD_LOGIC;
            result: out STD_LOGIC
        );
    end component;
    signal clk_tb, result_tb: STD_LOGIC := '0';
begin
    dut: FSM_sample port map(clk_tb, result_tb);
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
