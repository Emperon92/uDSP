Library std;
use std.textio.ALL;
use std.env.stop;    

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_textio.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity tb_top_dsp is
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
	classes : integer := 4;
    addr_data : integer := 15
    );
end tb_top_dsp;


architecture Behavioral of tb_top_dsp is

component fifo_memory is
 Port ( 
    CLK : in std_logic;
    FIFO_ADDRESS,ADDRESS_IN : in std_logic_vector(fifo_addr-1 downto 0); --address of operand
    FIFO_DATA_IN : in std_logic_vector(data-1 downto 0); --operand
    FIFO_DATA_OUT : out std_logic_vector(data-1 downto 0);
    FIFO_READ_ENABLE,FIFO_WRITE_ENABLE : in std_logic --read and write operation 
 );
end component;

component fifo_ema_memory is
 Port ( 
    CLK : in std_logic;
    FIFO_ADDRESS,ADDRESS_IN : in std_logic_vector(fifo_addr-1 downto 0); --address of operand
    FIFO_EMA_DATA_IN : in std_logic_vector(data-1 downto 0); --operand
    FIFO_EMA_DATA_OUT : out std_logic_vector(data-1 downto 0);
    FIFO_EMA_READ_ENABLE,FIFO_EMA_WRITE_ENABLE : in std_logic --read and write operation 
 );
end component;

component coefficient_memory is
 Port ( 
    CLK : in std_logic;
    ADDRESS_DATA,RESET_ADDRESS : in std_logic_vector(addr_data-1 downto 0); --address of operand
    DATA_RAM_IN,RESET_DATA : in std_logic_vector(data-1 downto 0); --value of operand
    DATA_RAM_OUT : out std_logic_vector(data-1 downto 0);
    READ_RAM,WRITE_RAM,WRITE_RESET : in std_logic --read and write operation 
 );
end component;

component program_memory is
  Port ( 
    READ_CODE : in std_logic;
    ADDRESS_CODE : in std_logic_vector(code-1 downto 0);
    DATA_CODE : out std_logic_vector(code-1 downto 0)
  );
end component;

component top_dsp is
Port ( 
    CLK,RST,ENA,WNS: in std_logic;
    FIFO_ADDRESS : out std_logic_vector(fifo_addr-1 downto 0); --address of operand
    FIFO_DATA_OUT : in std_logic_vector(data-1 downto 0);
    FIFO_READ_ENABLE: out std_logic; --read and write operation 
    FIFO_EMA_DATA_OUT : in std_logic_vector(data-1 downto 0);
    FIFO_EMA_READ_ENABLE: out std_logic; --read and write operation 
    ADDRESS_DATA : out std_logic_vector(addr_data-1 downto 0); --address of operand
    DATA_RAM_IN : out std_logic_vector(data-1 downto 0); --value of operand
    DATA_RAM_OUT : in std_logic_vector(data-1 downto 0);
    READ_RAM,WRITE_RAM : out std_logic; --read and write operation 
    READ_CODE : out std_logic;
    FWD : in std_logic_vector(4 downto 0);
    ADDRESS_CODE : out std_logic_vector(code-1 downto 0);
    DSP_MODE : in std_logic_vector(mode-1 downto 0);
    TAU,SIGMA : in std_logic_vector(mode-1 downto 0);
    TRAINING_SAMPLES : in std_logic_vector(data-1 downto 0);
    TEST_SAMPLES : in std_logic_vector(data-1 downto 0);
    RES1,RES2 : out std_logic_vector(data-1 downto 0);
    END_CLASSIFIED : out std_logic;
    DATA_CODE : in std_logic_vector(code-1 downto 0)
    );
end component;

