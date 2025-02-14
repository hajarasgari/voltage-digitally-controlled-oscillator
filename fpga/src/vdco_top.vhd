library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- THE SPI SLAVE MODULE SUPPORT ONLY SPI MODE 0 (CPOL=0, CPHA=0)!!!

entity VDCO_TOP is
    Generic (
        WORD_SIZE : natural := 16; -- size of transfer word in bits, must be power of two
        BIT_CNT_WIDTH : natural := 32;
		TW_OFFSET : natural := 21911
    );
    Port (
        CLK      : in  std_logic; -- system clock
        RST      : in  std_logic; -- high active synchronous reset
        -- SPI SLAVE INTERFACE
        SCK     : in  std_logic; -- SPI clock
        MOSI     : in  std_logic; -- SPI serial data from master to slave
        -- USER INTERFACE
        F_VDCO   : out std_logic  -- when DOUT_VLD = 1, received data are valid
		--RGB0		 : out std_logic;
		--RGB1		 : out std_logic;
		--RGB2		 : out std_logic
    );
end entity;

architecture RTL of VDCO_TOP is
-- component declaration

component SPI_SLAVE 
    Generic (
        WORD_SIZE : natural := WORD_SIZE  -- size of transfer word in bits, must be power of two
    );
    Port (
        CLK      : in  std_logic;
        RST      : in  std_logic;
        -- SPI SLAVE INTERFACE
        SCK     : in  std_logic;
        MOSI     : in  std_logic;
        -- USER INTERFACE
        DOUT     : out std_logic_vector(WORD_SIZE-1 downto 0); 
        DOUT_VLD : out std_logic  
    );
end component;

component TW_COMPOSER
    Generic (
        WORD_SIZE : natural := WORD_SIZE; 
        BIT_CNT_WIDTH : natural := BIT_CNT_WIDTH
		--TW_OFFSET : natural := 21911
    );
    Port (
        CLK         : in  std_logic; 
        RST         : in  std_logic; 
        -- INPUT INTERFACE
        SPI_VLD     : in  std_logic; 
        SPI_DATA    : in  std_logic_vector(WORD_SIZE-1 downto 0); 
        -- OUTPUT INTERFACE
        TW          : out unsigned(BIT_CNT_WIDTH-1 downto 0) 
    );
end component;

component DCO
    Generic (
        WORD_SIZE : natural := WORD_SIZE;
        BIT_CNT_WIDTH : natural := BIT_CNT_WIDTH
    );
    Port (
        CLK         : in  std_logic;
        RST         : in  std_logic; 
        -- INPUT INTERFACE
		TW          : in unsigned(BIT_CNT_WIDTH-1 downto 0);
        -- OUTPUT INTERFACE
        F_DCO       : out  std_logic  
    );
end component;

signal spi_dout         : std_logic_vector(WORD_SIZE-1 downto 0); -- received data from SPI master
signal spi_dout_vld : std_logic;  -- when DOUT_VLD = 1, received data are valid
signal DOUT     : std_logic_vector(WORD_SIZE-1 downto 0);
signal F_VDCO_r : std_logic;
signal tw_r          : unsigned(BIT_CNT_WIDTH-1 downto 0);

begin

spi_simple_slave : SPI_SLAVE
    generic map (
        WORD_SIZE => WORD_SIZE
    )
    port map (
        CLK      => CLK,
        RST      => RST,
        -- SPI MASTER INTERFACE
        SCK     => SCK,
        MOSI     => MOSI,
        -- USER INTERFACE
        DOUT     => spi_dout,
        DOUT_VLD => spi_dout_vld
    );

tw_composer_unit : TW_COMPOSER
    generic map (
        WORD_SIZE => WORD_SIZE, 
        BIT_CNT_WIDTH => BIT_CNT_WIDTH
		--TW_OFFSET => TW_OFFSET
    )
    port map (
        CLK         => CLK, 
        RST         => RST,  
        -- INPUT INTERFACE
        SPI_VLD     => spi_dout_vld, 
        SPI_DATA    => spi_dout, 
        -- OUTPUT INTERFACE
        TW          => tw_r 
    );


dco_unit : DCO
    generic map (
        WORD_SIZE => WORD_SIZE
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- INPUT INTERFACE
        TW          => tw_r,
        -- OUTPUT INTERFACE
        F_DCO       => F_VDCO
    );
	
	F_VDCO<= CLK;
	--RGB0 <= '1';
	--RGB1 <= '0';
	--RGB2 <= '0';
	
end architecture;