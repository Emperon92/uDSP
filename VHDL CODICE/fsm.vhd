library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_signed.all;
library UNISIM;

/*
package pkg is
  type kernel is array(15 downto 0) of std_logic_vector(15 downto 0);
end package;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_signed.all;
library UNISIM;
use UNISIM.VComponents.all;

use work.pkg.all;
*/

entity FSM is
  generic(
    mode : integer := 16;
    n_fwd : integer := 5;
    n_training : integer := 16;
    n_test : integer := 16;
    code : integer := 8;
    fifo_addr : integer := 4;
    opcode_alu : integer := 3;
    shift_size : integer := 3;
    data : integer := 16;
	classes : integer := 5;
    addr_data : integer := 15;
    EMA: integer := 16
    );
  port ( 
    CLK,RST,ENA,WNS : in std_logic;
    ADDRESS_CODE : out std_logic_vector(code-1 downto 0);
    ADDRESS_DATA : out std_logic_vector(addr_data-1 downto 0); --address of operand
    DATA_RAM_IN : out std_logic_vector(data-1 downto 0); --value of operand
    DATA_RAM_OUT : in std_logic_vector(data-1 downto 0);
    READ_RAM,WRITE_RAM : out std_logic;
    DATA_CODE : in std_logic_vector(code-1 downto 0);
    READ_CODE : out std_logic;
    SHIFT_COUNT: out std_Logic_Vector (shift_size downto 0);  
    ALU_OPCODE : out std_logic_vector(opcode_alu-1 downto 0);
    HIGHER,LOWER,OVERFLOW : in  STD_LOGIC;
	A,B : out std_logic_vector(data-1 downto 0);
	S : in std_logic_vector(data-1 downto 0);
	FIFO_ADDRESS : out std_logic_vector(fifo_addr-1 downto 0); 
    FIFO_DATA_OUT,FIFO_EMA_DATA_OUT  : in std_logic_vector(data-1 downto 0);
    TRAINING_SAMPLES : in std_logic_vector(n_training-1 downto 0);
    TEST_SAMPLES : in std_logic_vector(n_test-1 downto 0);
    FWD : in std_logic_vector(n_fwd-1 downto 0);
    DSP_MODE : in std_logic_vector(mode-1 downto 0);
    TAU,SIGMA: in std_logic_vector(mode-1 downto 0);
    END_CLASSIFIED : out std_logic;
    CLASSIFIED1: out std_logic_vector(data-1 downto 0);
    FIFO_READ_ENABLE,FIFO_EMA_READ_ENABLE : out std_logic;
    STATE_FSM: out std_logic_vector(2 downto 0)
    --ACCUMULATION_REG : out std_logic_vector(data-1 downto 0)
    --KERNEL_REG : out kernel
  );
end FSM;

architecture CORE of FSM is

type my_state is (IDLE,IDLE_S,FETCH,FETCH2,DECODE,LOAD,STORE,VECN,VECN2,VECN3,VECN4,VECN5,VECN6,LOAD2,
NNA,NNA2,NNA3,NNA4,NNA5,NNA6,NNA7,NNA10,MAC,MAC1,MAC2,MAC3,MAC4,MAC5,
STORE2,LOAD3,LOAD4,LOAD5,STORE3,DECODE_CLASS,DECODE_CLASS2,LOOP_COUNT,LOOP_COUNT1,LOOP_COUNT2,CMP_LOOP,CMP_LOOP1,CMP_LOOP2,
CMP_LOOP3,CMP_LOOP4,CMP_LOOP5,CMP_LOOP6,ADD,SUB,MUL,CMP,CMPZ,BZ,BGE,SHIFTL,SHIFTR,NOP,NOP2,OVRFLW,FLT,FLT2,FLT3,FLT4,FLT5,FLT6,FLT7,STAT);
signal state : my_state;
signal CLASS : std_logic_vector(classes-2 downto 0) := "0000"; 
signal ADDRESS_CLASS1 : std_logic_vector(classes-2 downto 0):="0000";
signal ADDRESS_CLASS2 : std_logic_vector(classes-2 downto 0):="0001";
signal ADDRESS_CLASS_RVFL : std_logic_vector(classes-2 downto 0) := "0000";
signal DATA_ADDRESS,ADDRESS_REGISTER : std_logic_vector(addr_data-1 downto 0); 
signal CODE_REGISTER,PROGRAM_COUNTER : std_logic_vector(code-1 downto 0); 
signal ACCUMULATION_REG : std_logic_vector(data-1 downto 0) ;
signal DSP_MODE_REG,DSP_MODE_REG2 : std_logic_vector(mode-1 downto 0);
signal TAU_REG,SIGMA_REG : std_logic_vector(mode-1 downto 0);
signal TRAINING_SAMPLES_REG : std_logic_vector(n_training-1 downto 0);
signal TEST_SAMPLES_REG : std_logic_vector(n_test-1 downto 0) := "0000000000000000";
signal FWD_REG : std_logic_vector(n_fwd-1 downto 0);
signal N_CLASS,N_CLASS2 : std_logic_vector(classes-2 downto 0);
signal N_CLASS_RVFL : std_logic_vector(3 downto 0);
signal PREFETCH_REG : std_logic_vector(data-1 downto 0);
type count is array (0 to 14) of std_logic_vector(19 downto 0);
type count_2 is array (0 to 14) of std_logic_vector(15 downto 0);  
signal counter_class : count;
--signal counter_class_debug : count_2; --debug valore reale registri uscita
type kernel is array(15 downto 0) of std_logic_vector(15 downto 0);
signal KERNEL_REG : kernel;
signal SGN: std_logic;
signal t_counter: std_logic_vector(7 downto 0); -- internal timer for WT e ANOMALY

