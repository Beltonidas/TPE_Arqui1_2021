----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2021 09:44:36
-- Design Name: 
-- Module Name: P1X - Behavioral
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
use IEEE.std_logic_signed.ALL; --or unsigned

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity P1c is
--  Port ( );
    Port(
            a : in std_logic_vector (31 downto 0);
            b : in std_logic_vector (31 downto 0);
            control: in std_logic_vector (2 downto 0);
            output: out std_logic_vector (31 downto 0);
            zero : out std_logic
        );
end P1c;

architecture Behavioral of P1c is
--ACA SE DECLARAN LAS ENTRADAS/SALIDAS UNICAMENTE (por eso los tb tienen esta parte vacia)
signal sig_zero: std_logic;
signal result: std_logic_vector(31 downto 0);
begin
    process(a,b,control)
    begin
        case (control) is
            when "000" => result <= a and b;
            when "001" => result <= a or b;
            when "010" => result <= a + b;
            when "100" => result <= b(15 downto 0) & x"0000";
            when "110" => result <= a - b;
            when "111" =>
                if (a < b) then
                    result <= x"00000001";
                    else
                    result <= x"00000000";
                end if;
            when others => result <= x"00000000";
        end case;
    end process;
    
    sig_zero <= '1' when (result = x"00000000")
    else '0';

    zero <= sig_zero;    
    output <= result;
end Behavioral;
