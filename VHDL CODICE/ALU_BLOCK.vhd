
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_signed.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;
library work;
use work.walltree_mul.all;

entity alu_block is
generic(
    data : integer := 16;
    opcode_alu : integer := 3;
    shift_size : integer := 3
    );
port(
	SHIFT_COUNT: in	std_Logic_Vector (shift_size DOWNTO 0);  
    ALU_OPCODE : in std_logic_vector(opcode_alu-1 downto 0);
    HIGHER,LOWER,OVERFLOW : out  STD_LOGIC;
	A,B: in std_logic_vector(data-1 downto 0);
	S: out std_logic_vector(data-1 downto 0)
);
end ALU_block;

architecture Behavioral of ALU_block is

signal A_extended : std_logic_vector(data downto 0);
signal B_extended : std_logic_vector(data downto 0);
signal S_extended : std_logic_vector(data downto 0);

begin

SET_OPERATION : process(all) --alu set operation
begin

A_extended <= A(15) & std_logic_vector(A);
B_extended <= B(15) & std_logic_vector(B);
HIGHER <= '0';
LOWER <= '0';
OVERFLOW <= '0';
S_extended <= "00000000000000000";
S <= "0000000000000000";

case ALU_OPCODE is 
    when "000" => -- sum    
        S_extended <= A_extended + B_extended;
        if S_extended(16) /= S_extended(15) then
            OVERFLOW <= '1';
        end if;
        S <= S_extended(15 downto 0);
    when "001" => --sub
        S_extended <= A_extended - B_extended;
        if S_extended(16) /= S_extended(15) then
           OVERFLOW <= '1';
         end if;
         S <= S_extended(15 downto 0);
    when "010" => --shift_left
        S <= std_logic_vector(shift_left(signed(A),to_integer(unsigned(SHIFT_COUNT))));
    when "011" => --shift_right
        S <= std_logic_vector(shift_right(signed(A),to_integer(unsigned(SHIFT_COUNT))));
    when "100" => --compare
        if A > B then
            HIGHER <= '1';
        else    
            HIGHER <= '0';
        end if;
    when "101" =>  --compare with zero
        if A > "0000000000000000" then
            LOWER <= '1';
        else 
            LOWER <= '0';
        end if;
    when "110" =>
        S_extended <= not(A_extended) + 1 + B_extended;
        if S_extended(16) /= S_extended(15) then
           OVERFLOW <= '1';
        end if;
         S <= S_extended(15 downto 0);
    when "111" => --shift_right mul
        w_mul(A,B,SHIFT_COUNT,S); 
    when others =>
        null;
end case;

end process;
end Behavioral;