signal CLK,RST,ENA,END_CLASSIFIED,WNS : std_logic;
signal TRAINING_SAMPLES : std_logic_vector(n_training-1 downto 0);
signal DSP_MODE : std_logic_vector(mode-1 downto 0);
signal TAU,SIGMA : std_logic_vector(mode-1 downto 0);
signal FWD : std_logic_vector(4 downto 0);
signal TEST_SAMPLES : std_logic_vector(n_test-1 downto 0);
signal WRITE_RESET : std_logic;
signal FIFO_ADDRESS,ADDRESS_IN : std_logic_vector(fifo_addr-1 downto 0);
signal FIFO_DATA_OUT : std_logic_vector(data-1 downto 0);
signal FIFO_DATA_IN : std_logic_vector(data-1 downto 0);
signal FIFO_EMA_DATA_OUT : std_logic_vector(data-1 downto 0);
signal FIFO_EMA_DATA_IN : std_logic_vector(data-1 downto 0);
signal DATA_RAM_IN,DATA_RAM_OUT,RESET_DATA : std_logic_vector(data-1 downto 0);
signal FIFO_READ_ENABLE,FIFO_EMA_READ_ENABLE,FIFO_WRITE_ENABLE,FIFO_EMA_WRITE_ENABLE,READ_CODE,READ_RAM,WRITE_RAM,WRITE_CODE : std_logic;
signal RES1,RES2 : std_logic_vector(15 downto 0);
signal ADDRESS_DATA,RESET_ADDRESS : std_logic_vector(addr_data-1 downto 0);
signal ADDRESS_CODE,DATA_CODE : std_logic_vector(code-1 downto 0);
constant CLK_PERIOD : time := 100 ns;
signal CLOCK_COUNTER : integer := 0;
file file_in : text open read_mode is "input.txt" ; --file diretory with test samples
--file file_in_RAW : text open read_mode is "RAW.txt" ; --file diretory with raw samples  -- simulazione rete ingresso
--file file_in_EMA : text open read_mode is "EMA.txt" ; --file diretory with test samples
file file_out : text open write_mode is "output.txt"  ; --file directory with the results
begin

CORE_RISC : top_dsp
port map(
    clk=>clk,rst=>rst,ena=>ena,wns=>wns,fifo_data_out=>fifo_data_out,fifo_ema_data_out=>fifo_ema_data_out,data_ram_in=>data_ram_in,
    data_code=>data_code,address_code=>address_code,read_code=>read_code,read_ram=>read_ram,write_ram=>write_ram,
    address_data=>address_data,fifo_read_enable=>fifo_read_enable,fifo_ema_read_enable=>fifo_ema_read_enable,
    fifo_address=>fifo_address,test_samples=>test_samples,end_classified=>end_classified,
    data_ram_out=>data_ram_out,res1=>res1,res2=>res2,fwd=>fwd,dsp_mode=>dsp_mode,sigma=>sigma,tau=>tau,training_samples=>training_samples
    );
SENSIPLUS_FIFO : fifo_memory
port map(
    clk=>clk,fifo_Address=>fifo_Address,fifo_write_enable=>fifo_write_enable,
    fifo_data_out=>fifo_data_out,fifo_read_enable=>fifo_read_enable,address_in=>address_in,
    fifo_data_in=>fifo_data_in
    );
    
SENSIPLUS_EMA_FIFO : fifo_ema_memory
port map(
    clk=>clk,fifo_Address=>fifo_Address,fifo_ema_write_enable=>fifo_ema_write_enable,
    fifo_ema_data_out=>fifo_ema_data_out,fifo_ema_read_enable=>fifo_ema_read_enable,address_in=>address_in,
    fifo_ema_data_in=>fifo_ema_data_in
    );
        
CODE_MEMORY : program_memory
port map(
    read_code=>read_code,address_code=>address_code,data_code=>data_code
    );
DATA_MEMORY : coefficient_memory
port map(
    address_data=>address_data,clk=>clk,data_ram_in=>data_ram_in,reset_address=>reset_address,
    read_ram=>read_ram,write_ram=>write_ram,reset_data=>reset_data,write_reset=>write_reset,
    data_ram_out=>data_ram_out
    );
    
