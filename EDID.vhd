LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.common.ALL;

ENTITY EDID IS
    PORT(clk, enable, compI2C : IN STD_LOGIC;
         byteRCV : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ready : OUT STD_LOGIC := '1';
         enableI2C : OUT STD_LOGIC := '0';
         instructionI2C : OUT state;
         horPixel, vertPixel, refreshRate : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
         screenName : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
         byteSend : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF EDID IS
TYPE FSM IS (IDLE, STARTI2C, SENDADDR, SENDEDID, RESTARTI2C, SENDREAD, HANDLE, READBYTE, READNAME, STOPI2C, REFRESHRATE1, REFRESHRATE2, REFRESHRATE3, REFRESHRATE4, DONE, WAITI2C);
SIGNAL currentFSM, nextFSM, returnFSM : FSM;

SIGNAL processStart : STD_LOGIC := '0';

SIGNAL horBlank, verBlank : STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');
SIGNAL pixelClock : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

SIGNAL foundPrefix : STD_LOGIC_VECTOR (2 DOWNTO 0) := (OTHERS => '0');
SIGNAL nameCount : INTEGER;
SIGNAL counter : INTEGER := 0;
SIGNAL refreshTop, refreshBot : STD_LOGIC_VECTOR (19 DOWNTO 0) := (OTHERS => '0');

BEGIN

PROCESS(ALL)
BEGIN
    IF RISING_EDGE(clk) THEN
        CASE currentFSM IS
        WHEN IDLE => IF enable THEN
            nextFSM <= STARTI2C;
            ready <= '0';
            nameCount <= 0;
            counter <= 0;
            refreshRate <= (OTHERS => '0');
            foundPrefix <= (OTHERS => '0');
        END IF;
        WHEN STARTI2C => instructionI2C <= START;
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= SENDADDR;
        WHEN SENDADDR => instructionI2C <= WRITE;
            byteSend <= x"50";
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= SENDEDID;
        WHEN SENDEDID => instructionI2C <= WRITE;
            byteSend <= (OTHERS => '0');
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= RESTARTI2C;
        WHEN RESTARTI2C => instructionI2C <= START;
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= SENDREAD;
        WHEN SENDREAD => instructionI2C <= WRITE;
            byteSend <= x"51";
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= HANDLE;
        WHEN HANDLE => instructionI2C <= READ;
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= HANDLE;
            counter <= counter + 1;
            CASE counter IS
            WHEN 1 => IF byteRCV /= x"00" THEN
                nextFSM <= IDLE;
                enableI2C <= '0';
            END IF;
            WHEN 8 => IF byteRCV /= x"00" THEN
                nextFSM <= IDLE;
                enableI2C <= '0';
            END IF;
            WHEN 55 => pixelClock(7 DOWNTO 0) <= byteRCV;
            WHEN 56 => pixelClock(15 DOWNTO 8) <= byteRCV;
            WHEN 57 => horPixel(7 DOWNTO 0) <= byteRCV;
            WHEN 58 => horBlank(7 DOWNTO 0) <= byteRCV;
            WHEN 59 => horPixel(11 DOWNTO 8) <= byteRCV(7 DOWNTO 4);
                horBlank(11 DOWNTO 8) <= byteRCV(3 DOWNTO 0);
            WHEN 60 => vertPixel(7 DOWNTO 0) <= byteRCV;
            WHEN 61 => verBlank(7 DOWNTO 0) <= byteRCV;
            WHEN 62 => vertPixel(11 DOWNTO 8) <= byteRCV(7 DOWNTO 4);
                verBlank(11 DOWNTO 8) <= byteRCV(3 DOWNTO 0);
            WHEN 73 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 74 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 75 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 91 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 92 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 93 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 109 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 110 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 111 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
            WHEN 76 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"FC" ELSE (OTHERS => '0');
            WHEN 94 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"FC" ELSE (OTHERS => '0');
            WHEN 112 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"FC" ELSE (OTHERS => '0');
            WHEN 77 => IF byteRCV = x"00" AND foundPrefix = d"4" THEN
                returnFSM <= READNAME;
            ELSE
                foundPrefix <= (OTHERS => '0');
            END IF;
            WHEN 95 => IF byteRCV = x"00" AND foundPrefix = d"4" THEN
                returnFSM <= READNAME;
            ELSE
                foundPrefix <= (OTHERS => '0');
            END IF;
            WHEN 113 => IF byteRCV = x"00" AND foundPrefix = d"4" THEN
                returnFSM <= READNAME;
            ELSE
                foundPrefix <= (OTHERS => '0');
            END IF;
            WHEN OTHERS => NULL;
            END CASE;
        WHEN READBYTE => instructionI2C <= READ;
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= READNAME;
        WHEN READNAME => screenName(7 + nameCount * 8 DOWNTO nameCount * 8) <= byteRCV;
            nameCount <= nameCount + 1;
            nextFSM <= STOPI2C WHEN nameCount = 12 ELSE READBYTE;
        WHEN STOPI2C => instructionI2C <= STOP;
            enableI2C <= '1';
            nextFSM <= WAITI2C;
            returnFSM <= REFRESHRATE1;
        WHEN REFRESHRATE1 => FOR i IN 1 TO 10 LOOP
                refreshTop <= pixelClock + refreshTop;
            END LOOP;
            refreshBot <= (x"00" & (horPixel + horBlank));
            nextFSM <= REFRESHRATE2;
        WHEN REFRESHRATE2 => IF refreshTop >= refreshBot THEN
            refreshTop <= refreshTop - refreshBot;
            refreshRate <= refreshRate + '1';
        ELSE
            refreshBot <= (x"00" & (vertPixel + verBlank));
            nextFSM <= REFRESHRATE3;
        END IF;
        WHEN REFRESHRATE3 => FOR i IN 1 TO 1000 LOOP
                refreshTop <= x"00" & refreshRate + refreshTop;
            END LOOP;
            refreshRate <= (OTHERS => '0');
            nextFSM <= REFRESHRATE4;
        WHEN REFRESHRATE4 => IF refreshTop >= refreshBot THEN
            refreshTop <= refreshTop - refreshBot;
            refreshRate <= refreshRate + '1';
        ELSE
            IF refreshTop > 0 THEN
                refreshRate <= refreshRate + '1';
            END IF;
            nextFSM <= DONE;
        END IF;
        WHEN DONE => ready <= '1';
            IF NOT enable THEN
                nextFSM <= IDLE;
            END IF;
        WHEN WAITI2C => IF NOT processStart AND NOT compI2C THEN
            processStart <= '1';
        ELSIF compI2C AND processStart THEN
            nextFSM <= returnFSM;
            processStart <= '0';
            enableI2C <= '0';
        END IF;
        END CASE;
    END IF;
END PROCESS;
END ARCHITECTURE;
