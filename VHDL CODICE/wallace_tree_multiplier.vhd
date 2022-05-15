library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
library work;
use work.walltree_func.all;

package walltree_mul is

    -- add two number i.e. num1 + num2
    procedure w_mul(
        signal op1	:	in	std_logic_vector(15 downto 0 );
		signal op2	:	in	std_logic_vector(15 downto 0 );
		signal shf :   in  std_logic_vector(3 downto 0 ); 
		signal z	:	out	std_logic_vector(15 downto 0 )
		);
                            

end package;

package body walltree_mul is
    
    -- procedure for adding two numbers i.e. num1 + num2
    procedure w_mul(
        signal op1	:	in	std_logic_vector(15 downto 0 );
		signal op2	:	in	std_logic_vector(15 downto 0 );
		signal shf :   in  std_logic_vector(3 downto 0 ); 
		signal z	:	out	std_logic_vector(15 downto 0 )) is 
		variable temp,temp_2: std_logic_vector(15 downto 0);
		variable temp_3,temp_4,temp_5,result_buf : std_logic_vector(32 downto 0);
        begin
            if op1(15) = '1' then
                temp := std_logic_vector(unsigned(not(op1) + 1));
            else
                temp := op1;
            end if;
            if op2(15) = '1' then
                temp_2 := std_logic_vector(unsigned(not(op2) + 1));
            else 
                temp_2 := op2;
            end if;
            --temp_s <= op1(15) xor op2(15);
            temp_3 := mul_func(temp,temp_2);
            --shift se richiesto
            temp_4 := std_logic_vector(shift_right(unsigned(temp_3),to_integer(unsigned(shf))));
            -- controllo saturazione su registri più grandi.
            if temp_4 > "000000000000000000111111111111111" then
                temp_5 := "000000000000000000111111111111111";
                else 
                temp_5 := temp_4;
            end if;
            if (op1(15) xor op2(15)) = '1' then
                result_buf := std_logic_vector(not(temp_5) + 1);
            else 
                result_buf := temp_5;
            end if;
            z <= result_buf(15 downto 0);
        
end procedure;
end package body;

