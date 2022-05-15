library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
entity program_memory is
  generic(
    code : integer := 8
    );
  Port ( 
    READ_CODE : in std_logic;
    ADDRESS_CODE : in std_logic_vector(code-1 downto 0);
    DATA_CODE : out std_logic_vector(code-1 downto 0)
  );
end program_memory;

architecture Behavioral of program_memory is
type rom is array (0 to 13) of std_logic_vector(7 downto 0); -- (0 to 14) for KNN, (0 to 12) for RVFL
constant RAM_PROGRAM : rom :=( --rom instruction memory

-- KNN -- deprecated
--MANHATTAN DISTANCE 
--     "00000000", --vec_n
--     "00100010", --loop count feature vector
--     "00001000", --load class
--     "00010000", --store
----INSERTION SORT DISTANCES
--     "00001001", --load sort
--     "00101000", --cmp loop
--     "00100001", --loop count insertion sort k
--     "00100000", --loop count number of samples
----DECODE CLASSES
--     "00011000", --decode class
--     "00100011", --loop count number of class k
----BUBBLE SORT CLASSES AND CLASSIFY
--     "00101001", --cmp loop
--     "00100100", --loop count (number of class - 1)
--     "00100101", --loop count (number of class - 1)
--     "00011001", --store classified fifo from decode class instruction
--     "00100110"  --new test sample


---  CONDIZIONAMENTO INGRESSO ---
/*
       "00000000", -- calcolo ft singola feature
       "00100010", -- loop per cambiare feature - 10 features - ottengo dt
       "01010100", -- div by EMA = 16
       "00110010", -- sum accumulator to prefetch
       "00101010", -- shift_reg
       "10011000"  -- STAT
*/

/*
--- ANOMALY DETECTION ---
       "00001000", --load centroid
       "00000001", -- vecn centroid
       "00100010", -- loop per cambiare feature - 10 features - ottengo distanza centroide
       "00001000", -- load soglia
       "10011000"  -- STAT

/*
--- RVFL ----

--COMPUTE H
	"00001010", --load mu,sigma
	"10000000", --NNA approssimazione gaussiana, modalità KERNEL
	"00100010", --loop stesso neurone, fwd REG
	"00100000", --loop neurone successivo, training REG

--COMPUTE H*BETA
	"01111000", --MAC  h*beta
	"00100001", --prossimo MAC loop, k REG
	"00011010", --store risultato nel contatore della classe relativa
	"00100011" --loop MAC classe successiva, quindi devo riprendere dal primo h, k2 REG
	/*
--SORTING CLASSES AND CLASSIFY
	"00101001", --riordino i risultati delle classi
	"00100100", --loop riordino classi
	"00100101", --loop riordino classi 
	"00011001" --store classified fom decode class instruction 
--
--	"00100110" --new test sample
*/

/*
--TEST
    "00001010",
    "00110000"
*/

--- MLP ---

  "01111001", --MAC  x*w
  "00100010", --loop stesso neurone, fwd REG
  "00100000", --loop neurone successivo, training REG
  "10000001", --NNA approssimazione sigmoide
  "00100111",  --loop stesso neurone, bias
 
  --- 
  "01111010", --MAC  h*w2
  "00100001", --prossimo MAC loop, k REG
  "00001000", --load b2    
  "00011011", --store risultato nel contatore della classe relativa + bias
  "00100011", --loop MAC classe successiva, quindi devo riprendere dal primo h, k2 REG
  
	--SORTING CLASSES AND CLASSIFY
  "00101001", --riordino i risultati delle classi
  "00100100", --loop riordino classi
  "00100101", --loop riordino classi 
  "00011001" --store classified fom decode class instruction 
    );
    
begin

process(all) --program memory
begin
    if READ_CODE = '1' then --read instruction from memory
       DATA_CODE <= std_logic_vector(RAM_PROGRAM(to_integer(unsigned(ADDRESS_CODE)))) after 10 ns;
    else 
        DATA_CODE <= "00000000";
    end if;
end process;

end Behavioral;

