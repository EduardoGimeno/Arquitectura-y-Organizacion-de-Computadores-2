----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:38:18 05/15/2014 
-- Design Name: 
-- Module Name:    UC_slave - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: la UC incluye un contador de 2 bits para llevar la cuenta de las transferencias de bloque y una m�quina de estados
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UC_MC is
    Port ( 	clk : in  STD_LOGIC;
			reset : in  STD_LOGIC;
			RE : in  STD_LOGIC; --RE y WE son las ordenes del MIPs
			WE : in  STD_LOGIC;
			hit : in  STD_LOGIC; --se activa si hay acierto
			dirty_bit : in  STD_LOGIC; --avisa si el bloque a reemplazar es sucio
			bus_TRDY : in  STD_LOGIC; --indica que la memoria no puede realizar la operaci�n solicitada en este ciclo
			Bus_DevSel: in  STD_LOGIC; --indica que la memoria ha reconocido que la direcci�n est� dentro de su rango
			MC_RE : out  STD_LOGIC; --RE y WE de la MC
            MC_WE : out  STD_LOGIC;
            bus_RE : out  STD_LOGIC; --RE y WE de la MC
            bus_WE : out  STD_LOGIC;
            MC_tags_WE : out  STD_LOGIC; -- para escribir la etiqueta en la memoria de etiquetas
            palabra : out  STD_LOGIC_VECTOR (1 downto 0);--indica la palabra actual dentro de una transferencia de bloque (1�, 2�...)
            mux_origen: out STD_LOGIC; -- Se utiliza para elegir si el origen de la direcci�n y el dato es el Mips (cuando vale 0) o la UC y el bus (cuando vale 1)
            ready : out  STD_LOGIC; -- indica si podemos procesar la orden actual del MIPS en este ciclo. En caso contrario habr� que detener el MIPs
            MC_send_addr : out  STD_LOGIC; --ordena que se env�en la direcci�n y las se�ales de control al bus
            MC_send_data : out  STD_LOGIC; --ordena que se env�en los datos
            Frame : out  STD_LOGIC; --indica que la operaci�n no ha terminado
			Send_dirty	: out  STD_LOGIC; --indica que hay que enviar el bloque sucio por el bus
			Update_dirty	: out  STD_LOGIC; --indica que hay que actualizar el bit dirty
			Replace_block	: out  STD_LOGIC -- indica que se ha reemplzado un bloque
           );
end UC_MC;

architecture Behavioral of UC_MC is


component counter_2bits is
		    Port ( clk : in  STD_LOGIC;
		           reset : in  STD_LOGIC;
		           count_enable : in  STD_LOGIC;
		           count : out  STD_LOGIC_VECTOR (1 downto 0)
					  );
end component;		           
type state_type is (Inicio,TransferenciaMP_MC,TransferenciaMC_MP,FinTransferencia); -- Poner aqu� el nombre de los estados. Usad nombres descriptivos
signal state, next_state : state_type; 
signal last_word: STD_LOGIC; --se activa cuando se est� pidiendo la �ltima palabra de un bloque
signal count_enable: STD_LOGIC; -- se activa si se ha recibido una palabra de un bloque para que se incremente el contador de palabras
signal palabra_UC : STD_LOGIC_VECTOR (1 downto 0);
begin
 
 
--el contador nos dice cuantas palabras hemos recibido. Se usa para saber cuando se termina la transferencia del bloque y para direccionar la palabra en la que se escribe el dato leido del bus en la MC
word_counter: counter_2bits port map (clk, reset, count_enable, palabra_UC); --indica la palabra actual dentro de una transferencia de bloque (1�, 2�...)

last_word <= '1' when palabra_UC="11" else '0';--se activa cuando estamos pidiendo la �ltima palabra