begin
    
ADDRESS_DATA <= DATA_ADDRESS; 
ADDRESS_CODE <= PROGRAM_COUNTER; 

AI_INFERENCE : process(all) 

begin

if RST = '1' then
    state <= IDLE;
elsif rising_edge(clk) then
    case state is
        when IDLE => --idle state 
            if ENA = '1' then
                READ_CODE <= '0';
                WRITE_RAM <= '0';
                READ_RAM <= '0';
                END_CLASSIFIED <= '0';
                DATA_ADDRESS <= std_logic_vector(to_unsigned(32767,addr_data));
                FIFO_ADDRESS <= std_logic_vector(to_unsigned(15,fifo_addr));
                PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                FIFO_READ_ENABLE <= '0';
                DSP_MODE_REG <= DSP_MODE;
                DSP_MODE_REG2 <= DSP_MODE;
                TAU_REG <= TAU;
                SIGMA_REG <= SIGMA;
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES;
                FWD_REG <= FWD;
                N_CLASS <= "1110";
                N_CLASS2 <= "1110";
                N_CLASS_RVFL <= "1111";
                ACCUMULATION_REG <= std_logic_vector(to_unsigned(0,data));
                ADDRESS_REGISTER <= std_logic_vector(to_unsigned(0,addr_data));
                PREFETCH_REG <= std_logic_vector(to_unsigned(0,data));
                SGN <= '0';
                counter_class <= (
                        "00000000000000000000",
                        "00010000000000000000",
                        "00100000000000000000",
                        "00110000000000000000",
                        "01000000000000000000",
                        "01010000000000000000",
                        "01100000000000000000",
                        "01110000000000000000",
                        "10000000000000000000",
                        "10010000000000000000",
                        "10100000000000000000",
                        "10110000000000000000",
                        "11000000000000000000",
                        "11010000000000000000",
                        "11100000000000000000"
                        );
                /*        
                counter_class_debug <= (
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000",
                        "0000000000000000"
                        );
                */
                ADDRESS_CLASS1 <= "0000";
                ADDRESS_CLASS2 <= "0001";
                ADDRESS_CLASS_RVFL <= "0000";
                KERNEL_REG <= (others => "0000000000000000");
                CLASS <= "0000";
                t_counter <= "00000000";
                state_fsm <= "000";
                state <= FETCH;
            else
                state <= IDLE;
            end if;
        when IDLE_S => --test per circuito di ingresso - RAW e EMA 
            if WNS = '0' then
                state <= FETCH;
            else 
                state <= IDLE_S;
                END_CLASSIFIED <= '0';
                FIFO_ADDRESS <= std_logic_vector(to_unsigned(15,fifo_addr));
                FIFO_READ_ENABLE <= '0';
                FIFO_EMA_READ_ENABLE <= '0';
            end if;
        when FETCH => --fetch instruction from program memory
            READ_CODE <= '1'; 
            state <= FETCH2;
        when FETCH2 =>
            CODE_REGISTER <= DATA_CODE;  
            READ_CODE <= '0';
            state <= DECODE;
        when DECODE => --decode instruction 
            if CODE_REGISTER(7 downto 3) = "00000" then
                state <= VECN;
            elsif CODE_REGISTER(7 downto 3) = "00001" then
                state <= LOAD; 
            elsif CODE_REGISTER(7 downto 3) = "00010" then
                state <= STORE;
            elsif CODE_REGISTER(7 downto 3) = "00011" then
                state <= DECODE_CLASS;
            elsif CODE_REGISTER(7 downto 3) = "00100" then
                state <= LOOP_COUNT;
            elsif CODE_REGISTER(7 downto 3) = "00101" then
                state <= CMP_LOOP;
            elsif CODE_REGISTER(7 downto 3) = "00110" then
                state <= ADD;
            elsif CODE_REGISTER(7 downto 3) = "00111" then
                state <= SUB;
            elsif CODE_REGISTER(7 downto 3) = "01000" then
                state <= MUL;
            elsif CODE_REGISTER(7 downto 3) = "01001" then
                state <= SHIFTL;
            elsif CODE_REGISTER(7 downto 3) = "01010" then
                state <= SHIFTR;
            elsif CODE_REGISTER(7 downto 3) = "01011" then
                state <= CMP;
            elsif CODE_REGISTER(7 downto 3) = "01100" then
                state <= CMPZ;
            elsif CODE_REGISTER(7 downto 3) = "01101" then
                state <= BZ;
            elsif CODE_REGISTER(7 downto 3) = "01110" then
                state <= BGE;
            elsif CODE_REGISTER(7 downto 3) = "01111" then
                state <= MAC;   
            elsif CODE_REGISTER(7 downto 3) = "10000" then
                state <= NNA;        
            elsif CODE_REGISTER(7 downto 3) = "10001" then
                state <= FLT;
            elsif CODE_REGISTER(7 downto 3) = "10011" then
                state <= STAT;                                   
            else
                NULL;
            end if;
        when ADD => 
            if code_register(2 downto 0) = "000" then
                ALU_OPCODE <= "000";
                A <= DATA_RAM_OUT;
                B <= FIFO_DATA_OUT;        
                state <= NOP;
            elsif code_register(2 downto 0) = "001" then
                ALU_OPCODE <= "000";
                A <= ACCUMULATION_REG;
                B <= PREFETCH_REG;        
                state <= NOP;
             elsif code_register(2 downto 0) = "010" then
                ALU_OPCODE <= "000";
                A <= ACCUMULATION_REG;
                B <= PREFETCH_REG;        
                state <= NOP2;
            end if;
        when SUB =>
            if code_register(2 downto 0) = "000" then
                ALU_OPCODE <= "001";
                A <= DATA_RAM_OUT;
                B <= FIFO_DATA_OUT; 
                state <= NOP;
            elsif code_register(2 downto 0) = "001" then
                ALU_OPCODE <= "001";
                A <= ACCUMULATION_REG;
                B <= PREFETCH_REG;        
                state <= NOP;
            elsif code_register(2 downto 0) = "010" then
                ALU_OPCODE <= "001";
                A <= ACCUMULATION_REG;
                B <= PREFETCH_REG;        
                state <= NOP2;
            end if;
        when MUL => 
             if code_register(2 downto 0) = "000" then
                ALU_OPCODE <= "111";
                A <= DATA_RAM_OUT;
                B <= FIFO_DATA_OUT; 
                state <= NOP;
            elsif code_register(2 downto 0) = "001" then
                ALU_OPCODE <= "111";
                A <= ACCUMULATION_REG;
                B <= PREFETCH_REG;        
                state <= NOP;
            elsif code_register(2 downto 0) = "010" then
                ALU_OPCODE <= "111";
                A <= ACCUMULATION_REG;
                B <= PREFETCH_REG;        
                state <= NOP2;
            end if;
        when SHIFTL => --shift left
            ALU_OPCODE <= "010";
            A <= ACCUMULATION_REG(15 downto 0);
            SHIFT_COUNT <= '0'&code_register(2 downto 0);
            state <= NOP;
        when SHIFTR => --shift right
            ALU_OPCODE <= "011";
            A <= ACCUMULATION_REG(15 downto 0);
            SHIFT_COUNT <= '0'&code_register(2 downto 0);
            state <= NOP;
        when CMP =>
            ALU_OPCODE <= "100";
            A <= PREFETCH_REG;
            B <= ACCUMULATION_REG(15 downto 0);
            state <= FETCH;
            PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
        when CMPZ => --compare with zero
            ALU_OPCODE <= "101";
            A <= ACCUMULATION_REG(15 downto 0);
            state <= FETCH;
            PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
        when BZ =>
            if LOWER = '1' then
                PROGRAM_COUNTER <= PROGRAM_COUNTER - code_register(2 downto 0);
            else 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
            end if;
            state <= FETCH;
        when BGE =>
            if HIGHER = '1' then
                PROGRAM_COUNTER <= PROGRAM_COUNTER - code_register(2 downto 0);
            else 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
            end if;
            state <= FETCH;
        when NOP =>
            if(OVERFLOW = '1') then
                 ACCUMULATION_REG <= std_logic_vector(to_unsigned(32767,data));
            else
                 ACCUMULATION_REG <= S;
            end if;
            state <= FETCH;
            PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
        when NOP2 =>
            if(OVERFLOW = '1') then
                 PREFETCH_REG <= std_logic_vector(to_unsigned(32767,data));
            else
                 PREFETCH_REG <= S;
            end if;
            state <= FETCH;
            PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;

        when STORE => --store value in data memory - utilizzata KNN
			if code_register(2 downto 0) = "000" then
				DATA_ADDRESS <= "111111111111111";  
				state <= STORE2;
			elsif code_register(2 downto 0) = "001" then
				DATA_ADDRESS <= DATA_ADDRESS + 1 + "";
				state <= STORE2;
			end if;
        when STORE2 => --write distance and relative class in memory
			if code_register(2 downto 0) = "000" then
				DATA_RAM_IN <= ACCUMULATION_REG;
				WRITE_RAM <= '1';
				state <= STORE3;
			end if;
        when STORE3 => 
			if code_register(2 downto 0) = "000" then
				WRITE_RAM <= '0';
				PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
				state <= FETCH;
			end if;
        when LOAD => 
            if code_register(2 downto 0)="000" then --load class
                READ_RAM <= '1';
                DATA_ADDRESS <= DATA_ADDRESS + 1;
                state <= LOAD2;
            elsif code_register(2 downto 0)="001" then --load data from memory for sorting - KNN function
                READ_RAM <= '1';
                DATA_ADDRESS <= DATA_ADDRESS; 
                state <= LOAD2; 
             elsif code_register(2 downto 0)="010" then 
                READ_RAM <= '1';
                DATA_ADDRESS <= DATA_ADDRESS + 1;
                FIFO_READ_ENABLE <= '1';
		        FIFO_ADDRESS <=  FIFO_ADDRESS + 1;
                state <= LOAD2;
            end if;
        when LOAD2 => 
            if code_register(2 downto 0)="000" then --load class
                ADDRESS_REGISTER <= DATA_ADDRESS;
                READ_RAM <= '0';
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;
            elsif code_register(2 downto 0)="001" then --load data for sorting - KNN function
                state <= LOAD3;
            elsif code_register(2 downto 0)="010" then 
                ADDRESS_REGISTER <= DATA_ADDRESS;
                FIFO_READ_ENABLE <= '0';
                READ_RAM <= '0';
                state <= LOAD3;
            end if;
        when LOAD3 =>
            if code_register(2 downto 0)="001" then --load data for sorting - KNN function
                PREFETCH_REG <= DATA_RAM_OUT;
                READ_RAM <= '0';
                state <= LOAD4;   
            elsif code_register(2 downto 0)="010" then   
                READ_RAM <= '1';
                PREFETCH_REG <= DATA_RAM_OUT;
                DATA_ADDRESS <= DATA_ADDRESS + 1;
                state <= LOAD4;
            end if;  
        when LOAD4 =>
            if code_register(2 downto 0)="001" then --load data for sorting -  KNN function
                READ_RAM <= '1';
                DATA_ADDRESS <= DATA_ADDRESS - 1 ; 
                state <= LOAD5;
            elsif code_register(2 downto 0)="010" then  
                ADDRESS_REGISTER <= DATA_ADDRESS;
                READ_RAM <= '0';
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;    
            end if; 
        when LOAD5 =>
            READ_RAM <= '0';
            PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
            state <= FETCH;
        when DECODE_CLASS => --load class from memory for counter the k near class - to deprecate
            if code_register(2 downto 0) = "000" then
                READ_RAM <= '1';
                DATA_ADDRESS <= std_logic_vector(to_unsigned(0,15)) - std_logic_vector(unsigned((DSP_MODE_REG2(9 downto 0)))) ;
                state <= DECODE_CLASS2;
            elsif code_register(2 downto 0) = "001" then --store the result of the classification on the FIFO CLASSIFIED
                CLASSIFIED1 <= counter_class(0)(19 downto 16)&counter_class(0)(3 downto 0)&counter_class(1)(19 downto 16)&counter_class(1)(3 downto 0); 
                END_CLASSIFIED <= '1';
                state <= IDLE;
                --PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
			elsif code_register(2 downto 0) = "010" then -- y_j of the RVFL is stored on the j_esimo counter class
				counter_class(to_integer(unsigned(ADDRESS_CLASS_RVFL)))(15 downto 0) <= ACCUMULATION_REG;
				-- counter_class_debug(to_integer(unsigned(ADDRESS_CLASS_RVFL)))(15 downto 0) <= ACCUMULATION_REG;
				ADDRESS_CLASS_RVFL <= ADDRESS_CLASS_RVFL + 1; 
				state <= FETCH;
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;  
            elsif code_register(2 downto 0) = "011" then -- y_j of the MLP is stored on the j_esimo counter class + bias
                ALU_OPCODE <= "000";
				A <= ACCUMULATION_REG;
				B <= DATA_RAM_OUT;
				state <= DECODE_CLASS2;
            else 
                NULL;
            end if;
        when DECODE_CLASS2 => --increment counter classes  
            if code_register(2 downto 0) = "011" then 
                counter_class(to_integer(unsigned(ADDRESS_CLASS_RVFL)))(15 downto 0) <= S;
				-- counter_class_debug(to_integer(unsigned(ADDRESS_CLASS_RVFL)))(15 downto 0) <= S;
				ADDRESS_CLASS_RVFL <= ADDRESS_CLASS_RVFL + 1; 
				state <= FETCH;
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;  
            end if;
  ----------------------------------      
      
	    when NNA =>  -- sub x-mu
	         if code_register(2 downto 0)="000" then -- sub x-mu 
                 ALU_OPCODE <= "001";
			     A <= FIFO_DATA_OUT; --x
			     B <= PREFETCH_REG; --mean value
			 elsif code_register(2 downto 0)="001" then  -- add bias hidden
			     ALU_OPCODE <= "000";
			     A <= KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1)));
			     B <= DATA_RAM_OUT;
			 end if;
			 state <= NNA2;
        when NNA2 => 
             if code_register(2 downto 0)="000" then 
                 ALU_OPCODE <= "111"; --mul
                 A <= S;
                 B <= DATA_RAM_OUT; --1/sigma
                 SHIFT_COUNT <= "0000";
			 end if;
			 if S(15) = '1' then
				    SGN <= '1';
			 else 
				    SGN <= '0';
			 end if;    
			 state <= NNA3;
       when NNA3 => 
			 ACCUMULATION_REG <= abs(S);
	         state <= NNA4;
	   when NNA4 =>
	   
	        if code_register(2 downto 0)="000" then   --GAUSSIAN APPROXIMATION WITH PIECEWISE LINEAR FUNCTION
	        
	            if ACCUMULATION_REG =  std_logic_vector(to_signed(0,data)) then --exponent 0, exponential value is 1000
                    ALU_OPCODE <= "000"; 
                    A <= KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1)));
                    B <= std_logic_vector(to_signed(1000,data));
                    state <= NNA7;		
                elsif (ACCUMULATION_REG >=  std_logic_vector(to_signed(30000,data))) then --(exponent < -30000 or > 30000)
                    PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                    ACCUMULATION_REG <=  std_logic_vector(to_signed(0,data));
                    ADDRESS_REGISTER <= DATA_ADDRESS;
                    state <= FETCH;
                elsif (ACCUMULATION_REG > std_logic_vector(to_signed(0,data)) and ACCUMULATION_REG  <= std_logic_vector(to_signed(15000,data))) then --exponent between 0 and 1.5
                    ALU_OPCODE <= "011";
                    A <= ACCUMULATION_REG;
                    SHIFT_COUNT <= "0100"; -- division by 16 -> 4
                    state <= NNA5;
                elsif (ACCUMULATION_REG > std_logic_vector(to_signed(15000,data)) and ACCUMULATION_REG < std_logic_vector(to_signed(30000,data))) then --exponent between 1.5 and 3
                    ALU_OPCODE <= "011";
                    A <= ACCUMULATION_REG;
                    SHIFT_COUNT <= "0111"; -- division by 128 -> 7
                    state <= NNA5;
                else -- (values not allowed)
                    NULL;            
	            end if;  
	            
	        elsif code_register(2 downto 0)="001" then -- SIGMOID APPROXIMATION WITH PIECEWISE LINEAR FUNCTION
	        
                if ACCUMULATION_REG >=  std_logic_vector(to_signed(500,data)) then --(exponent < -500 or > 500)
                    if SGN='0' then
                        KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1))) <=  std_logic_vector(to_signed(100,data));
                    elsif SGN='1' then                                         
                        KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1))) <= std_logic_vector(to_signed(0,data));
                    end if;
                    ACCUMULATION_REG <=  std_logic_vector(to_signed(0,data));
                    PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                    ADDRESS_REGISTER <= DATA_ADDRESS;
                    state <= FETCH;      
                elsif ACCUMULATION_REG >= std_logic_vector(to_signed(184,data)) and ACCUMULATION_REG  <= std_logic_vector(to_signed(500,data)) then --exponent between 0 and 1.5
                    ALU_OPCODE <= "011";
                    A <= ACCUMULATION_REG;
                    SHIFT_COUNT <= "0100"; -- division by 16 -> 4
                    state <= NNA5;
                elsif ACCUMULATION_REG >= std_logic_vector(to_signed(0,data)) and ACCUMULATION_REG  < std_logic_vector(to_signed(184,data)) then --exponent between 0 and 1.5
                    ALU_OPCODE <= "011";
                    A <= ACCUMULATION_REG;
                    SHIFT_COUNT <= "0010"; -- division by 4 -> 2
                    state <= NNA5;        
                else -- if value is negative (not allowed)
                    NULL;            
	            end if;  
	        end if;       
	        
	        
	        when NNA5 => --sum the q of the line
	        
            if code_register(2 downto 0)="000" then -- GAUSSIAN +q
            	       	        
                if ACCUMULATION_REG > std_logic_vector(to_signed(0,data)) and ACCUMULATION_REG  <= std_logic_vector(to_signed(15000,data)) then 
                    ALU_OPCODE <= "110"; 
                    A <= S;
                    B <= std_logic_vector(to_signed(1000,data)); -- sum 1000 at the line
                    state <= NNA6;
                elsif ACCUMULATION_REG > std_logic_vector(to_signed(15000,data)) and ACCUMULATION_REG < std_logic_vector(to_signed(30000,data)) then
                    ALU_OPCODE <= "110"; 
                    A <= S;
                    B <= std_logic_vector(to_signed(200,data)); -- sum 200 at the line
                    state <= NNA6;
                end if;
                
             elsif code_register(2 downto 0)="001" then -- SIGMOID +q 
             
                if ACCUMULATION_REG >= std_logic_vector(to_signed(184,data)) and ACCUMULATION_REG  < std_logic_vector(to_signed(500,data)) then --exponent between 0 and 1.5
                    A <= S;
                    if SGN = '0' then
                        ALU_OPCODE <= "000"; 
                        B <= std_logic_vector(to_signed(79,data)); -- sum 79 at the line
                    elsif SGN = '1' then
                        ALU_OPCODE <= "110"; 
                        B <= std_logic_vector(to_signed(21,data)); -- sum 21 at the line 
                    end if;  
                    state <= NNA7;
                elsif ACCUMULATION_REG >= std_logic_vector(to_signed(0,data)) and ACCUMULATION_REG < std_logic_vector(to_signed(184,data)) then --exponent between 1.5 and 3
                    if SGN = '0' then
                        ALU_OPCODE <= "000"; 
                        A <= S; 
                    elsif SGN = '1' then
                        ALU_OPCODE <= "110"; 
                        A <= S;    
                    end if;  
                    B <= std_logic_vector(to_signed(50,data)); -- sum 50 at the line
                    state <= NNA7;
                end if;   
        end if;                  
		when NNA6 => --accumulate the exponent for compute H
			ALU_OPCODE <= "000";
			A <= KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1)));
			B <= S;	
			state <= NNA7;
		when NNA7 => -- output of the neuron for the RVFL is stored in KERNEL_REG
			ADDRESS_REGISTER <= DATA_ADDRESS;
			KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1))) <= std_logic_vector(signed(S));
			ACCUMULATION_REG(15 downto 0) <= std_logic_vector(to_unsigned(0,data));
			PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
			state <= FETCH; 

 ----------------------------------------------------       
  --MAC
       when MAC =>  --load Beta from data memory
            if code_register(2 downto 0) = "000" or  code_register(2 downto 0) = "010"  then -- first layer in-hidden
                DATA_ADDRESS <= DATA_ADDRESS + 1;
			    READ_RAM <= '1';
			    state <= MAC2;	
            elsif code_register(2 downto 0) = "001" then -- first layer in-hidden
                FIFO_READ_ENABLE <= '1';
                FIFO_ADDRESS <=  FIFO_ADDRESS + 1;
                DATA_ADDRESS <= DATA_ADDRESS + 1;
			    READ_RAM <= '1';
			    state <= MAC2;	
			elsif code_register(2 downto 0) = "010" then
			    state <= MAC3;	 
            end if;   		
	   when MAC2 =>
	        if code_register(2 downto 0) = "001" then
                FIFO_READ_ENABLE <= '0';
            end if;    
	   	    READ_RAM <= '0';
			state <= MAC3;
	   when MAC3 =>
	        if code_register(2 downto 0) = "000" then
	             ALU_OPCODE <= "111";
			     A <= KERNEL_REG(to_integer(signed(TRAINING_SAMPLES_REG(9 downto 0)-1))); --H_j
			     B <= std_logic_vector((signed(DATA_RAM_OUT))); -- beta
			     SHIFT_COUNT <= "1010";
			elsif code_register(2 downto 0) = "010" then
			     ALU_OPCODE <= "111";
			     A <= KERNEL_REG(to_integer(signed(TRAINING_SAMPLES_REG(9 downto 0)-1))); --H_j
			     B <= std_logic_vector((signed(DATA_RAM_OUT))); -- beta
			     SHIFT_COUNT <= "0111";
			elsif code_register(2 downto 0) = "001" then
			     ALU_OPCODE <= "111";
			     A <= FIFO_DATA_OUT; -- feature
			     B <= DATA_RAM_OUT; -- w
			     SHIFT_COUNT <= "0011";
			elsif code_register(2 downto 0) = "011" then     
			     ALU_OPCODE <= "000";
			     A <= KERNEL_REG(to_integer(signed(TRAINING_SAMPLES_REG(9 downto 0)-1))); --H_j
			     B <= ACCUMULATION_REG;	     
			end if;
			state <= MAC4;
	   when MAC4 => --accumulate h*beta
	        if code_register(2 downto 0) = "000" or code_register(2 downto 0) = "010"  or code_register(2 downto 0) = "011" then
	             ALU_OPCODE <= "000";
	             A <= S;
	             B <= ACCUMULATION_REG;
			elsif code_register(2 downto 0) = "001" then
			     ALU_OPCODE <= "000";
			     A <= S; 
			     B <= KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1)));
			     ADDRESS_REGISTER <= DATA_ADDRESS;
			end if;
			state <= MAC5;
		when MAC5 => --save results in accumulation register
		    if code_register(2 downto 0) = "000" or code_register(2 downto 0) = "010" or code_register(2 downto 0) = "011"  then  
		      ACCUMULATION_REG <= S;
		    elsif code_register(2 downto 0) = "001" then
		      KERNEL_REG(to_integer(unsigned(TRAINING_SAMPLES_REG-1))) <= S;
		    end if;
			state <= FETCH;
			PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;		


