library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity processor is
port(
	Clk         : in  std_logic;
	Reset       : in  std_logic;
	-- Instruction memory
	I_Addr      : out std_logic_vector(31 downto 0);
	I_RdStb     : out std_logic;
	I_WrStb     : out std_logic;
	I_DataOut   : out std_logic_vector(31 downto 0);
	I_DataIn    : in  std_logic_vector(31 downto 0);
	-- Data memory
	D_Addr      : out std_logic_vector(31 downto 0);
	D_RdStb     : out std_logic;
	D_WrStb     : out std_logic;
	D_DataOut   : out std_logic_vector(31 downto 0);
	D_DataIn    : in  std_logic_vector(31 downto 0)
);
end processor;

architecture processor_arq of processor is
---------Inicio Sección Fetch---------
signal PC, PC_next, PC_4: std_logic_vector(31 downto 0);
signal ID_PC_4, Instruction: std_logic_vector(31 downto 0);
signal PCSrc: std_logic;
signal PC_Branch: std_logic_vector(31 downto 0);

---------Inicio Sección Instruction Decode---------
component P1d is port( --Declaración del banco de registros
        clk: in std_logic;
        rst: in std_logic;
        wr: in std_logic;
        reg1_rd: in std_logic_vector (4 downto 0);
        reg2_rd: in std_logic_vector (4 downto 0);
        reg_wr: in std_logic_vector (4 downto 0);
        data_wr: in std_logic_vector (31 downto 0);   
        data1_rd: out std_logic_vector (31 downto 0); 
        data2_rd: out std_logic_vector (31 downto 0) 
    );
end component;
    signal clk_rg, rst_rg, wr_rg: std_logic;
   signal reg1_rd_rg, reg2_rd_rg, reg_wr_rg: std_logic_vector (4 downto 0);
   signal data_wr_rg, data1_rd_rg, data2_rd_rg: std_logic_vector (31 downto 0);
---------Fin Sección Instruction Decode---------
begin 	
Reg_bank: p1d port map( --Connexión del banco de registros
        clk => clk_rg,
        rst => rst_rg,
        wr  => wr_rg,
        reg1_rd => reg1_rd_rg,
        reg2_rd => reg2_rd_rg,
        reg_wr  => reg_wr_rg,
        data_wr => data_wr_rg,   
        data1_rd => data1_rd_rg, 
        data2_rd => data2_rd_rg
    );
    
--Multiplexor que elige instrucción a meter en Program Conter
PC_next <= PC_4 when PCSrc='0' else
          PC_Branch;

--Definicion del Program Counter (PC) (Es un registro)
PC_Process:    process(Clk,Reset)
               begin
                if (Reset = '1') then
                    PC <= (others => '0'); --Confirmar que la sintaxis sea correcta
                    elsif (rising_edge(Clk)) then
                        PC <= PC_next;
                end if;
               end process;
               
--Definición del sumador de PC+4               
PC_4 <= PC+4;

-------------------------------------------------------------------------------------------------------------------------
--CONFIRMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAR.
--Manejo de I_Addr (Este puerto despues se conecta a la memoria en el TB)
I_Addr <= PC;
--CONFIRMAR, porque estoy escribiendo directamene a un puerto del procesador.
--CONFIRMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAR.
-------------------------------------------------------------------------------------------------------------------------

--Definición de registro de segmentación IF/ID
reg_IF_ID:      process(Clk,Reset) 
                begin
                    if(Reset = '1') then
                        Instruction <= (others => '0');
                        ID_PC_4 <= (others => '0');
                    elsif  (rising_edge(Clk)) then
                        --asigno valores a ambas señales
                        ID_PC_4 <= PC_4;
                        Instruction <= I_DataIn;
                    end if;
                end process;
-------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------              
end processor_arq;
