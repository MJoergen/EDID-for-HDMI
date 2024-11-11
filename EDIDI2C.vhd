LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.states.ALL;
USE WORK.dataBytes.ALL;

ENTITY EDIDI2C IS
    PORT(clk, enable, compI2C : IN STD_LOGIC;
         byteRCV : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ready : OUT STD_LOGIC := '1';
         enableI2C : OUT STD_LOGIC := '0';
         parseReady : OUT STD_LOGIC := '0';
         instructionI2C : OUT state;
         readData : OUT data;
         byteSend : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF EDIDI2C IS
TYPE FSM IS (IDLE, STARTI2C, SENDADDR, SENDEDID, RESTARTI2C, SENDREAD, HANDLE, STOPI2C, DONE, WAITI2C);
SIGNAL currentFSM, returnFSM : FSM := IDLE;

SIGNAL processStart : STD_LOGIC := '0';

SIGNAL counter : INTEGER RANGE 1 TO 256 := 1;

BEGIN

PROCESS(ALL)
BEGIN
    IF RISING_EDGE(clk) THEN
        CASE currentFSM IS
        WHEN IDLE => parseReady <= '0';
            IF enable THEN
            currentFSM <= STARTI2C;
            ready <= '0';
            counter <= 1;
        END IF;
        WHEN STARTI2C => instructionI2C <= START;
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= SENDADDR;
        WHEN SENDADDR => instructionI2C <= WRITE;
            byteSend <= x"A0";
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
            byteSend <= x"A1";
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= HANDLE;
        WHEN HANDLE => instructionI2C <= READ;
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            IF counter = 256 THEN
                returnFSM <= STOPI2C;
            ELSE
                returnFSM <= HANDLE;
            END IF;
            counter <= counter + 1;
            readData(counter) <= byteRCV; 
        WHEN STOPI2C => instructionI2C <= STOP;
            enableI2C <= '1';
            currentFSM <= WAITI2C;
            returnFSM <= DONE;     
        WHEN WAITI2C => IF NOT processStart AND NOT compI2C THEN
            processStart <= '1';
        ELSIF compI2C AND processStart THEN
            currentFSM <= returnFSM;
            processStart <= '0';
            enableI2C <= '0';
        END IF;
        WHEN DONE => parseReady <= '1';
            ready <= '1';
            IF NOT enable THEN
                currentFSM <= IDLE;
            END IF;
        END CASE;
    END IF;
END PROCESS;
END ARCHITECTURE;