------------------------------------------------

--VECN
        when VECN => --load values from memory and sensiplus fifo
                if code_register(2 downto 0) = "000" then
                    FIFO_ADDRESS <=  FIFO_ADDRESS + 1;
                    FIFO_READ_ENABLE <= '1';
	                FIFO_EMA_READ_ENABLE <= '1';
	                state <= VECN2;
	             elsif  code_register(2 downto 0) = "001" then  --for anomaly distance from centroid
	                FIFO_ADDRESS <=  FIFO_ADDRESS + 1;
                    FIFO_READ_ENABLE <= '1';
	                state <= VECN2;
	             end if;
	    when VECN2 =>
	            if code_register(2 downto 0) = "000" then
	                FIFO_READ_ENABLE <= '0';
	                FIFO_EMA_READ_ENABLE <= '0';
				    state <= VECN3;     
				elsif code_register(2 downto 0) = "001" then     --for anomaly distance from centroid
				    FIFO_READ_ENABLE <= '0';
				    state <= VECN4;    
				end if;            
        when VECN3 =>
                ALU_OPCODE <= "001";  
                A <= FIFO_DATA_OUT;
                B <= FIFO_EMA_DATA_OUT;
                state <= VECN4;
        when VECN4 =>
                if code_register(2 downto 0) = "000" then
                    ALU_OPCODE <= "001";
                    A <= S; 
                    B <= std_logic_vector(to_signed(0,data));  
                    state <= VECN5;
                elsif code_register(2 downto 0) = "001" then    --for anomaly distance from centroid
                    ALU_OPCODE <= "001";
                    A <= FIFO_DATA_OUT;
                    B <= DATA_RAM_OUT;
	                state <= VECN5;  
	            end if; 
        when VECN5 => 
                ALU_OPCODE <= "000";
                A <= abs(S);
                B <= ACCUMULATION_REG;
                state <= VECN6;
	   when VECN6 =>
	            if(OVERFLOW = '1') then
			         ACCUMULATION_REG <= std_logic_vector(to_unsigned(32767,data));
			    else
			         ACCUMULATION_REG <= S;
			    end if;
			    PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;   
				state <= FETCH;	
							  
