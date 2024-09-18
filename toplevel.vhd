LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.common.ALL;

ENTITY toplevel IS
    PORT(clk, btn1, RST : IN STD_LOGIC;
         SCL, TX : OUT STD_LOGIC;
         SDA : INOUT STD_LOGIC
         );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
TYPE main IS (READ, WAITSTART, WAITVALUE, DONE);
SIGNAL currentMain, nextMain : main;

TYPE display IS (NAME, MANU, RESO, DIME);
SIGNAL currentDisplay, nextDisplay : display;

CONSTANT CR : STD_LOGIC_VECTOR := x"0D"; --Carriage Return
CONSTANT LF : STD_LOGIC_VECTOR := x"0A"; --Line Feed
CONSTANT BS : STD_LOGIC_VECTOR := x"08"; --Backspace
CONSTANT ESC : STD_LOGIC_VECTOR := x"1B"; --Escape
CONSTANT SP : STD_LOGIC_VECTOR := x"20"; --Space
CONSTANT DEL  : STD_LOGIC_VECTOR := x"7F"; --Delete

SIGNAL nameString : STRING (6 DOWNTO 1);
SIGNAL nameLogic : STD_LOGIC_VECTOR (47 DOWNTO 0);

SIGNAL resoString : STRING (12 DOWNTO 1);
SIGNAL resoLogic : STD_LOGIC_VECTOR (95 DOWNTO 0);

SIGNAL tx_valid, tx_ready : STD_LOGIC;
SIGNAL tx_data, tx_name, tx_reso : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL isSend, SDAIn, SDAOut, I2CComp, I2CEnable : STD_LOGIC;
SIGNAL I2CInstruc : state;
SIGNAL byteSend, byteRCV : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL enableEDID, readyEDID : STD_LOGIC;
SIGNAL charInd : INTEGER;
SIGNAL horPixel, vertPixel, refreshRate : STD_LOGIC_VECTOR (11 DOWNTO 0);
SIGNAL screenName : STD_LOGIC_VECTOR (103 DOWNTO 0);

SIGNAL horThou, horHund, horTens, horOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL vertThou, vertHund, vertTens, vertOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL refreshThou, refreshHund, refreshTens, refreshOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL counter : INTEGER RANGE 0 TO 16;
SIGNAL nameCounter, resoCounter : INTEGER;

