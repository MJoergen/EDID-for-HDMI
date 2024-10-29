LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.states.ALL;

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
TYPE FSM IS (IDLE, STARTI2C, SENDADDR, SENDEDID, RESTARTI2C, SENDREAD, HANDLE, STOPI2C, DONE, WAITI2C);
SIGNAL currentFSM, returnFSM : FSM := IDLE;

TYPE data IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL readData : data;

SIGNAL processStart : STD_LOGIC := '0';

SIGNAL horBlank, verBlank : STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');
SIGNAL pixelClock : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

SIGNAL foundPrefix : STD_LOGIC_VECTOR (2 DOWNTO 0) := (OTHERS => '0');
SIGNAL nameCount : INTEGER RANGE 0 TO 14;
SIGNAL counter : INTEGER RANGE 0 TO 257;
SIGNAL refreshTop, refreshBot : STD_LOGIC_VECTOR (19 DOWNTO 0) := (OTHERS => '0');

BEGIN

PROCESS(ALL)
BEGIN
    IF RISING_EDGE(clk) THEN
        CASE currentFSM IS
        WHEN IDLE => IF enable THEN
            currentFSM <= STARTI2C;
            ready <= '0';
            nameCount <= 0;
            counter <= 0;
            refreshRate <= (OTHERS => '0');
            foundPrefix <= (OTHERS => '0');
        END IF;
        WHEN STARTI2C => instructionI2C <= START;
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= SENDADDR;
        WHEN SENDADDR => instructionI2C <= WRITE;
            byteSend <= x"50";
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= SENDEDID;
        WHEN SENDEDID => instructionI2C <= WRITE;
            byteSend <= (OTHERS => '0');
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= RESTARTI2C;
        WHEN RESTARTI2C => instructionI2C <= START;
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= SENDREAD;
        WHEN SENDREAD => instructionI2C <= WRITE;
            byteSend <= x"51";
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= HANDLE;
        WHEN HANDLE => instructionI2C <= READ;
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= HANDLE;
            counter <= counter + 1;
            readData(counter) <= byteRCV;      
        WHEN WAITI2C => IF NOT processStart AND NOT compI2C THEN
            processStart <= '1';
        ELSIF compI2C AND processStart THEN
            currentFSM <= returnFSM;
            processStart <= '0';
            enableI2C <= '0';
        END IF;
        END CASE;
    END IF;
END PROCESS;
END ARCHITECTURE;
