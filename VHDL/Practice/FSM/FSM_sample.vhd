----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.02.2026 07:39:22
-- Design Name: 
-- Module Name: FSM_sample - Behavioral
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

entity FSM_sample is
    Port ( clk : in STD_LOGIC;
           result : out STD_LOGIC);
end FSM_sample;

architecture Behavioral of FSM_sample is
    signal data_counter, padding_counter: integer := 0;
    signal data_counter_next, padding_counter_next: integer := 0;
    type stateType is (idle, running, padding, finished);
    signal state_current, state_next: stateType := idle;
begin
    next_state_logic:
    process(state_current, data_counter, padding_counter)
    begin
        state_next <= state_current;
        data_counter_next <= data_counter;
        padding_counter_next <= padding_counter;
        
        case state_current is
            when idle =>
                state_next <= running;
                data_counter_next <= 1;
            when running =>
                if data_counter < 7 then
                    state_next <= running;
                    data_counter_next <= data_counter + 1;
                else
                    state_next <= padding;
                    padding_counter_next <= 1;
                end if;
            when padding =>
                if padding_counter < 4 then
                    state_next <= padding;
                    padding_counter_next <= padding_counter + 1;
                else
                    state_next <= finished;
                end if;
            when finished =>
                state_next <=running;
		data_counter_next <= 1;
            when others =>
                state_next <= idle;  
        end case;
    end process;

    control:
    process(clk)
    begin
        if rising_edge(clk) then 
            state_current <= state_next;
            data_counter <= data_counter_next;
            padding_counter <= padding_counter_next;
        end if;
    end process;
    
    output_logic:
    process(state_current)
    begin
        if(state_current = finished) then
            result <= '1';
        end if;
    end process;
end Behavioral;
