LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         thou, hund, tens, ones : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE behavior OF conv IS
TYPE state IS (START, ADD3, SHIFT, DONE);
SIGNAL currentState, nextState : state;

SIGNAL temp : STD_LOGIC;

SIGNAL step : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
SIGNAL cache : STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');
SIGNAL digits : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

SIGNAL temp1, temp2, temp3, temp4 : STD_LOGIC_VECTOR (15 DOWNTO 0);

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentState IS
            WHEN START => cache <= char;
                step <= (OTHERS => '0');
                digits <= (OTHERS => '0');
                nextState <= ADD3;
            WHEN ADD3 => temp1 <= TO_STDLOGICVECTOR(3, 16) WHEN digits(3 DOWNTO 0) >= 5 ELSE (OTHERS => '0');
                temp2 <= TO_STDLOGICVECTOR(48, 16) WHEN digits(7 DOWNTO 4) >= 5 ELSE (OTHERS => '0');
                temp3 <= TO_STDLOGICVECTOR(768, 16) WHEN digits(11 DOWNTO 8) >= 5 ELSE (OTHERS => '0');
                temp4 <= TO_STDLOGICVECTOR(12288, 16) WHEN digits(15 DOWNTO 12) >= 5 ELSE (OTHERS => '0');
                digits <= digits + temp1 + temp2 + temp3 + temp4;
                nextState <= SHIFT;
            WHEN SHIFT => temp <= '1' WHEN cache(11) ELSE '0';
                digits <= digits(14 DOWNTO 0) & temp;
                cache <= cache(10 DOWNTO 0) & '0';
                IF step = 11 THEN
                    nextState <= DONE;
                ELSE
                    step <= step + '1';
                    nextState <= ADD3;
                END IF;
            WHEN DONE => thou <= TO_STDLOGICVECTOR(48, 8) + ("0000" & digits(15 DOWNTO 12));
                hund <= TO_STDLOGICVECTOR(48, 8) + ("0000" & digits(11 DOWNTO 8));
                tens <= TO_STDLOGICVECTOR(48, 8) + ("0000" & digits(7 DOWNTO 4));
                ones <= TO_STDLOGICVECTOR(48, 8) + ("0000" & digits(3 DOWNTO 0));
                nextState <= START;
            END CASE;
            currentState <= nextState;
        END IF;
    END PROCESS;
END ARCHITECTURE;