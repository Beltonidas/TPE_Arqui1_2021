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
   signal EX_sign_ext, EX_data2_rd_rg, EX_data1_rd_rg, EX_PC_4: std_logic_vector (31 downto 0); --Registro de segmentacion
      
   signal RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch: std_logic;
   signal AluOp: std_logic_vector(2 downto 0);
   signal Reg_destino0, Reg_destino1: std_logic_vector (4 downto 0);
---------Fin Sección Instruction Decode---------

---------Inicio sección Execution--------------
component P1c is port( --ALU
            a : in std_logic_vector (31 downto 0);
            b : in std_logic_vector (31 downto 0);
            control: in std_logic_vector (2 downto 0);
            output: out std_logic_vector (31 downto 0);
            zero : out std_logic  
        );
end component;

    signal ALU_b,ALU_result, Add_result: std_logic_vector (31 downto 0);
    signal reg_destino:std_logic_vector (4 downto 0);
    signal ALU_zero: std_logic;
    signal ALU_ctrl: std_logic_vector(2 downto 0);
    signal funct: std_logic_vector(5 downto 0);
    signal MEM_RegWrite, MEM_MemtoReg, MEM_Branch, MEM_MemWrite, MEM_MemRead, MEM_ALU_zero:std_logic;
    signal MEM_Add_result, MEM_ALU_result, MEM_data2_rd_rg:std_logic_vector(31 downto 0);
    signal MEM_reg_destino: std_logic_vector (4 downto 0);
------------fin sección Execution--------------
------------inicio sección Memory--------------
    signal mem_reg_data: std_logic_vector (31 downto 0);
------------fin sección Memory--------------
---------Inicio sección Write Back--------------
    signal dato_reg_destino_wb: std_logic_vector(31 downto 0);
    signal reg_Destino_wb: std_logic_vector(4 downto 0);
    signal WB_RegWrite, WB_MemtoReg: std_logic;
    signal WB_mem_reg_data, WB_ALU_result: std_logic_vector(31 downto 0);
    signal WB_reg_destino: std_logic_vector (4 downto 0);
    
------------fin sección Write Back--------------
begin
I_DataOut <= x"00000000"; 	
Reg_bank: p1d port map( --Connexión del banco de registros
        clk => Clk,
        rst => Reset,
        wr  => WB_RegWrite, --ID_PC_4
        reg1_rd => reg1_rd_rg, --reg1_rd_rg <= Instruction(25 downto 21);
        reg2_rd => reg2_rd_rg,
        reg_wr  => WB_reg_destino,
        data_wr => dato_reg_destino_wb,   --¿ACA PODRIA CONECTAR DIRECTO DEL WB?
        data1_rd => data1_rd_rg, 
        data2_rd => data2_rd_rg
    );

ALU: P1c port map( --Connexión de la ALU
         a => EX_data1_rd_rg,
         b => ALU_b,
         control => ALU_ctrl,
         output => ALU_result,  
         zero => ALU_zero
    );     
    
--Multiplexor que elige instrucción a meter en Program Conter
PC_next <= PC_4 when PCSrc='0' else
          MEM_Add_result;

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
I_WrStb <= '0';
I_RdStb <= '1'; --¿Esto es correcto para que siempre lea?
I_Addr <= PC;
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

--Estos 2 los valores a elegir en el mux de la etapa EX
Reg_destino0 <= Instruction(20 downto 16);
Reg_destino1 <= Instruction(15 downto 11);

--Definicion unidad de extension de signo
sign_ext <= x"0000" & Instruction(15 downto 0) when Instruction(15) = '0' else
        x"FFFF" & Instruction(15 downto 0);

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
    when others => --Tener cuidado y ocnsultar por el others
       RegDst <= '1';
       ALUSrc <= '0';
       MemtoReg <= '0';
       RegWrite <= '1';
       MemRead <= '0';
       MemWrite <= '0';
       Branch <= '0';
       AluOp <= "010";
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
                    EX_sign_ext <= x"00000000";             
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
                    EX_sign_ext <= sign_ext;
                end if;
            end process;
