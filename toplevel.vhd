LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.states.ALL;
USE WORK.dataBytes.ALL;

ENTITY toplevel IS
    PORT(clk, btn1, RST : IN STD_LOGIC;
         SCL, TX, mirrord, mirrorc, LED : OUT STD_LOGIC := '1';
         SDA : INOUT STD_LOGIC := '1'
         );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
TYPE main IS (READ, WAITSTART, WAITVALUE, DONE);
SIGNAL currentMain : main := READ;

TYPE display IS (HOLD, PRNTALL, NAME, MANU, RESO, DIME);
SIGNAL currentDisplay : display := HOLD;

CONSTANT CR : STD_LOGIC_VECTOR := x"0D"; --Carriage Return
CONSTANT LF : STD_LOGIC_VECTOR := x"0A"; --Line Feed
CONSTANT BS : STD_LOGIC_VECTOR := x"08"; --Backspace
CONSTANT ESC : STD_LOGIC_VECTOR := x"1B"; --Escape
CONSTANT SP : STD_LOGIC_VECTOR := x"20"; --Space
CONSTANT DEL  : STD_LOGIC_VECTOR := x"7F"; --Delete

SIGNAL nameString : STRING (1 TO 6);
SIGNAL nameLogic : STD_LOGIC_VECTOR (0 TO 47);

SIGNAL resoString : STRING (1 TO 12);
SIGNAL resoLogic : STD_LOGIC_VECTOR (0 TO 95);

SIGNAL tx_valid, tx_ready : STD_LOGIC;
SIGNAL tx_data, tx_name, tx_reso, creator : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL isSend, SDAIn, SDAOut, I2CComp, I2CEnable : STD_LOGIC;
SIGNAL I2CInstruc : state;
SIGNAL byteSend, byteRCV : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL enableEDID, readyEDID, parseReady : STD_LOGIC;
SIGNAL charInd : INTEGER RANGE 0 TO 13 := 0;
SIGNAL horPixel, vertPixel, refreshRate : STD_LOGIC_VECTOR (11 DOWNTO 0);
SIGNAL screenName : STD_LOGIC_VECTOR (103 DOWNTO 0);

SIGNAL horThou, horHund, horTens, horOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL vertThou, vertHund, vertTens, vertOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL refreshThou, refreshHund, refreshTens, refreshOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL counter : INTEGER RANGE 0 TO 18 := 0;
SIGNAL nameCounter, resoCounter : INTEGER RANGE 0 TO 13 := 0;
SIGNAL dataCounter : INTEGER RANGE 0 TO 256 := 0;

SIGNAL readData : data;

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

