
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity top_dsp is
  generic(
    mode : integer := 16;
    data : integer := 16;
    code : integer := 8;
    fifo_addr : integer := 4;
    opcode_alu : integer := 3;
    shift_size : integer := 3;
    shift_size_mul : integer := 4;
    addr_data : integer := 15
    );
  Port ( 
    CLK,RST,ENA,WNS : in std_logic;
    FIFO_ADDRESS : out std_logic_vector(fifo_addr-1 downto 0); --address of operand
    FIFO_DATA_OUT : in std_logic_vector(data-1 downto 0);
    FIFO_READ_ENABLE : out std_logic; --read and write operation 
    FIFO_EMA_READ_ENABLE : out std_logic; --read and write operation 
    FIFO_EMA_DATA_OUT : in std_logic_vector(data-1 downto 0);
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
    DATA_CODE : in std_logic_vector(code-1 downto 0);
    STATE_FSM: out std_logic_vector(2 downto 0)
    );
end top_dsp;

architecture Behavioral of top_dsp is

component ALU_BLOCK is 
Port ( 
	SHIFT_COUNT: in	std_Logic_Vector(shift_size DOWNTO 0); 
    ALU_OPCODE : in std_logic_vector(opcode_alu-1 downto 0);
    HIGHER,LOWER,OVERFLOW : out  STD_LOGIC;
	A,B: in std_logic_vector(data-1 downto 0);
	S: out std_logic_vector(data-1 downto 0)
  );
end component;

component fsm is 
  Port ( 
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
	S: in std_logic_vector(data-1 downto 0);
	FIFO_ADDRESS : out std_logic_vector(fifo_addr-1 downto 0); 
    FIFO_DATA_OUT : in std_logic_vector(data-1 downto 0);
    FIFO_EMA_DATA_OUT : in std_logic_vector(data-1 downto 0);
    DSP_MODE : in std_logic_vector(data-1 downto 0);
    TAU,SIGMA : in std_logic_vector(data-1 downto 0);
    TRAINING_SAMPLES : in std_logic_vector(data-1 downto 0);
    FWD : in std_logic_vector(4 downto 0);
    TEST_SAMPLES : in std_logic_vector(data-1 downto 0);
    CLASSIFIED1: out std_logic_vector(data-1 downto 0);
    END_CLASSIFIED : out std_logic;
    FIFO_READ_ENABLE,FIFO_EMA_READ_ENABLE : out std_logic;   
    STATE_FSM: out std_logic_vector(2 downto 0)
  );
end component;
 
component CLASSIFIED is
Port ( 
    CLK : in std_logic;
    RES1 : out std_logic_vector(data-1 downto 0);
    CLASSIFIED1: in std_logic_vector(data-1 downto 0)
  );
end component;


signal CLASSIFIED1: std_logic_vector(data-1 downto 0);
signal HIGHER,LOWER,OVERFLOW : std_logic;
signal S : std_logic_vector(data-1 downto 0);
signal A,B : std_logic_vector(data-1 downto 0);
signal ALU_OPCODE : std_logic_vector(opcode_alu-1 downto 0);
signal SHIFT_COUNT : std_logic_vector(shift_size downto 0);

begin
ALU : ALU_BLOCK 
port map(
    a=>a,b=>b,s=>s,higher=>higher,lower=>lower,shift_count=>shift_count,alu_opcode=>alu_opcode,overflow=>overflow
    );


CONTROL_UNIT : fsm
port map(
    clk=>clk,rst=>rst,ena=>ena,wns=>wns,data_ram_in=>data_ram_in,a=>a,b=>b,state_fsm=>state_fsm,
    s=>s,alu_opcode=>alu_opcode,higher=>higher,lower=>lower,data_code=>data_code,fwd=>fwd,training_samples=>TRAINING_SAMPLES,
    address_code=>address_code,fifo_data_out=>fifo_data_out,fifo_ema_data_out=>fifo_ema_data_out,read_ram=>read_ram,dsp_mode=>dsp_mode,
    write_ram=>write_ram,read_code=>read_code,fifo_read_enable=>fifo_read_enable,fifo_ema_read_enable=>fifo_ema_read_enable,test_samples=>test_samples,
    fifo_address=>fifo_address,address_data=>address_data,shift_count=>shift_count,tau=>tau,sigma=>sigma,
    data_ram_out=>data_ram_out,classified1=>classified1,end_classified=>end_classified,overflow=>overflow
    );
    
CLASSIFIED_FIFO : CLASSIFIED
port map(
    clk=>clk,classified1=>classified1,res1=>res1
    );

end Behavioral;

