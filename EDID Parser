LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.dataBytes.ALL;

ENTITY EDID IS
    PORT(clk, enable : IN STD_LOGIC;
         readData : IN data;
         horPixel, vertPixel, refreshRate : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
         screenName : OUT STD_LOGIC_VECTOR (103 DOWNTO 0)
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF EDID IS
TYPE FSM IS (IDLE, HANDLE, READNAME, REFRESHRATE1, REFRESHRATE2, REFRESHRATE3, REFRESHRATE4, DONE);
SIGNAL currentFSM : FSM;

SIGNAL processStart : STD_LOGIC := '0';

SIGNAL horBlank, verBlank : STD_LOGIC_VECTOR (11 DOWNTO 0);
SIGNAL pixelClock : STD_LOGIC_VECTOR (15 DOWNTO 0);

SIGNAL foundPrefix : STD_LOGIC_VECTOR (2 DOWNTO 0);
SIGNAL nameCount : INTEGER RANGE 0 TO 14;
SIGNAL counter : INTEGER RANGE 0 TO 257;
SIGNAL refreshTop, refreshBot : STD_LOGIC_VECTOR (19 DOWNTO 0);

BEGIN

PROCESS(ALL)
BEGIN
    IF RISING_EDGE(clk) THEN
        CASE currentFSM IS
        WHEN IDLE => processStart <= '0';
            horBlank <= (OTHERS => '0');
            verBlank <= (OTHERS => '0');
            pixelClock <= (OTHERS => '0');
            foundPrefix <= (OTHERS => '0');
            nameCount <= 0;
            counter <= 0;
            refreshTop <= (OTHERS => '0');
            refreshBot <= (OTHERS => '0');
            IF enable THEN
                currentFSM <= HANDLE;
            END IF;
        WHEN HANDLE => counter <= counter + 1;
            CASE counter IS
            WHEN 1 => IF readData(counter) /= x"00" THEN
                currentFSM <= IDLE;
            END IF;
            WHEN 8 => IF readData(counter) /= x"00" THEN
                currentFSM <= IDLE;
            END IF;
            WHEN 55 => pixelClock(7 DOWNTO 0) <= readData(counter);
            WHEN 56 => pixelClock(15 DOWNTO 8) <= readData(counter);
            WHEN 57 => horPixel(7 DOWNTO 0) <= readData(counter);
            WHEN 58 => horBlank(7 DOWNTO 0) <= readData(counter);
            WHEN 59 => horPixel(11 DOWNTO 8) <= readData(counter)(7 DOWNTO 4);
                horBlank(11 DOWNTO 8) <= readData(counter)(3 DOWNTO 0);
            WHEN 60 => vertPixel(7 DOWNTO 0) <= readData(counter);
            WHEN 61 => verBlank(7 DOWNTO 0) <= readData(counter);
            WHEN 62 => vertPixel(11 DOWNTO 8) <= readData(counter)(7 DOWNTO 4);
                verBlank(11 DOWNTO 8) <= readData(counter)(3 DOWNTO 0);
            WHEN 73 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 74 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 75 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 91 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 92 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 93 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 109 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 110 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 111 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"00" ELSE (OTHERS => '0');
            WHEN 76 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"FC" ELSE (OTHERS => '0');
            WHEN 94 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"FC" ELSE (OTHERS => '0');
            WHEN 112 => foundPrefix <= foundPrefix + '1' WHEN  readData(counter) = x"FC" ELSE (OTHERS => '0');
            WHEN 77 => IF readData(counter) = x"00" AND foundPrefix = d"4" THEN
                currentFSM <= READNAME;
            ELSE
                foundPrefix <= (OTHERS => '0');
            END IF;
            WHEN 95 => IF readData(counter) = x"00" AND foundPrefix = d"4" THEN
                currentFSM <= READNAME;
            ELSE
                foundPrefix <= (OTHERS => '0');
            END IF;
            WHEN 113 => IF readData(counter) = x"00" AND foundPrefix = d"4" THEN
                currentFSM <= READNAME;
            ELSE
                foundPrefix <= (OTHERS => '0');
            END IF;
            WHEN OTHERS => NULL;
            END CASE;
        WHEN READNAME => screenName(7 + nameCount * 8 DOWNTO nameCount * 8) <= readData(counter);
            nameCount <= nameCount + 1;
            currentFSM <= REFRESHRATE1 WHEN nameCount = 12 ELSE HANDLE;
        WHEN REFRESHRATE1 => FOR i IN 1 TO 10 LOOP
                refreshTop <= pixelClock + refreshTop;
            END LOOP;
            refreshBot <= (x"00" & (horPixel + horBlank));
            currentFSM <= REFRESHRATE2;
        WHEN REFRESHRATE2 => IF refreshTop >= refreshBot THEN
            refreshTop <= refreshTop - refreshBot;
            refreshRate <= refreshRate + '1';
        ELSE
            refreshBot <= (x"00" & (vertPixel + verBlank));
            currentFSM <= REFRESHRATE3;
        END IF;
        WHEN REFRESHRATE3 => FOR i IN 1 TO 1000 LOOP
                refreshTop <= x"00" & refreshRate + refreshTop;
            END LOOP;
            refreshRate <= (OTHERS => '0');
            currentFSM <= REFRESHRATE4;
        WHEN REFRESHRATE4 => IF refreshTop >= refreshBot THEN
            refreshTop <= refreshTop - refreshBot;
            refreshRate <= refreshRate + '1';
        ELSE
            IF refreshTop > 0 THEN
                refreshRate <= refreshRate + '1';
            END IF;
            currentFSM <= DONE;
        END IF;
        WHEN DONE => IF NOT enable THEN
                currentFSM <= IDLE;
            END IF;
        END CASE;
    END IF;
END PROCESS;
END ARCHITECTURE;