-----------------------------------------------------------------------------------   
           
        when STAT =>  -- implementa FSM ingresso
                --WT
                if (state_fsm = "000") and (t_counter >= EMA-1)  then
                    state_fsm <= "001"; -- BA
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                    t_counter <= t_counter + 1;    
                elsif (state_fsm = "000") and (t_counter < EMA-1) then
                    state_fsm <= "000"; -- WT
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                    t_counter <= std_logic_vector(to_unsigned(0,code));     
                --BA
                elsif (state_fsm = "001") and (PREFETCH_REG < tau_reg) then
                    state_fsm <= "010"; -- BT
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));    
                elsif (state_fsm = "001") and (PREFETCH_REG > tau_reg) then
                    state_fsm <= "001"; -- BA
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                --BT       -- tau / 16
                elsif (state_fsm = "010") and (KERNEL_REG(0) > tau_reg) then
                    state_fsm <= "011"; -- BSP
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                elsif (state_fsm = "010") and (KERNEL_REG(0) > tau_reg) then
                    state_fsm <= "010"; -- BT
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                --BSP
                 elsif (state_fsm = "011") and (KERNEL_REG(0) > tau_reg) then
                    t_counter <= t_counter + 1;  
                    state_fsm <= "011"; -- BSP
                    PROGRAM_COUNTER <=  std_logic_vector(to_unsigned(0,code));
                elsif (state_fsm = "011") and (KERNEL_REG(0) > tau_reg) then
                    t_counter <= std_logic_vector(to_unsigned(0,code));
                    state_fsm <= "100"; -- BS
                    PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                elsif (state_fsm = "011") and (KERNEL_REG(0) < tau_reg) then
                    state_fsm <= "010"; -- BT
                    PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                --BS - ANOMALY
                elsif (state_fsm = "100") and (ACCUMULATION_REG > DATA_RAM_OUT) and t_counter <= 14 then
                    PROGRAM_COUNTER <= PROGRAM_COUNTER - 4;
                    t_counter <= t_counter + 1;
                    ACCUMULATION_REG <= std_logic_vector(to_unsigned(0,data));
                elsif (state_fsm = "100") and (ACCUMULATION_REG > DATA_RAM_OUT) and  t_counter > 14 then 
                    CLASSIFIED1 <= std_logic_vector(to_unsigned(0,data)); -- Anomaly_class_0
                    END_CLASSIFIED <= '1';
                    state <= IDLE;
                elsif (state_fsm = "100") and (ACCUMULATION_REG <= DATA_RAM_OUT) then   
                    PROGRAM_COUNTER <= PROGRAM_COUNTER + 1; --classified -- not anomaly
                    FIFO_ADDRESS <= std_logic_vector(to_unsigned(15,fifo_addr));
                    
                /*
                elsif (state_fsm = "011") and (ACCUMULATION_REG > tau_reg) and t_count >= 5 then
                    state_fsm <= "100";
                    PROGRAM_COUNTER <= PROGRAM_COUNTER + 2;
                    t_count <= 0;
                elsif (state_fsm = "011") and (dt < tau_reg) then    
                    state_fsm = "010";
                    PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
            */  
                else 
                    NULL;
                end if;
                state <= IDLE_S;
                END_CLASSIFIED <= '1';
                
        when LOOP_COUNT => --decrement iteration number
            if CODE_REGISTER(2 downto 0) = "000" then
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES_REG - 1;
            elsif CODE_REGISTER(2 downto 0) = "001" then
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES_REG - 1;
            elsif CODE_REGISTER(2 downto 0) = "010" then
                FWD_REG <= FWD_REG - 1;
            elsif CODE_REGISTER(2 downto 0) = "011" then
                N_CLASS_RVFL <= N_CLASS_RVFL - 1;
            elsif CODE_REGISTER(2 downto 0) = "100" then
                N_CLASS <= N_CLASS - 1;
            elsif CODE_REGISTER(2 downto 0) = "101" then
                N_CLASS2 <= N_CLASS2 - 1;
            elsif CODE_REGISTER(2 downto 0) = "110" then
                TEST_SAMPLES_REG <= TEST_SAMPLES_REG + 1;
            elsif CODE_REGISTER(2 downto 0) = "111" then
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES_REG - 1;
            else    
                NULL;
            end if;
            state <= LOOP_COUNT1;
        when LOOP_COUNT1 => --compare with zero 
            if CODE_REGISTER(2 downto 0) = "000" then 
                ALU_OPCODE <= "101";
                A <= TRAINING_SAMPLES_REG;
            elsif CODE_REGISTER(2 downto 0) =  "001" then
                ALU_OPCODE <= "101";
                A <= TRAINING_SAMPLES_REG;
            elsif CODE_REGISTER(2 downto 0) =  "010" then
                A <= "000000000000"& FWD_REG(3 downto 0);
                ALU_OPCODE <= "101";
            elsif CODE_REGISTER(2 downto 0) =  "011" then
                A <= "000000000000"&N_CLASS_RVFL;
                ALU_OPCODE <= "101";
            elsif CODE_REGISTER(2 downto 0) =  "100" then
                A <= "000000000000"&N_CLASS;
                ALU_OPCODE <= "101";
            elsif CODE_REGISTER(2 downto 0) =  "101" then
                A <= "000000000000"&N_CLASS2;
                ALU_OPCODE <= "101";
            elsif CODE_REGISTER(2 downto 0) =  "110" then
                ALU_OPCODE <= "100";
                A <= TEST_SAMPLES;
                B <= TEST_SAMPLES_REG;
            elsif CODE_REGISTER(2 downto 0) = "111" then 
                ALU_OPCODE <= "101";
                A <= TRAINING_SAMPLES_REG;
            else
                NULL;
            end if; 
            state <= LOOP_COUNT2;
        when LOOP_COUNT2 => -- BRANCH IF ZERO
            if LOWER = '1' and CODE_REGISTER(2 downto 0) = "000" then -- load new sample and evaluate distance, calcolo h del neurone successivo
                FWD_REG <= FWD;
                DSP_MODE_REG <= DSP_MODE;
                PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                ACCUMULATION_REG <= std_logic_vector(to_unsigned(0,data));
                DATA_ADDRESS <=  ADDRESS_REGISTER;
                FIFO_ADDRESS <= "1111";
                state <= FETCH;
            elsif LOWER = '0' and CODE_REGISTER(2 downto 0) = "000" then 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES;
                state <= FETCH;
            elsif LOWER = '1' and CODE_REGISTER(2 downto 0) = "001" then --sorting distance
                PROGRAM_COUNTER <= PROGRAM_COUNTER - to_integer(unsigned(DSP_MODE_REG(15 downto 13))); 
                state <= FETCH;
             elsif LOWER = '0' and CODE_REGISTER(2 downto 0) = "001" then --sorting distance
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES;
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;
            elsif LOWER = '1' and CODE_REGISTER(2 downto 0) = "010" then --features 
                PROGRAM_COUNTER <= std_logic_vector(to_unsigned(0,code));
                state <= FETCH;
            elsif LOWER = '0' and CODE_REGISTER(2 downto 0) = "010" then --features 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                FWD_REG <= FWD;
                state <= FETCH;
            elsif LOWER = '1' and CODE_REGISTER(2 downto 0) = "011" then --counter for class
                PROGRAM_COUNTER <= PROGRAM_COUNTER - to_integer(unsigned(DSP_MODE_REG(12 downto 10)));
                DSP_MODE_REG(9 downto 0) <= DSP_MODE(9 downto 0);
				TRAINING_SAMPLES_REG <= TRAINING_SAMPLES;
				ACCUMULATION_REG <= std_logic_vector(to_unsigned(0,data));
                state <= FETCH;
            elsif LOWER = '1' and CODE_REGISTER(2 downto 0) = "100" then --bubble sort inner loop
                PROGRAM_COUNTER <= PROGRAM_COUNTER - "00000001";
                ADDRESS_CLASS1 <= ADDRESS_CLASS1 + 1;
                ADDRESS_CLASS2 <= ADDRESS_CLASS2 + 1;
                state <= FETCH;
            elsif LOWER = '1' and CODE_REGISTER(2 downto 0) = "101" then --bubble sort outer loop
                N_CLASS <= "1110";
                ADDRESS_CLASS1 <= "0000";
                ADDRESS_CLASS2 <= "0001";
                PROGRAM_COUNTER <= PROGRAM_COUNTER - "00000010";
                state <= FETCH;    
            elsif HIGHER = '1' and CODE_REGISTER(2 downto 0) = "110" then --new test sample
                state <= IDLE;
            elsif LOWER = '1' and CODE_REGISTER(2 downto 0) = "111" then --cycle for bias  
                PROGRAM_COUNTER <= PROGRAM_COUNTER - "00000001";
                state <= FETCH;
            elsif LOWER = '0' and CODE_REGISTER(2 downto 0) = "111" then 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                TRAINING_SAMPLES_REG <= TRAINING_SAMPLES;
                state <= FETCH;         
            else 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;
            end if;       
        when CMP_LOOP =>
            if code_register(2 downto 0) = "000" then --compare two values
                ALU_OPCODE <= "100";
                A <= DATA_RAM_OUT; 
                B <= PREFETCH_REG; 
            elsif code_register(2 downto 0) = "001" then --compare class between them
                ALU_OPCODE <= "100";
                B <= counter_class(to_integer(unsigned(address_class1)))(15 downto 0);
                A <= counter_class(to_integer(unsigned(address_class2)))(15 downto 0);
            elsif code_register(2 downto 0) = "010" then --sum
                ALU_OPCODE <="001";
                A <= PREFETCH_REG;
                B <= KERNEL_REG(15);
            else 
                NULL;
            end if;
            state <= CMP_LOOP1;
        when CMP_LOOP1 => --if first value is greater than secod, HIGHER goes to '1'
            if code_register(2 downto 0) = "000" and HIGHER = '1'  then    
                DATA_ADDRESS <= DATA_ADDRESS;
                state <= CMP_LOOP2;
            elsif code_register(2 downto 0) = "001" and HIGHER = '1'  then --switch class counters if they are not in order  
                counter_class(to_integer(unsigned(address_class1))) <= counter_class(to_integer(unsigned(address_class2)));
                counter_class(to_integer(unsigned(address_class2))) <= counter_class(to_integer(unsigned(address_class1)));
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;
            elsif code_register(2 downto 0) = "010" then --shift reg
                for ii in 0 to 14 loop
                    KERNEL_REG(ii+1) <=  KERNEL_REG(ii);
                end loop;  -- ii
                KERNEL_REG(0) <= ACCUMULATION_REG;
                ACCUMULATION_REG <= std_logic_vector(to_unsigned(0,data));    
                PREFETCH_REG <= S; 
                state <= CMP_LOOP2;                
            else 
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;
            end if;
        when CMP_LOOP2 => --switch values in memory if they are not in order 
            if code_register(2 downto 0) = "010" then --shift reg
                ALU_OPCODE <= "000";
                A <= PREFETCH_REG;
                B <= SIGMA_REG;
                state <= CMP_LOOP3;
            else
                DATA_RAM_IN <= PREFETCH_REG;
                WRITE_RAM <= '1';
                state <= CMP_LOOP3;
            end if;
        when CMP_LOOP3 =>
            if code_register(2 downto 0) = "010" then --shift reg
                PREFETCH_REG <= S;
                PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
                state <= FETCH;
            else 
                WRITE_RAM <= '0';
                state <= CMP_LOOP4;
            end if;
        when CMP_LOOP4 =>
            DATA_ADDRESS <= DATA_ADDRESS + 1;
            state <= CMP_LOOP5;
        when CMP_LOOP5 =>
            DATA_RAM_IN <= DATA_RAM_OUT;
            WRITE_RAM <= '1';
            state <= CMP_LOOP6;
        when CMP_LOOP6 =>
            WRITE_RAM <= '0';
            PROGRAM_COUNTER <= PROGRAM_COUNTER + 1;
            DATA_ADDRESS <= DATA_ADDRESS - 1;
            state <= FETCH;
        when others =>
            null;
    end case;
end if;
end process;
end CORE;