palabra <= palabra_UC;

   SYNC_PROC: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            state <= Inicio;
         else
            state <= next_state;
         end if;        
      end if;
   end process;
 
   --MEALY State-Machine - Outputs based on state and inputs
   OUTPUT_DECODE: process (state, hit, last_word, bus_TRDY, RE, WE, dirty_bit, Bus_DevSel)
   begin
			  -- valores por defecto, si no se asigna otro valor en un estado valdr�n lo que se asigna aqu�
		MC_WE <= '0';
		bus_RE <= '0';
		bus_WE <= '0'; -- ta lectura de una instrucci�n
        ready <= '0';
        mux_origen <= '0';
        MC_send_addr <= '0';
        MC_send_data <= '0';
        next_state <= state;  
		count_enable <= '0';
		Frame <= '0';
		Send_dirty <= '0';
		Update_dirty <= '0';
		Replace_block <= '0';
		MC_tags_WE <= '0';
			
        -- Estado Inicio          
        if (state = Inicio and RE= '0' and WE= '0') then -- si no piden nada no hacemos nada
			next_state <= Inicio;
			ready <= '1';
        -- Incluir aqu� vuestra m�quina de estados. Mirar el ejemplo en las transparencas de VHDL
		elsif (state = Inicio and RE = '1' and hit = '1') then
			-- t1
			next_state <= Inicio;
			MC_RE <= '1';
			ready <= '1';
			mux_origen <= '0';
		elsif (state = Inicio and WE = '1' and hit = '1') then
			-- t2
			next_state <= Inicio;
			MC_WE <= '1';
			ready <= '1';
			mux_origen <= '0';
			Update_dirty <= '1';
		elsif (state = Inicio and hit = '0' and dirty_bit = '0') then
			-- t3
			next_state <= TransferenciaMP_MC;
			Frame <= '1';
			Send_dirty <= '0';
			MC_send_addr <= '1';
			ready <= '0';
		elsif (state = TransferenciaMP_MC and (Bus_DevSel = '0' or bus_TRDY = '0')) then
			-- t4
			next_state <= TransferenciaMP_MC;
			if (Bus_DevSel = '0') then
				MC_send_addr <= '1';
				Send_dirty <= '0';
			end if;
			bus_RE <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = TransferenciaMP_MC and Bus_DevSel = '1' and bus_TRDY = '1' and last_word = '0') then
			-- t5
			next_state <= TransferenciaMP_MC;
			MC_WE <= '1';
			mux_origen <= '1';
			bus_RE <= '1';
			count_enable <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = TransferenciaMP_MC and bus_TRDY = '1' and last_word = '1') then
			-- t6
			next_state <= FinTransferencia;
			MC_WE <= '1';
			mux_origen <= '1';
			bus_RE <= '1';
			count_enable <= '1';
			MC_tags_WE <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = Inicio and hit = '0' and dirty_bit = '1') then
			-- t7
			next_state <= TransferenciaMC_MP;
			Send_dirty <= '1';
			MC_send_addr <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = TransferenciaMC_MP and (Bus_DevSel = '0' or bus_TRDY = '0')) then
			-- t8
			next_state <= TransferenciaMC_MP;
			if (Bus_DevSel = '0') then
				MC_send_addr <= '1';
				Send_dirty <= '1';
			end if;
			bus_WE <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = TransferenciaMC_MP and Bus_DevSel = '1' and bus_TRDY = '1' and last_word = '0') then
			-- t9
			next_state <= TransferenciaMC_MP;
			MC_RE <= '1';
			MC_send_data <= '1';
			mux_origen <= '1';
			bus_WE <= '1';
			count_enable <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = TransferenciaMC_MP and bus_TRDY = '1' and last_word = '1') then
			-- t10
			next_state <= FinTransferencia;
			MC_RE <= '1';
			MC_send_data <= '1';
			mux_origen <= '1';
			bus_WE <= '1';
			count_enable <= '1';
			Update_dirty <= '1';
			Replace_block <= '1';
			Frame <= '1';
			ready <= '0';
		elsif (state = FinTransferencia) then
			-- t11
			next_state <= Inicio;
			Frame <= '0';
			ready <= '0';
		end if;
   end process;
 
   
end Behavioral;

