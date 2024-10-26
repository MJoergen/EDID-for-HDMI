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
TYPE part IS (INTS, BASE, THO, HUN, TEN, ONE);
SIGNAL currentPart : part;

TYPE bits IS ARRAY (0 TO 7) OF INTEGER RANGE 0 TO 1;
SIGNAL int : bits := (OTHERS => 0);

SIGNAL cache : INTEGER RANGE 0 TO 8096 := 0;

IMPURE FUNCTION UPDOWN (var : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
VARIABLE switch : STD_LOGIC_VECTOR (7 DOWNTO 0);
BEGIN
    FOR i IN 0 TO 7 LOOP
        switch(i) := var(7 - i);
    END LOOP;
    RETURN switch;
END FUNCTION;

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentPart IS
            WHEN INTS => FOR i IN 0 TO 7 LOOP
                int(i) <= 1 WHEN char(i) ELSE 0;
            END LOOP;
            WHEN BASE => cache <= int(0) * 128 + int(1) * 64 + int(2) * 32 + int(3) * 16 + int(4) * 8 + int(5) * 4 + int(6) * 2 + int(7) * 1;
            WHEN THO => IF cache >= 8000 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"8";
                cache <= cache - 8000;
            ELSIF cache >= 7000 AND cache <= 7999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"7";
                cache <= cache - 7000;
            ELSIF cache >= 6000 AND cache <= 6999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"6";
                cache <= cache - 6000;
            ELSIF cache >= 5000 AND cache <= 5999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"5";
                cache <= cache - 5000;
            ELSIF cache >= 4000 AND cache <= 4999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"4";
                cache <= cache - 4000;
            ELSIF cache >= 3000 AND cache <= 3999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"3";
                cache <= cache - 3000;
            ELSIF cache >= 2000 AND cache <= 2999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + d"2";
                cache <= cache - 2000;
            ELSIF cache >= 1000 AND cache <= 1999 THEN
                thou <= TO_STDLOGICVECTOR(48, 8) + "1";
                cache <= cache - 1000;
            ELSE
                thou <= TO_STDLOGICVECTOR(48, 8);
            END IF;
            WHEN HUN => IF cache >= 900 AND cache <= 999 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"9";
                cache <= cache - 900;
            ELSIF cache >= 800 AND cache <= 899 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"8";
                cache <= cache - 800;
            ELSIF cache >= 700 AND cache <= 799 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"7";
                cache <= cache - 700;
            ELSIF cache >= 600 AND cache <= 699 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"6";
                cache <= cache - 600;
            ELSIF cache >= 500 AND cache <= 599 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"5";
                cache <= cache - 500;
            ELSIF cache >= 400 AND cache <= 499 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"4";
                cache <= cache - 400;
            ELSIF cache >= 300 AND cache <= 399 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"3";
                cache <= cache - 300;
            ELSIF cache >= 200 AND cache <= 299 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + d"2";
                cache <= cache - 200;
            ELSIF cache >= 100 AND cache <= 199 THEN
                hund <= TO_STDLOGICVECTOR(48, 8) + "1";
                cache <= cache - 100;
            ELSE
                hund <= TO_STDLOGICVECTOR(48, 8);
            END IF;
            WHEN TEN => IF cache >= 90 AND cache <= 99 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"9";
                cache <= cache - 90;
            ELSIF cache >= 80 AND cache <= 89 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"8";
                cache <= cache - 80;
            ELSIF cache >= 70 AND cache <= 79 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"7";
                cache <= cache - 70;
            ELSIF cache >= 60 AND cache <= 69 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"6";
                cache <= cache - 60;
            ELSIF cache >= 50 AND cache <= 59 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"5";
                cache <= cache - 50;
            ELSIF cache >= 40 AND cache <= 49 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"4";
                cache <= cache - 40;
            ELSIF cache >= 30 AND cache <= 39 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"3";
                cache <= cache - 30;
            ELSIF cache >= 20 AND cache <= 29 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + d"2";
                cache <= cache - 20;
            ELSIF cache >= 10 AND cache <= 19 THEN
                tens <= TO_STDLOGICVECTOR(48, 8) + "1";
                cache <= cache - 10;
            ELSE
                tens <= TO_STDLOGICVECTOR(48, 8);
            END IF;
            WHEN ONE =>	ones <= TO_STDLOGICVECTOR(48, 8) + TO_STDLOGICVECTOR(cache, 4);
            END CASE;
        END IF;
    END PROCESS;

    PROCESS(currentPart)
    BEGIN
        CASE currentPart IS
        WHEN INTS => currentPart <= BASE;
        WHEN BASE => currentPart <= THO;
        WHEN THO => currentPart <= HUN;
        WHEN HUN => currentPart <= TEN;
        WHEN TEN => currentPart <= ONE;
        WHEN ONE => currentPart <= INTS;
        END CASE;
    END PROCESS;
END ARCHITECTURE;
