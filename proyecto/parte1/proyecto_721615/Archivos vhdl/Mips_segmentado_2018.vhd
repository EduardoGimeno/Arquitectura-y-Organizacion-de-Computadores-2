----------------------------------------------------------------------------------
-- Description: Mips segmentado tal y como lo hemos estudiado en clase. Sus caracter韘ticas son:
-- Saltos 1-retardados
-- instrucciones aritm閠icas, LW, SW y BEQ
-- MI y MD de 128 palabras de 32 bits
-- Registro de salida de 32 bits mapeado en la direcci髇 FFFFFFFF. Si haces un SW en esa direcci髇 se escribe en este registro y no en la memoria
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MIPs_segmentado is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  output : out  STD_LOGIC_VECTOR (31 downto 0));
end MIPs_segmentado;

architecture Behavioral of MIPs_segmentado is
component reg32 is
    Port ( Din : in  STD_LOGIC_VECTOR (31 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;
---------------------------------------------------------------

component adder32 is
    Port ( Din0 : in  STD_LOGIC_VECTOR (31 downto 0);
           Din1 : in  STD_LOGIC_VECTOR (31 downto 0);
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component mux2_1 is
  Port (   DIn0 : in  STD_LOGIC_VECTOR (31 downto 0);
           DIn1 : in  STD_LOGIC_VECTOR (31 downto 0);
		   ctrl : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component memoriaRAM_D is port (
		  CLK : in std_logic;
		  ADDR : in std_logic_vector (31 downto 0); --Dir 
          Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
          WE : in std_logic;		-- write enable	
		  RE : in std_logic;		-- read enable		  
		  Dout : out std_logic_vector (31 downto 0));
end component;

component memoriaRAM_I is port (
		  CLK : in std_logic;
		  ADDR : in std_logic_vector (31 downto 0); --Dir 
          Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
          WE : in std_logic;		-- write enable	
		  RE : in std_logic;		-- read enable		  
		  Dout : out std_logic_vector (31 downto 0));
end component;

component Banco_ID is
 Port (  IR_in : in  STD_LOGIC_VECTOR (31 downto 0); -- instrucci髇 leida en IF
         PC4_in:  in  STD_LOGIC_VECTOR (31 downto 0); -- PC+4 sumado en IF
		 clk : in  STD_LOGIC;
		 reset : in  STD_LOGIC;
         load : in  STD_LOGIC;
         IR_ID : out  STD_LOGIC_VECTOR (31 downto 0); -- instrucci髇 en la etapa ID
         PC4_ID:  out  STD_LOGIC_VECTOR (31 downto 0)); -- PC+4 en la etapa ID
end component;

COMPONENT BReg
    PORT(
         clk : IN  std_logic;
		 reset : in  STD_LOGIC;
         RA : IN  std_logic_vector(4 downto 0);
         RB : IN  std_logic_vector(4 downto 0);
         RW : IN  std_logic_vector(4 downto 0);
         BusW : IN  std_logic_vector(31 downto 0);
         RegWrite : IN  std_logic;
         BusA : OUT  std_logic_vector(31 downto 0);
         BusB : OUT  std_logic_vector(31 downto 0)
        );
END COMPONENT;

component Ext_signo is
    Port ( inm : in  STD_LOGIC_VECTOR (15 downto 0);
           inm_ext : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component two_bits_shifter is
    Port ( Din : in  STD_LOGIC_VECTOR (31 downto 0);
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component UC is
    Port ( IR_op_code : in  STD_LOGIC_VECTOR (5 downto 0);
           Branch : out  STD_LOGIC;
           RegDst : out  STD_LOGIC;
           ALUSrc : out  STD_LOGIC;
           -- Nueva se馻l FP
		   FP_add	: out  STD_LOGIC; -- indica que es una suma en FP
		   -- Fin Nueva se馻l
           MemWrite : out  STD_LOGIC;
           MemRead : out  STD_LOGIC;
           MemtoReg : out  STD_LOGIC;
           RegWrite : out  STD_LOGIC);
end component;
-- Unidad de detecci髇 de riesgos
component UD is
    Port ( 	Reg_Rs_ID: in  STD_LOGIC_VECTOR (4 downto 0); --registros Rs y Rt en la etapa ID
		   Reg_Rt_ID	: in  STD_LOGIC_VECTOR (4 downto 0);
			MemRead_EX	: in std_logic; -- informaci贸n sobre la instrucci贸n en EX (destino, si lee de memoria y si escribe en registro)
			RegWrite_EX	: in std_logic;
			RW_EX			: in  STD_LOGIC_VECTOR (4 downto 0);
			RegWrite_Mem	: in std_logic;-- informacion sobre la instruccion en Mem (destino y si escribe en registro)
			RW_Mem			: in  STD_LOGIC_VECTOR (4 downto 0);
			IR_op_code	: in  STD_LOGIC_VECTOR (5 downto 0); -- c贸digo de operaci贸n de la instrucci贸n en IEEE
            PCSrc			: in std_logic; -- 1 cuando se produce un salto 0 en caso contrario
			FP_add_EX	: in std_logic; -- Indica si la instrucci贸n en EX es un ADDFP
			FP_done		: in std_logic; -- Informa cuando la operaci贸n de suma en FP ha terminado
			Kill_IF		: out  STD_LOGIC; -- Indica que la instrucci贸n en IF no debe ejecutarse (fallo en la predicci贸n de salto tomado)
			Parar_ID		: out  STD_LOGIC; -- Indica que las etapas ID y previas deben parar
			Parar_EX		: out  STD_LOGIC); -- Indica que las etapas EX y previas deben parar
end component;

COMPONENT Banco_EX
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         load : IN  std_logic;
         busA : IN  std_logic_vector(31 downto 0);
         busB : IN  std_logic_vector(31 downto 0);
         busA_EX : OUT  std_logic_vector(31 downto 0);
         busB_EX : OUT  std_logic_vector(31 downto 0);
		 inm_ext: IN  std_logic_vector(31 downto 0);
		 inm_ext_EX: OUT  std_logic_vector(31 downto 0);
         RegDst_ID : IN  std_logic;
         ALUSrc_ID : IN  std_logic;
         MemWrite_ID : IN  std_logic;
         MemRead_ID : IN  std_logic;
         MemtoReg_ID : IN  std_logic;
         RegWrite_ID : IN  std_logic;
         RegDst_EX : OUT  std_logic;
         ALUSrc_EX : OUT  std_logic;
         MemWrite_EX : OUT  std_logic;
         MemRead_EX : OUT  std_logic;
         MemtoReg_EX : OUT  std_logic;
         RegWrite_EX : OUT  std_logic;
		 -- FP
		 FP_add_ID : in  STD_LOGIC;
		 FP_add_EX : out  STD_LOGIC;
		 --Fin FP
		 ALUctrl_ID: in STD_LOGIC_VECTOR (2 downto 0);
		 ALUctrl_EX: out STD_LOGIC_VECTOR (2 downto 0);
         Reg_Rt_ID : IN  std_logic_vector(4 downto 0);
         Reg_Rd_ID : IN  std_logic_vector(4 downto 0);
		 Reg_Rs_ID : IN  std_logic_vector(4 downto 0);
         Reg_Rt_EX : OUT  std_logic_vector(4 downto 0);
         Reg_Rd_EX : OUT  std_logic_vector(4 downto 0);
		 Reg_Rs_EX : OUT  std_logic_vector(4 downto 0)
        );
    END COMPONENT;
-- Unidad de anticipaci髇 de operandos
-- Ahora mismo no hace nada. La ten閕s que dise馻r
    COMPONENT UA
	Port(
			Reg_Rs_EX: IN  std_logic_vector(4 downto 0); 
			Reg_Rt_EX: IN  std_logic_vector(4 downto 0);
			RegWrite_MEM: IN std_logic;
			RW_MEM: IN  std_logic_vector(4 downto 0);
			RegWrite_WB: IN std_logic;
			RW_WB: IN  std_logic_vector(4 downto 0);
			MUX_ctrl_A: out std_logic_vector(1 downto 0);
			MUX_ctrl_B: out std_logic_vector(1 downto 0)
		);
	end component;
-- Mux 4 a 1
-- Se utiliza para la anticipaci髇 de operandos
	component mux4_1_32bits is
	Port ( DIn0 : in  STD_LOGIC_VECTOR (31 downto 0);
		   DIn1 : in  STD_LOGIC_VECTOR (31 downto 0);
		   DIn2 : in  STD_LOGIC_VECTOR (31 downto 0);
		   DIn3 : in  STD_LOGIC_VECTOR (31 downto 0);
		   ctrl : in  std_logic_vector(1 downto 0);
		   Dout : out  STD_LOGIC_VECTOR (31 downto 0));
	end component;
	
	COMPONENT ALU
    PORT(
         DA : IN  std_logic_vector(31 downto 0);
         DB : IN  std_logic_vector(31 downto 0);
         ALUctrl : IN  std_logic_vector(2 downto 0);
         Dout : OUT  std_logic_vector(31 downto 0)
               );
    END COMPONENT;
	-- Sumador en FP
	component FPP_ADD_SUB is
	port(A      : in  std_logic_vector(31 downto 0);
       B      : in  std_logic_vector(31 downto 0);
       clk    : in  std_logic;
       reset  : in  std_logic;
       go     : in  std_logic;
       done   : out std_logic;
       result : out std_logic_vector(31 downto 0)
       );
	end component;
	 
	component mux2_5bits is
	Port ( DIn0 : in  STD_LOGIC_VECTOR (4 downto 0);
		   DIn1 : in  STD_LOGIC_VECTOR (4 downto 0);
		   ctrl : in  STD_LOGIC;
		   Dout : out  STD_LOGIC_VECTOR (4 downto 0));
	end component;
	
COMPONENT Banco_MEM
    PORT(
         ALU_out_EX : IN  std_logic_vector(31 downto 0);
         ALU_out_MEM : OUT  std_logic_vector(31 downto 0);
         clk : IN  std_logic;
         reset : IN  std_logic;
         load : IN  std_logic;
         MemWrite_EX : IN  std_logic;
         MemRead_EX : IN  std_logic;
         MemtoReg_EX : IN  std_logic;
         RegWrite_EX : IN  std_logic;
         MemWrite_MEM : OUT  std_logic;
         MemRead_MEM : OUT  std_logic;
         MemtoReg_MEM : OUT  std_logic;
         RegWrite_MEM : OUT  std_logic;
         BusB_EX : IN  std_logic_vector(31 downto 0);
         BusB_MEM : OUT  std_logic_vector(31 downto 0);
         RW_EX : IN  std_logic_vector(4 downto 0);
         RW_MEM : OUT  std_logic_vector(4 downto 0)
        );
    END COMPONENT;
 
    COMPONENT Banco_WB
    PORT(
         ALU_out_MEM : IN  std_logic_vector(31 downto 0);
         ALU_out_WB : OUT  std_logic_vector(31 downto 0);
         MEM_out : IN  std_logic_vector(31 downto 0);
         MDR : OUT  std_logic_vector(31 downto 0);
         clk : IN  std_logic;
         reset : IN  std_logic;
         load : IN  std_logic;
         MemtoReg_MEM : IN  std_logic;
         RegWrite_MEM : IN  std_logic;
         MemtoReg_WB : OUT  std_logic;
         RegWrite_WB : OUT  std_logic;
         RW_MEM : IN  std_logic_vector(4 downto 0);
         RW_WB : OUT  std_logic_vector(4 downto 0)
        );
    END COMPONENT; 
	
	COMPONENT mux2_1_1bit
	PORT(  DIn0 : in  STD_LOGIC;
		   DIn1 : in  STD_LOGIC;
		   ctrl : in  STD_LOGIC;
		   Dout : out  STD_LOGIC);
	end component;
		 
CONSTANT ARIT : STD_LOGIC_VECTOR (5 downto 0) := "000001";
signal load_PC, PCSrc, RegWrite_ID, RegWrite_EX, RegWrite_MEM, RegWrite_WB, Z, Branch, RegDst_ID, RegDst_EX, ALUSrc_ID, ALUSrc_EX: std_logic;
signal MemtoReg_ID, MemtoReg_EX, MemtoReg_MEM, MemtoReg_WB, MemWrite_ID, MemWrite_EX, MemWrite_MEM, MemRead_ID, MemRead_EX, MemRead_MEM: std_logic;
signal PC_in, PC_out, four, PC4, Dirsalto_ID, IR_in, IR_ID, PC4_ID, inm_ext_EX, ALU_Src_out, cero : std_logic_vector(31 downto 0);
signal BusW, BusA, BusB, BusA_EX, BusB_EX, BusB_MEM, inm_ext, inm_ext_x4, ALU_out_EX, ALU_out_MEM, ALU_out_WB, Mem_out, MDR : std_logic_vector(31 downto 0);
signal RW_EX, RW_MEM, RW_WB, Reg_Rs_ID, Reg_Rs_EX, Reg_Rt_ID, Reg_Rd_EX, Reg_Rt_EX: std_logic_vector(4 downto 0);
signal ALUctrl_ID, ALUctrl_EX : std_logic_vector(2 downto 0);
signal ADD_FP_out, ALU_INT_out, Mux_A_out, Mux_B_out: std_logic_vector(31 downto 0);
signal IR_op_code: std_logic_vector(5 downto 0);
signal FP_add_ID, FP_add_EX, FP_done, FP_mux: std_logic;
signal MUX_ctrl_A, MUX_ctrl_B : std_logic_vector(1 downto 0);
signal parar_EX, parar_ID, RegWrite_EX_mux_out, Kill_IF, reset_ID, load_ID, load_EX: std_logic;
signal MemWrite_EX2, MemRead_EX2, RegWrite_EX2: std_logic;
signal MemWrite_ID2, MemRead_ID2, RegWrite_ID2, FP_add_ID2: std_logic;
begin
pc: reg32 port map (	Din => PC_in, clk => clk, reset => reset, load => load_PC, Dout => PC_out);
------------------------------------------------------------------------------------
-- load_PC vale '1' porque en la versi髇 actual el procesador no para nunca
-- Si queremos detener una instrucci髇 en la etapa fetch habr?que ponerlo a '0'
load_PC <= parar_ID and parar_EX; 
------------------------------------------------------------------------------------
-- constantes que se usan en el c骴igo;
four <= "00000000000000000000000000000100";
cero <= "00000000000000000000000000000000";
-- Adder que hace PC+4
adder_4: adder32 port map (Din0 => PC_out, Din1 => four, Dout => PC4);
------------------------------------------------------------------------------------
-- Este mux elige entre PC+4 o la Direcci髇 de salto generada en ID
muxPC: mux2_1 port map (Din0 => PC4, DIn1 => Dirsalto_ID, ctrl => PCSrc, Dout => PC_in);
------------------------------------------------------------------------------------
-- si leemos una instrucci髇 equivocada tenemos que modificar el c骴igo de operaci髇 antes de almacenarlo en memoria
Mem_I: memoriaRAM_I PORT MAP (CLK => CLK, ADDR => PC_out, Din => cero, WE => '0', RE => '1', Dout => IR_in);
------------------------------------------------------------------------------------
-- el load vale uno porque este procesador no para nunca. Si queremos que una instrucci髇 no avance habr?que poner el load a '0'
-- Los registros tienen reset s韓crono que se puede utilizar para poner a cero su contenido en el ciclo siguiente. 
-- Ahora mismo s髄o se activa si llega el reset global.
reset_ID <= reset or (kill_IF and load_ID);
-- load_ID vale '1' porque en la versi髇 actual el procesador no para nunca
-- Si queremos detener una instrucci髇 en la etapa fetch habr?que ponerlo a '0'
load_ID <= parar_ID and parar_EX;
-- Registros que separan las etapas IF e ID
Banco_IF_ID: Banco_ID port map (	IR_in => IR_in, PC4_in => PC4, clk => clk, reset => reset_ID, load => load_ID, IR_ID => IR_ID, PC4_ID => PC4_ID);
--
------------------------------------------Etapa ID-------------------------------------------------------------------
-- se馻les que indican los registros RS, Rt y el c骴igo de op
Reg_Rs_ID <= IR_ID(25 downto 21);
Reg_Rt_ID <= IR_ID(20 downto 16);
IR_op_code <= IR_ID(31 downto 26);
-- BR
Register_bank: BReg PORT MAP (clk => clk, reset => reset, RA => Reg_Rs_ID, RB => Reg_Rt_ID, RW => RW_WB, BusW => BusW, 
									RegWrite => RegWrite_WB, BusA => BusA, BusB => BusB);
-------------------------------------------------------------------------------------
-- Extiende de 16 a 32
sign_ext: Ext_signo port map (inm => IR_ID(15 downto 0), inm_ext => inm_ext);
-- X4
two_bits_shift: two_bits_shifter	port map (Din => inm_ext, Dout => inm_ext_x4);
-- Calcula la @salto
adder_dir: adder32 port map (Din0 => inm_ext_x4, Din1 => PC4_ID, Dout => Dirsalto_ID);
-- Comparador para los BEQ
Z <= '1' when (busA=busB) else '0';

------------------------Unidad de detenci髇-----------------------------------
-- Deb閕s completar la unidad y conectarla con el resto del procesador para que sus 髍denes se cumplan.
-- Ahora mismo sus salidas son 0 y no se usan en ning鷑 sitio
-------------------------------------------------------------------------------------

Unidad_detenci髇_riesgos: UD port map (	Reg_Rs_ID => Reg_Rs_ID, Reg_Rt_ID => Reg_Rt_ID, MemRead_EX => MemRead_EX, RW_EX => RW_EX, RegWrite_EX => RegWrite_EX,
										RW_Mem => RW_Mem, RegWrite_Mem => RegWrite_Mem, IR_op_code => IR_op_code, PCSrc => PCSrc, FP_add_EX => FP_add_EX, FP_done => FP_done,
										kill_IF => kill_IF, parar_ID => parar_ID, parar_EX => parar_EX );
-------------------------------------------------------------------------------------
-- UC
UC_seg: UC port map (IR_op_code => IR_op_code, Branch => Branch, RegDst => RegDst_ID,  ALUSrc => ALUSrc_ID, MemWrite => MemWrite_ID,  
							MemRead => MemRead_ID, MemtoReg => MemtoReg_ID, RegWrite => RegWrite_ID, FP_add => FP_add_ID);
-------------------------------------------------------------------------------------
-- Ahora mismo s髄o esta implementada la instrucci髇 de salto BEQ. Si es una instrucci髇 de salto y se activa la se馻l Z se carga la direcci髇 de salto, sino PC+4 	
PCSrc <= Branch AND Z; 				
-- si la operaci髇 es aritm閠ica (es decir: IR_op_code= "000001") miro el campo funct
-- como s髄o hay 4 operaciones en la alu, basta con los bits menos significativos del campo func de la instrucci髇	
-- si no es aritm閠ica le damos el valor de la suma (000)
ALUctrl_ID <= IR_ID(2 downto 0) when IR_op_code= ARIT else "000";
------------ mux que selecciona entre MemWrite_ID y 0 en caso de parada
mux_MemWriteID: mux2_1_1bit port map (DIn0 => '0', DIn1 => MemWrite_ID, ctrl => parar_ID, Dout => MemWrite_ID2);
----------
-- mux que selecciona entre MemRead_ID y 0 en caso de parada
mux_MemReadID: mux2_1_1bit port map (DIn0 => '0', DIn1 => MemRead_ID, ctrl => parar_ID, Dout => MemRead_ID2);
----------
-- mux que selecciona entre RegWrite_ID y 0 en caso de parada
mux_RegWriteID: mux2_1_1bit port map (DIn0 => '0', DIn1 => RegWrite_ID, ctrl => parar_ID, Dout => RegWrite_ID2);
----------
-- mux que selecciona entre FP_add_ID y 0 en caso de parada
mux_FPaddID: mux2_1_1bit port map (DIn0 => '0', DIn1 => FP_add_ID, ctrl => parar_ID, Dout => FP_add_ID2);
-- load_EX vale '1' porque en la versi髇 actual el procesador no para nunca
-- Si queremos detener una instrucci髇 en la etapa fetch habr?que ponerlo a '0'y pensar qu?se env韆 a la etapa siguiente
load_EX <= parar_EX;
-- Banco que separa las etapas de ID y EX
Banco_ID_EX: Banco_EX PORT MAP ( clk => clk, reset => reset, load => load_EX, busA => busA, busB => busB, busA_EX => busA_EX, busB_EX => busB_EX,
											RegDst_ID => RegDst_ID, ALUSrc_ID => ALUSrc_ID, MemWrite_ID => MemWrite_ID2, MemRead_ID => MemRead_ID2,
											MemtoReg_ID => MemtoReg_ID, RegWrite_ID => RegWrite_ID2, RegDst_EX => RegDst_EX, ALUSrc_EX => ALUSrc_EX,
											MemWrite_EX => MemWrite_EX, MemRead_EX => MemRead_EX, MemtoReg_EX => MemtoReg_EX, RegWrite_EX => RegWrite_EX,
											-- FP
											FP_add_ID => FP_add_ID2, 
											FP_add_EX => FP_add_EX,
											--Fin FP
											ALUctrl_ID => ALUctrl_ID, ALUctrl_EX => ALUctrl_EX, inm_ext => inm_ext, inm_ext_EX=> inm_ext_EX,
											Reg_Rt_ID => IR_ID(20 downto 16), Reg_Rd_ID => IR_ID(15 downto 11),
											Reg_Rs_ID => IR_ID(25 downto 21),
											Reg_Rt_EX => Reg_Rt_EX, Reg_Rd_EX => Reg_Rd_EX, Reg_Rs_EX => Reg_Rs_EX);			
							
--
------------------------------------------Etapa EX-------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Unidad de anticipaci髇 incompleta. Ahora mismo selecciona siempre la entrada 0
-- Entradas: Reg_Rs_EX, Reg_Rt_EX, RegWrite_MEM, RW_MEM, RegWrite_WB, RW_WB
-- Salidas: MUX_ctrl_A, MUX_ctrl_B

Unidad_Ant: UA port map (	Reg_Rs_EX => Reg_Rs_EX, Reg_Rt_EX => Reg_Rt_EX, RegWrite_MEM => RegWrite_MEM, RW_MEM => RW_MEM,
							RegWrite_WB => RegWrite_WB, RW_WB => RW_WB, MUX_ctrl_A => MUX_ctrl_A, MUX_ctrl_B => MUX_ctrl_B);
-- Muxes para la anticipaci髇
-- Su salida no se usa. Hay que conectarla donde proceda
Mux_A: mux4_1_32bits port map  ( DIn0 => BusA_EX, DIn1 => ALU_out_MEM, DIn2 => busW, DIn3 => cero, ctrl => MUX_ctrl_A, Dout => Mux_A_out);
Mux_B: mux4_1_32bits port map  ( DIn0 => BusB_EX, DIn1 => ALU_out_MEM, DIn2 => busW, DIn3 => cero, ctrl => MUX_ctrl_B, Dout => Mux_B_out);
----------------------------------------------------------------------------------
muxALU_src: mux2_1 port map (Din0 => Mux_B_out, DIn1 => inm_ext_EX, ctrl => ALUSrc_EX, Dout => ALU_Src_out);

ALU_MIPs: ALU PORT MAP ( DA => Mux_A_out, DB => ALU_Src_out, ALUctrl => ALUctrl_EX, Dout => ALU_INT_out);

-- Sumador FP. El n鷐ero de ciclos que necesita es variable en funci髇 de los operandos. 
-- FP_add_EX indica al sumador que debe realizar una suma en FP. Cuando termina activa la se馻l done. 
-- La salida s髄o dura un ciclo. 
ADD_FP: FPP_ADD_SUB port map (A => Mux_A_out,B => Mux_B_out, clk => clk, reset => reset, go => FP_add_EX, done => FP_done, result => ADD_FP_out);

------------------------------------------
-- la siguiente l韓ea es un mux que elige entre la salida de la ALU de enteros y la del sumador FP
-- ahora mismo se coje siempre la de enteros. Hay que coger la de FP cuando proceda
FP_mux <= FP_done;
ALU_out_EX <= ADD_FP_out when (FP_mux='1') else ALU_INT_out;
--------------------------------------------
-- mux que elige el destino correcto entre las dos opciones (Rt o Rd) 
mux_dst: mux2_5bits port map (Din0 => Reg_Rt_EX, DIn1 => Reg_Rd_EX, ctrl => RegDst_EX, Dout => RW_EX);
-----------
--- mux que selecciona entre MemWrite_EX y 0 en caso de parada
mux_MemWriteEX: mux2_1_1bit port map (DIn0 => '0', DIn1 => MemWrite_EX, ctrl => Parar_EX, Dout => MemWrite_EX2);
-----------
--- mux que selecciona entre MemRead_EX y 0 en caso de parada
mux_MemReadEX: mux2_1_1bit port map (DIn0 => '0', DIn1 => MemRead_EX, ctrl => Parar_EX, Dout => MemRead_EX2);
-----------
--- mux que selecciona entre RegWrite_EX y 0 en caso de parada
mux_RegWriteEX: mux2_1_1bit port map (DIn0 => '0', DIn1 => RegWrite_EX, ctrl => Parar_EX, Dout => RegWrite_EX2);
-----------
-- Banco que separa las etapas de EX y Mem
-- NOTA:Si paramos en EX por una operaci髇 de FP habr?que pensar qu?se env韆 a la siguiente etapa
Banco_EX_MEM: Banco_MEM PORT MAP ( ALU_out_EX => ALU_out_EX, ALU_out_MEM => ALU_out_MEM, clk => clk, reset => reset, load => '1', MemWrite_EX => MemWrite_EX2,
												MemRead_EX => MemRead_EX2, MemtoReg_EX => MemtoReg_EX, RegWrite_EX => RegWrite_EX2, MemWrite_MEM => MemWrite_MEM, MemRead_MEM => MemRead_MEM,
												MemtoReg_MEM => MemtoReg_MEM, RegWrite_MEM => RegWrite_MEM, 
												BusB_EX => Mux_B_out, 
												BusB_MEM => BusB_MEM, RW_EX => RW_EX, RW_MEM => RW_MEM);
--
------------------------------------------Etapa MEM-------------------------------------------------------------------
--
-- Memoria de datos
Mem_D: memoriaRAM_D PORT MAP (CLK => CLK, ADDR => ALU_out_MEM, Din => BusB_MEM, WE => MemWrite_MEM, RE => MemRead_MEM, Dout => Mem_out);
-- Banco que separa las etapas de Mem y WB
Banco_MEM_WB: Banco_WB PORT MAP ( ALU_out_MEM => ALU_out_MEM, ALU_out_WB => ALU_out_WB, Mem_out => Mem_out, MDR => MDR, clk => clk, reset => reset, load => '1', MemtoReg_MEM => MemtoReg_MEM, RegWrite_MEM => RegWrite_MEM, 
											MemtoReg_WB => MemtoReg_WB, RegWrite_WB => RegWrite_WB, RW_MEM => RW_MEM, RW_WB => RW_WB );
-- Mux para elegir entre la salida de memoria y la de la ALU 
mux_busW: mux2_1 port map (Din0 => ALU_out_WB, DIn1 => MDR, ctrl => MemtoReg_WB, Dout => busW);
-----------
-- output no se usa para nada. Est?puesto para que el sistema tenga alguna salida al exterior.
output <= IR_ID;
end Behavioral;