-------------------------------------------------------------------------------------------------------------------------
--ID/EX
-------------------------------------------------------------------------------------------------------------------------             
-- Definición de Unidad ALU Control
process (EX_sign_ext,EX_AluOp)
begin
    funct <= EX_sign_ext(5 downto 0);
    case EX_AluOp is
       when "000" => ALU_ctrl <= "010";
       when "001" => ALU_ctrl <= "110";
       when "011" => ALU_ctrl <= "100";
       when "100" => ALU_ctrl <= "000";
       when "101" => ALU_ctrl <= "001";
       when "010" => 
            case funct is
                when "100000" => ALU_ctrl <="010";
                when "100010" => ALU_ctrl <="110";
                when "100100" => ALU_ctrl <="000";
                when "100101" => ALU_ctrl <="001";
                when "101010" => ALU_ctrl <="111";
                when others => ALU_ctrl <="010";
            end case;
       when others => ALU_ctrl <="010";
    end case;
end process;


ALU_b <= EX_data2_rd_rg when EX_ALUSrc='0' else
        EX_sign_ext;  

reg_destino <= EX_Reg_destino0  when EX_RegDst='0' else
               EX_Reg_destino1;
               
Add_result <= EX_PC_4 + (EX_sign_ext(29 downto 0) & "00");

--Definición de registro de segmentación EX/MEM
reg_EX_MEM:      process(Clk,Reset) 
                begin
                    if(Reset = '1') then
                        MEM_Add_result <= (others => '0');
                        MEM_ALU_result <= (others => '0');
                        MEM_data2_rd_rg <= (others => '0');
                        MEM_reg_destino <= (others => '0');
                        MEM_RegWrite <= '0';
                        MEM_MemtoReg <= '0';
                        MEM_Branch <= '0';
                        MEM_MemWrite <= '0';
                        MEM_MemRead  <= '0';
                        MEM_ALU_zero <= '0';
                    elsif  (rising_edge(Clk)) then
                        MEM_Add_result <= Add_result;
                        MEM_ALU_zero <= ALU_zero;
                        MEM_ALU_result <= ALU_result;
                        MEM_data2_rd_rg <= EX_data2_rd_rg;
                        MEM_reg_destino <= reg_destino;
                        MEM_RegWrite <= EX_RegWrite;
                        MEM_MemtoReg <= EX_MemtoReg;
                        MEM_Branch <= EX_Branch;
                        MEM_MemWrite <= EX_MemWrite;
                        MEM_MemRead  <= EX_MemRead;
                    end if;
                end process;
-------------------------------------------------------------------------------------------------------------------------
--EX/MEM
-------------------------------------------------------------------------------------------------------------------------             
PCSrc <= MEM_Branch and MEM_ALU_zero;

--Lectura de memoria externa
D_Addr <= MEM_ALU_result;
D_DataOut <= MEM_data2_rd_rg;
D_RdStb <= MEM_MemRead;
D_WrStb <= MEM_MemWrite;
mem_reg_data <= D_DataIn;

--Definición de registro de segmentación MEM/WB
reg_MEM_WB:      process(Clk,Reset) 
                begin
                    if(Reset = '1') then
                        WB_RegWrite <= '0';
                        WB_MemtoReg <= '0';
                        WB_mem_reg_data <= (others => '0');
                        WB_ALU_result <= (others => '0');
                        WB_reg_destino <= (others => '0');
                    elsif  (rising_edge(Clk)) then
                        WB_RegWrite <= MEM_RegWrite;
                        WB_MemtoReg <= MEM_MemtoReg;
                        WB_mem_reg_data <= mem_reg_data;
                        WB_ALU_result <= MEM_ALU_result;
                        WB_reg_destino <= MEM_reg_destino;
                    end if;
                end process;
-------------------------------------------------------------------------------------------------------------------------
--MEM/WB
-------------------------------------------------------------------------------------------------------------------------
dato_reg_destino_wb <= WB_mem_reg_data when WB_MemtoReg='0' else
                       WB_ALU_result;

end processor_arq;
