----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2021 12:43:05
-- Design Name: 
-- Module Name: p1d_TB - Behavioral
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
use ieee.std_logic_unsigned.conv_integer;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity p1d is
--  Port ( );
    Port(
    clk: in std_logic;
    rst: std_logic;
    wr: in std_logic;
    reg1_rd: in std_logic_vector (4 downto 0);
    reg2_rd: in std_logic_vector (4 downto 0);
    reg_wr: in std_logic_vector (4 downto 0);
    data_wr: in std_logic_vector (31 downto 0);   
    data1_rd: out std_logic_vector (31 downto 0); 
    data2_rd: out std_logic_vector (31 downto 0) 
    );
end p1d;

architecture Behavioral of p1d is
type t_regBank is array(31 downto 0) of std_logic_vector (31 downto 0);
-- El banco de registros en si, sería una señal unicamente.
signal regBank: t_regbank;
signal output_1,output_2: std_logic_vector (31 downto 0);
begin
    process (clk,rst) is
    begin
        if(rst = '1') then
            regBank <= (others => x"00000000"); --( ) es aggregate (listado de "cosas"), others me asigna a todas esas "cosas" el valor 0.
        elsif (falling_edge(clk)) then
            if (wr='1') then
                regBank(conv_integer(reg_wr))<=data_wr;
            end if;
        end if;
    end process;
    
    --Data reads concurrentes
    output_1 <= x"00000000" when (reg1_rd = "00000")
    else regBank(conv_integer(reg1_rd));
    output_1 <= x"00000000" when (reg2_rd = "00000")
    else regBank(conv_integer(reg2_rd));
    --Asigno las señales de los reads a las verdaderas salidas.
    data1_rd <= output_1;
    data2_rd <= output_2;

end Behavioral;