COMPONENT EDIDI2C IS
    PORT(clk, enable, compI2C : IN STD_LOGIC;
         byteRCV : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ready : OUT STD_LOGIC := '1';
         enableI2C : OUT STD_LOGIC := '0';
         parseReady : OUT STD_LOGIC := '0';
         instructionI2C : OUT state;
         readData : OUT data;
         byteSend : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

COMPONENT EDID IS
    PORT(clk, enable : IN STD_LOGIC;
         readData : IN data;
         LED : OUT STD_LOGIC;
         horPixel, vertPixel, refreshRate : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
         screenName : OUT STD_LOGIC_VECTOR (103 DOWNTO 0)
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

IMPURE FUNCTION STR2SLV (str : STRING; size : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data : STD_LOGIC_VECTOR(0 TO size'LENGTH - 1);
    BEGIN
    FOR i IN str'RANGE LOOP
        data(i * 8 - 8 TO i * 8 - 1) := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(str(i)), 8));
    END LOOP;
    RETURN data;
END FUNCTION;

IMPURE FUNCTION BITSHIFT (data : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE str : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
    FOR i IN 0 TO 7 LOOP
        str(i) := data(7 - i);
    END LOOP;
    RETURN str;
END FUNCTION;

BEGIN
    DATA : I2C PORT MAP(clk => clk, SDAin => SDAIn, enable => I2CEnable, instruction => I2CInstruc, byteSend => byteSend, complete => I2Ccomp, SDAout => SDAOut, SCL => SCL, isSend => isSend, byteReceived => byteRCV);
    INFO : EDID PORT MAP(clk => clk, enable => parseReady, readData => readData, LED => LED, horPixel => horPixel, vertPixel => vertPixel, refreshRate => refreshRate, screenName => screenName);
    INFOI2C : EDIDI2C PORT MAP(clk => clk, enable => enableEDID, compI2C => I2CComp, byteRCV => byteRCV, ready => readyEDID, enableI2C => I2CEnable, parseReady => parseReady, instructionI2C => I2CInstruc, readData => readData, byteSend => byteSend);
    HOR : conv PORT MAP(clk => clk, char => horPixel, thou => horThou, hund => horHund, tens => horTens, ones => horOnes);
    VERT : conv PORT MAP(clk => clk, char => vertPixel, thou => vertThou, hund => vertHund, tens => vertTens, ones => vertOnes);
    PIXEL : conv PORT MAP(clk => clk, char => refreshRate, thou => refreshThou, hund => refreshHund, tens => refreshTens, ones => refreshOnes);
    UARTTX : UART_TX PORT MAP(clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            SDA <= '0' WHEN (isSend AND NOT SDAOut) ELSE 'Z';
            SDAIn <= '1' WHEN SDA ELSE '0';
            mirrord <= SDA;
            mirrorc <= SCL;
        END IF;
    END PROCESS;

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentDisplay IS
            WHEN HOLD => nameString <= "      ";
                nameLogic <= (OTHERS => '0');
                resoString <= "            ";
                resoLogic <= (OTHERS => '0');
                tx_valid <= '0';
                tx_data <= (OTHERS => '0');
                charInd <= 0;
                counter <= 0;
                dataCounter <= 0;
                nameCounter <= 0;
                resoCounter <= 0;
                IF parseReady THEN
                    tx_valid <= '1';
                    currentDisplay <= PRNTALL;
                END IF;
            WHEN PRNTALL => tx_data <= readData(dataCounter);
                IF tx_valid = '1' AND tx_ready = '1' AND dataCounter < 255 THEN
                    dataCounter <= dataCounter + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    dataCounter <= 0;
                    currentDisplay <= NAME;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN NAME => nameString <= "Name: ";
                nameLogic <= STR2SLV(nameString, nameLogic);
                tx_data <= tx_name;
                IF tx_valid = '1' AND tx_ready = '1' AND nameCounter < 5 THEN
                    nameCounter <= nameCounter + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    nameCounter <= 0;
                    currentDisplay <= MANU;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN MANU => creator <= screenName(7 + charInd * 8 DOWNTO charInd * 8);
                tx_data <= creator;
                IF tx_valid = '1' AND tx_ready = '1' AND charInd < 11 THEN
                    charInd <= charInd + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    charInd <= 0;
                    currentDisplay <= RESO;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN RESO => resoString <= "Resolution: ";
                resoLogic <= STR2SLV(resoString, resoLogic);
                tx_data <= tx_reso;
                IF tx_valid = '1' AND tx_ready = '1' AND resoCounter < 11 THEN
                    resoCounter <= resoCounter + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    resoCounter <= 0;
                    currentDisplay <= DIME;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN DIME => IF tx_valid = '1' AND tx_ready = '1' THEN
                CASE counter IS
                WHEN 0 => tx_data <= horThou;
                    tx_valid <= '0';
                WHEN 1 => tx_data <= horHund;
                    tx_valid <= '0';
                WHEN 2 => tx_data <= horTens;
                    tx_valid <= '0';
                WHEN 3 => tx_data <= horOnes;
                    tx_valid <= '0';
                WHEN 4 => tx_data <= SP;
                    tx_valid <= '0';
                WHEN 5 => tx_data <= x"78";
                    tx_valid <= '0';
                WHEN 6 => tx_data <= SP;
                    tx_valid <= '0';
                WHEN 7 => tx_data <= vertThou;
                    tx_valid <= '0';
                WHEN 8 => tx_data <= vertHund;
                    tx_valid <= '0';
                WHEN 9 => tx_data <= vertTens;
                    tx_valid <= '0';
                WHEN 10 => tx_data <= vertOnes;
                    tx_valid <= '0';
                WHEN 11 => tx_data <= SP; 
                    tx_valid <= '0';
                WHEN 12 => tx_data <= x"40";
                    tx_valid <= '0';
                WHEN 13 => tx_data <= refreshTens;
                    tx_valid <= '0';
                WHEN 14 => tx_data <= refreshOnes;
                    tx_valid <= '0';
                WHEN 15 => tx_data <= x"48";
                    tx_valid <= '0';
                WHEN 16 => tx_data <= x"7A";
                    tx_valid <= '0';
                WHEN 17 => currentDisplay <= HOLD;
                WHEN OTHERS => NULL;
                END CASE;
                counter <= counter + 1;
            ELSIF tx_valid <= '0' THEN
                tx_valid <= '1';
            END IF;
            END CASE;
        END IF;
    END PROCESS;

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            IF NOT btn1 THEN
                enableEDID <= '0';
                currentMain <= READ;
            ELSE
                CASE currentMain IS
                WHEN READ => enableEDID <= '1';
                    currentMain <= WAITSTART;
                WHEN WAITSTART => IF NOT readyEDID THEN
                    currentMain <= WAITVALUE;
                END IF;
                WHEN WAITVALUE => IF readyEDID THEN
                    currentMain <= DONE;
                END IF;
                WHEN DONE => enableEDID <= '0';
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            tx_name <= nameLogic(nameCounter * 8 TO nameCounter * 8 + 7);
            tx_reso <= resoLogic(resoCounter * 8 TO resoCounter * 8 + 7);
        END IF;
    END PROCESS;
END ARCHITECTURE;
