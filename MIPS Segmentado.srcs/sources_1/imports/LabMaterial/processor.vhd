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
   signal rst_rg, wr_rg: std_logic;
   signal reg1_rd_rg, reg2_rd_rg, reg_wr_rg: std_logic_vector (4 downto 0);
   signal data_wr_rg, data1_rd_rg, data2_rd_rg: std_logic_vector (31 downto 0);
   signal Special: std_logic_vector(5 downto 0);
   signal sign_ext:std_logic_vector (31 downto 0);
   
   signal EX_RegDst, EX_ALUSrc, EX_MemtoReg, EX_RegWrite, EX_MemRead, EX_MemWrite, EX_Branch:std_logic;--Registro de segmentacion
   signal EX_AluOp:std_logic_vector(2 downto 0); --Registro de segmentacion
   signal EX_Reg_Destino0,  EX_Reg_Destino1:std_logic_vector (4 downto 0); --Registro de segmentacion
   signal EX_sign_ext, EX_data2_rd_rg, EX_data1_rd_rg, EX_PC_4 : std_logic_vector (31 downto 0); --Registro de segmentacion
      
   signal RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch: std_logic;
   signal AluOp: std_logic_vector(2 downto 0);
   signal Reg_destino0, Reg_destino1: std_logic_vector (4 downto 0);
---------Fin Sección Instruction Decode---------

---------Inicio sección Execution--------------
------------fin sección Execution--------------

---------Inicio sección Write Back--------------
    signal WB_RegWrite: std_logic;
    signal dato_reg_destino_wb: std_logic_vector(31 downto 0);
    signal reg_Destino_wb: std_logic_vector(4 downto 0);
------------fin sección Write Back--------------
begin 	
Reg_bank: p1d port map( --Connexión del banco de registros
        clk => Clk,
        rst => rst_rg,
        wr  => WB_RegWrite, --ID_PC_4
        reg1_rd => reg1_rd_rg, --reg1_rd_rg <= Instruction(25 downto 21);
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
--Fetch/ID
-------------------------------------------------------------------------------------------------------------------------
--Desglosamos la instrucción para elegir el numero de registros
reg1_rd_rg <= Instruction(25 downto 21); --Seleccionaoms los registros
reg2_rd_rg <= Instruction(20 downto 16);

data1_rd_rg <= reg1_rd_rg;
data2_rd_rg <= reg2_rd_rg; --Leemos los registros que anteriormente seleciconamos 

--Definimos registro de escritura final
reg_wr_rg <= reg_Destino_wb;
data_wr_rg <= dato_reg_destino_wb;

--Estos 2 los valores a elegir en el mux de la etapa EX
Reg_destino0 <= Instruction(20 downto 16);
Reg_destino1 <= Instruction(15 downto 11);

--Definición de Unidad de extensión de signo.
process (Instruction)  
    --Confirmar lista de sensibilidad y no haber extendido al reves, o tomado los bits que no eran (31 a 15) o (15 a 0)
begin
    if (Instruction(15) = '1') then
    sign_ext <=  x"FFFF" & Instruction(15 downto 0);
    else
    sign_ext <=  x"0000" & Instruction(15 downto 0);
    end if;
end process;
--CONFIRMAR QUE NO HAYA HECHO COSAS AL REVES

--Definición de Unidad de control, todo va a parar al registro de segmentación (eventualmente)
process (Instruction)
begin
    Special <= Instruction(31 downto 26);
    case Special is
   when "000000" => -- R-Type
       RegDst <= '1';
       ALUSrc <= '0';
       MemtoReg <= '0';
       RegWrite <= '1';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "010";  
       	
   when "100011" => -- LW
       RegDst <= '0';
       ALUSrc <= '1';
       MemtoReg <= '1';
       RegWrite <= '1';
       MemRead <= '1';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "000";
       
   when "101011" => -- SW
       RegDst <= '1';
       ALUSrc <= '1';
       MemtoReg <= '0';
       RegWrite <= '0';
       MemRead <= '0';
       MemWrite <= '1';
       Branch <= '0';
       AluOp <= "000";
       
   when "000100" => -- BEQ
       RegDst <= '1';
       ALUSrc <= '0';
       MemtoReg <= '0';
       RegWrite <= '0';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '1';
       AluOp <= "001";
   
   when "001111" => -- LUI
       RegDst <= '0';
       ALUSrc <= '1';
       MemtoReg <= '0';
       RegWrite <= '1';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "011";
       
    when "001000" => -- ADDI
       RegDst <= '0';
       ALUSrc <= '1';
       MemtoReg <= '0';
       RegWrite <= '1';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "000";
       
    when "001100" => -- ANDI
       RegDst <= '0';
       ALUSrc <= '1';
       MemtoReg <= '0';
       RegWrite <= '1';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "100";
       
    when "001101" => -- ORI
       RegDst <= '0';
       ALUSrc <= '1';
       MemtoReg <= '0';
       RegWrite <= '1';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "101";
    --when others => Tener cuidado y ocnsultar por el others
    end case;
end process;

--Definición de registro de segmentación ID/EX
reg_ID_EX:  process(Clk,Reset)
            begin
                if(Reset = '1') then
                    EX_RegDst <= '0';
                    EX_ALUSrc <= '0';
                    EX_MemtoReg <= '0';
                    EX_RegWrite <= '0';
                    EX_MemRead <= '0';
                    EX_MemWrite <= '0';
                    EX_Branch <= '0';
                    EX_AluOp <= "000";
                    EX_Reg_destino0 <= "00000";
                    EX_Reg_destino1 <= "00000";
                    EX_PC_4 <= x"00000000";
                    EX_data1_rd_rg <= x"00000000";
                    EX_data2_rd_rg <= x"00000000";                    
                elsif(rising_edge(Clk)) then
                    EX_RegDst <= RegDst;
                    EX_ALUSrc <= ALUSrc;
                    EX_MemtoReg <= MemtoReg;
                    EX_RegWrite <= RegWrite;
                    EX_MemRead <= MemRead;
                    EX_MemWrite <= MemWrite;
                    EX_Branch <= Branch;
                    EX_AluOp <= AluOp;
                    EX_Reg_destino0 <= Reg_destino0;
                    EX_Reg_destino1 <= Reg_destino1;
                    EX_PC_4 <= ID_PC_4;
                    EX_data1_rd_rg <= data1_rd_rg;
                    EX_data2_rd_rg <= data2_rd_rg;
                end if;
            end process;
-------------------------------------------------------------------------------------------------------------------------
--ID/EX
-------------------------------------------------------------------------------------------------------------------------             
end processor_arq;