CLOCK_GENERATING : process
begin
    CLK <= '1'; wait for CLK_PERIOD/2;
    CLK <= '0'; wait for CLK_PERIOD/2;
    CLOCK_COUNTER <= CLOCK_COUNTER + 1;
end process;


stimulus : process

variable linea1,linea2,linea3 : line;
variable half_word : integer; 
variable final1,final2 : std_logic_vector(3 downto 0);
begin	        
-- SET NUMBER OF TEST SAMPLES AND SET SENSIPLUS_REGISTERS
        TEST_SAMPLES <= std_logic_vector(to_unsigned(0,n_test)); --set number of test samples + 1
        DSP_MODE <= std_logic_vector(to_unsigned(1,3))&std_logic_vector(to_unsigned(4,3))&std_logic_vector(to_unsigned(16,mode-6)); --1,3 for RVFL; --1,4 for MLP: 2,1 for KNN; number of kernel for RVFL, K value for KNN
        TRAINING_SAMPLES <= std_logic_vector(to_unsigned(16,n_training)); --number of kernel for RVFL, number of training samples in memory for KNN
        FWD <= "01010"; -- specify the number of features
        TAU <= std_logic_vector(to_unsigned(200,mode));
        SIGMA <= std_logic_vector(to_unsigned(0,mode));
        wait for CLK_PERIOD;
-- LOAD SAMPLE IN SENSIPLUS FIFO MEMORY  
        RST <= '1';   
        ENA <= '0'; 
        wait for CLK_PERIOD/2;
        RST <= '0';
        wait for CLK_PERIOD/2;
         for j in 0 to to_integer(unsigned(TEST_SAMPLES)) loop   
               for i in 0 to to_integer(unsigned(FWD(3 downto 0))-1) loop
                     ADDRESS_IN <= std_logic_vector(to_unsigned(i,fifo_addr));
                     wait for CLK_PERIOD;
                     FIFO_WRITE_ENABLE <= '1';
                     --FIFO_EMA_WRITE_ENABLE <= '1';
                     readline(file_in,linea1);  
                     read(linea1,half_word);
                     FIFO_DATA_IN <= std_logic_vector(to_signed(half_word,data));
                     --readline(file_in_EMA,linea2);  
                     --read(linea2,half_word);
                     --FIFO_EMA_DATA_IN <= std_logic_vector(to_signed(half_word,data));
                     wait for CLK_PERIOD;
                     FIFO_WRITE_ENABLE <= '0';
                     --FIFO_EMA_WRITE_ENABLE <= '0';
                     wait for CLK_PERIOD;
                 end loop; 
-- START CLASSIFICATION           
            WNS <= '0'; 
            ENA <= '1';      
            wait until END_CLASSIFIED = '1';  
            --WNS <= '1';  
            wait for CLK_PERIOD;
-- RESET DEFAULT MEMORY VALUES
            ENA <= '0';
            RESET_ADDRESS <= std_logic_vector(to_unsigned(0,addr_data));   
            wait for CLK_PERIOD;
                -- for k in 0 to to_integer(unsigned(DSP_MODE)) loop
                  --   RESET_ADDRESS <= RESET_ADDRESS - 1;
                   --  wait for CLK_PERIOD;
                   --  WRITE_RESET <= '1';
                   --  RESET_DATA <= std_logic_vector(to_unsigned(65535,data+4));
                   --  wait for CLK_PERIOD;
                   --  WRITE_RESET <= '0';
                   --  wait for CLK_PERIOD;
                -- end loop;     
-- WRITE RESULTS ON FILE
        final1 := RES1(15 downto 12);
        write(linea2,to_integer(unsigned(final1))+1);
        writeline(file_out,linea2);
        wait for CLK_PERIOD;
        end loop;
        stop;
    end process;
end Behavioral;