COMPONENT I2C IS
    PORT(clk, SDAin, enable : IN STD_LOGIC;
         instruction : IN state;
         byteSend : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         complete : OUT STD_LOGIC;
         SDAout, SCL : OUT STD_LOGIC := '1';
         isSend : OUT STD_LOGIC := '0';
         byteReceived : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
END COMPONENT;

COMPONENT EDID IS
    PORT(clk, enable, compI2C : IN STD_LOGIC;
         byteRCV : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ready : OUT STD_LOGIC := '1';
         enableI2C : OUT STD_LOGIC := '0';
         instructionI2C : OUT state;
         horPixel, vertPixel, refreshRate : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
         screenName : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
         byteSend : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

COMPONENT conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         thou, hund, tens, ones : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

COMPONENT UART_TX IS
    PORT (clk : IN  STD_LOGIC;
          reset : IN  STD_LOGIC;
          tx_valid : IN STD_LOGIC;
          tx_data : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
          tx_ready : OUT STD_LOGIC;
          tx_OUT : OUT STD_LOGIC);
END COMPONENT;

IMPURE FUNCTION BITSHIFT (input : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE output : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        FOR i IN 0 TO 7 LOOP
            output(i) := input(7 - i);
        END LOOP;
    RETURN output;
END FUNCTION;

IMPURE FUNCTION STR2SLV (str : STRING; size : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data : STD_LOGIC_VECTOR(size'length - 1 DOWNTO 0);
    BEGIN
    FOR i IN str'HIGH DOWNTO 1 LOOP
        data(i * 8 - 1 DOWNTO i * 8 - 8) := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(str(i)), 8));
    END LOOP;
    RETURN data;
END FUNCTION;

BEGIN
    DATA : I2C PORT MAP(clk => clk, SDAin => SDAIn, enable => I2CEnable, instruction => I2CInstruc, byteSend => byteSend, complete => I2Ccomp, SDAout => SDAOut, SCL => SCL, isSend => isSend, byteReceived => byteRCV);
    INFO :  EDID PORT MAP(clk => clk, enable => enableEDID, compI2C => I2Ccomp, byteRCV => byteRCV, ready => readyEDID, enableI2C => I2Cenable, instructionI2C => I2CInstruc, horPixel => horPixel, vertPixel => vertPixel, refreshRate => refreshRate, screenName => screenName, byteSend => byteSend);
    HOR : conv PORT MAP(clk => clk, char => horPixel, thou => horThou, hund => horHund, tens => horTens, ones => horOnes);
    VERT : conv PORT MAP(clk => clk, char => vertPixel, thou => vertThou, hund => vertHund, tens => vertTens, ones => vertOnes);
    PIXEL : conv PORT MAP(clk => clk, char => refreshRate, thou => refreshThou, hund => refreshHund, tens => refreshTens, ones => refreshOnes);
    UARTTX : UART_TX PORT MAP(clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            SDA <= '0' WHEN (isSend AND NOT SDAout) ELSE 'Z';
            SDAIn <= '1' WHEN SDA ELSE '0';
        END IF;
    END PROCESS;

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            IF NOT enableEDID THEN
                CASE currentDisplay IS
                WHEN NAME => nameString <= "Name: ";
                    nameLogic <= STR2SLV(nameString, nameLogic);
                    tx_data <= BITSHIFT(tx_name);
                    IF tx_valid = '1' AND tx_ready = '1' AND nameCounter < 5 THEN
                        IF counter /= 1 THEN
                            counter <= counter + 1;
                        ELSE
                            nameCounter <= nameCounter + 1;
                            counter <= 0;
                        END IF;
                    ELSIF tx_valid AND tx_ready THEN
                        nameCounter <= 0;
                        nextDisplay <= MANU;
                    ELSIF NOT tx_valid THEN
                        tx_valid <= '1';
                    END IF;
                WHEN MANU => tx_data <= screenName(7 + charInd * 8 DOWNTO charInd + 8);
                    IF charInd = 12 THEN
                        charInd <= 0;
                        nextDisplay <= RESO;
                    ELSE
                        charInd <= charInd + 1;
                    END IF;
                WHEN RESO => resoString <= "Resolution: ";
                    resoLogic <= STR2SLV(resoString, resoLogic);
                    tx_data <= BITSHIFT(tx_reso);
                    IF tx_valid = '1' AND tx_ready = '1' AND resoCounter < 5 THEN
                        IF counter /= 1 THEN
                            counter <= counter + 1;
                        ELSE
                            resoCounter <= resoCounter + 1;
                            counter <= 0;
                        END IF;
                    ELSIF tx_valid AND tx_ready THEN
                        resoCounter <= 0;
                        nextDisplay <= DIME;
                    ELSIF NOT tx_valid THEN
                        tx_valid <= '1';
                    END IF;
                WHEN DIME => IF tx_valid = '1' THEN
                    CASE counter IS
                    WHEN 0 => tx_data <= BITSHIFT(horThou);
                    WHEN 1 => tx_data <= BITSHIFT(horHund);
                    WHEN 2 => tx_data <= BITSHIFT(horTens);
                    WHEN 3 => tx_data <= BITSHIFT(horOnes);
                    WHEN 4 => tx_data <= BITSHIFT(SP);
                    WHEN 5 => tx_data <= BITSHIFT(x"78");
                    WHEN 6 => tx_data <= BITSHIFT(SP);
                    WHEN 7 => tx_data <= BITSHIFT(vertThou);
                    WHEN 8 => tx_data <= BITSHIFT(vertHund);
                    WHEN 9 => tx_data <= BITSHIFT(vertTens);
                    WHEN 10 => tx_data <= BITSHIFT(vertOnes);
                    WHEN 11 => tx_data <= BITSHIFT(SP);
                    WHEN 12 => tx_data <= BITSHIFT(x"40");
                    WHEN 13 => tx_data <= BITSHIFT(refreshTens);
                    WHEN 14 => tx_data <= BITSHIFT(refreshOnes);
                    WHEN 15 => tx_data <= BITSHIFT(x"48");
                    WHEN 16 => tx_data <= BITSHIFT(x"7A");
                    END CASE;
                    counter <= counter + 1;
                END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            IF NOT btn1 THEN
                enableEDID <= '0';
                nextMain <= READ;
            ELSE
                CASE currentMain IS
                WHEN READ => enableEDID <= '1';
                    nextMain <= WAITSTART;
                WHEN WAITSTART => IF NOT readyEDID THEN
                    nextMain <= WAITVALUE;
                END IF;
                WHEN WAITVALUE => IF readyEDID THEN
                    nextMain <= DONE;
                END IF;
                WHEN DONE => enableEDID <= '0';
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            tx_name <= nameLogic(47 - nameCounter * 8 DOWNTO 40 - nameCounter * 8);
            tx_reso <= resoLogic(95 - resoCounter * 8 DOWNTO 88 - resoCounter * 8);
        END IF;
    END PROCESS;
END ARCHITECTURE;
