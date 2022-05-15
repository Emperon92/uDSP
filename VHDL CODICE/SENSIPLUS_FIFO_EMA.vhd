library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;use IEEE.std_logic_unsigned.all;use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity fifo_ema_memory is
  generic(
    fifo_addr : integer := 4;
    data : integer := 16
    );
  port ( 
    CLK : in std_logic;
    FIFO_ADDRESS,ADDRESS_IN : in std_logic_vector(fifo_addr-1 downto 0); --address of operand
    FIFO_EMA_DATA_IN : in std_logic_vector(data-1 downto 0); --value of operand
    FIFO_EMA_DATA_OUT : out std_logic_vector(data-1 downto 0);
    FIFO_EMA_READ_ENABLE,FIFO_EMA_WRITE_ENABLE : in std_logic --read and write operation 
 );
end fifo_ema_memory;

architecture Behavioral of fifo_ema_memory is
type reg is array (0 to 40) of integer;
signal SENSIPLUS_EMA_SAMPLE: reg := (
others =>0
    );
begin


process(all)
begin
if rising_edge(clk) then
    if FIFO_EMA_READ_ENABLE = '1'  then --read data from RAM memory
        FIFO_EMA_DATA_OUT <= std_logic_vector(to_signed(SENSIPLUS_EMA_SAMPLE(to_integer(unsigned(FIFO_ADDRESS))),data));
    elsif FIFO_EMA_WRITE_ENABLE = '1'  then --write data to RAM memory
        SENSIPLUS_EMA_SAMPLE(to_integer(unsigned(ADDRESS_IN))) <= to_integer(signed(FIFO_EMA_DATA_IN));
    end if;
end if;
end process;
end Behavioral;
