library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CLASSIFIED is
  generic(
    data : integer := 16
    );
  Port ( 
    CLK : in std_logic;
    RES1: out std_logic_vector(data-1 downto 0);
    CLASSIFIED1: in std_logic_vector(data-1 downto 0)
  );
end CLASSIFIED;

architecture Behavioral of CLASSIFIED is
begin

process(all)
begin
    if rising_edge(clk) then 
        RES1 <= CLASSIFIED1;
    end if;
end process;

end Behavioral;
