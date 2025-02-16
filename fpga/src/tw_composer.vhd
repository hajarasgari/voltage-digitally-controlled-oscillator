library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


entity TW_COMPOSER is
    Generic (
        WORD_SIZE : natural := 12; -- size of transfer word in bits, must be power of two
        BIT_CNT_WIDTH : natural := 32
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- INPUT INTERFACE
        SPI_VLD     : in  std_logic; -- SPI output valid signal
        SPI_DATA    : in  std_logic_vector(WORD_SIZE-1 downto 0); -- SPI chip select, active in low
        -- OUTPUT INTERFACE
        TW          : out unsigned(BIT_CNT_WIDTH-1 downto 0) -- Tuning word
    );
end entity;

architecture RTL of TW_COMPOSER is

signal spi_data_r: std_logic_vector(WORD_SIZE-1 downto 0);
signal bit_cnt            : unsigned(BIT_CNT_WIDTH-1 downto 0);
signal fill_zero_r: std_logic_vector((BIT_CNT_WIDTH-WORD_SIZE-1) downto 0) := (others=>'0');
signal tw_r: std_logic_vector(BIT_CNT_WIDTH-1 downto 0);
signal tw_div2: std_logic_vector(BIT_CNT_WIDTH-1 downto 0);
signal TW_OFFSET : integer := 2433814;


begin

    -- -------------------------------------------------------------------------
    --  STORING  SPI DATA WHEN IT IS VALID
    -- -------------------------------------------------------------------------

    -- The dco module recieves the spi data when it is valid
    spi_rcv_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_data_r <= (others => '0');
            elsif (SPI_VLD = '1') then
                spi_data_r <= SPI_DATA;
            else
                spi_data_r <= spi_data_r;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  CALCULATE  TW BASED ON INPUT TW  and TW_OFFSET
    -- -------------------------------------------------------------------------

    -- tw_r <= fill_zero_r & spi_data_r;

	-- tw_div2 <= ('0' & tw_r(BIT_CNT_WIDTH-1 downto 1));

	TW <= to_unsigned(TW_OFFSET,32)  + unsigned(fill_zero_r & spi_data_r);

end architecture;