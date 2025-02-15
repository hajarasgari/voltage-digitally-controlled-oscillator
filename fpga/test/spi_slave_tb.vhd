--------------------------------------------------------------------------------
-- PROJECT: SPI MASTER AND SLAVE FOR FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/spi-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity SPI_SLAVE_TB is
    Generic (
        CLK_FREQ      : natural := 12e6; -- system clock frequency in Hz
        SPI_FREQ      : natural := 4e5;  -- spi clock frequency in Hz
        WORD_SIZE     : natural := 16;    -- size of transfer word in bits, must be power of two
        TRANS_COUNT   : natural := 1e4   -- number of test transaction
    );
end entity;

architecture SIM of SPI_SLAVE_TB is

    constant CLK_PERIOD : time := 1 ns * integer(real(1e9)/real(CLK_FREQ));
    constant SPI_PERIOD : time := 1 ns * integer(real(1e9)/real(SPI_FREQ));
    constant RX_OFFSET  : natural := 42;
    constant TX_OFFSET  : natural := 11;

    signal CLK            : std_logic;
    signal RST            : std_logic;

    signal sclk           : std_logic := '0';
    signal mosi           : std_logic;

    signal udo            : std_logic_vector(WORD_SIZE-1 downto 0);
    signal udo_exp        : std_logic_vector(WORD_SIZE-1 downto 0);
    signal udo_vld        : std_logic;
    
    signal spi_mdi        : std_logic_vector(WORD_SIZE-1 downto 0);

    signal spi_model_done : std_logic := '0';
    signal udo_done       : std_logic := '0';
    signal sim_done       : std_logic := '0';
    signal rand_int       : integer := 0;
    signal count_rx       : integer;
    signal count_tx       : integer;

    procedure SPI_MASTER (
        constant SPI_PER : time;
        signal SMM_MDI  : in  std_logic_vector(WORD_SIZE-1 downto 0);
        signal SMM_SCLK : out std_logic;
        signal SMM_MOSI : out std_logic
    ) is
    begin
        for i in 0 to (WORD_SIZE-1) loop
            SMM_SCLK <= '0';
            SMM_MOSI <= SMM_MDI(WORD_SIZE-1-i);
            wait for SPI_PER/2;
            SMM_SCLK <= '1';
            wait for SPI_PER/2;
        end loop;
        SMM_SCLK <= '0';
        wait for SPI_PER/2;
    end procedure;

begin

    rand_int_p : process
        variable seed1, seed2: positive;
        variable rand : real;
    begin
        uniform(seed1, seed2, rand);
        rand_int <= integer(rand*real(20));
        --report "Random number X: " & integer'image(rand_int);
        wait for CLK_PERIOD;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    dut : entity work.SPI_SLAVE
    generic map (
        WORD_SIZE => WORD_SIZE
    )
    port map (
        CLK      => CLK,
        RST      => RST,
        -- SPI MASTER INTERFACE
        SCK     => sclk,
        MOSI     => mosi,
        -- USER INTERFACE
        DOUT     => udo,
        DOUT_VLD => udo_vld
    );

    clk_gen_p : process
    begin
        CLK <= '0';
        wait for CLK_PERIOD/2;
        CLK <= '1';
        wait for CLK_PERIOD/2;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    rst_gen_p : process
    begin
        report "======== SIMULATION START! ========";
        report "Total transactions for master to slave direction: " & integer'image(TRANS_COUNT);
        report "Total transactions for slave to master direction: " & integer'image(TRANS_COUNT);
        RST <= '1';
        wait for CLK_PERIOD*3;
        RST <= '0';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  DUT TEST
    -- -------------------------------------------------------------------------

    spi_master_model_p : process
    begin
        count_tx <= 1;
        sclk <= '0';
        wait until RST = '0';
        wait for 33 ns;
        for i in 0 to TRANS_COUNT-1 loop
            spi_mdi     <= std_logic_vector(to_unsigned(((i+RX_OFFSET) mod 2**WORD_SIZE),WORD_SIZE));
            wait for SPI_PERIOD/2; -- minimum idle time between transactions
            SPI_MASTER(SPI_PERIOD, spi_mdi, sclk,  mosi);

            count_tx <= count_tx + 1;
            wait for (rand_int/2) * SPI_PERIOD;
        end loop;
        spi_model_done <= '1';
        wait;
    end process;


    spi_slave_udo_p : process
    begin
        count_rx <= 1;
        for i in 0 to TRANS_COUNT-1 loop
            udo_exp <= std_logic_vector(to_unsigned(((i+RX_OFFSET) mod 2**WORD_SIZE),WORD_SIZE));
            wait until udo_vld = '1';
            if (udo = udo_exp) then
                if ((count_rx mod (TRANS_COUNT/10)) = 0) then
                    report "Transactions received from master: " & integer'image(count_rx);
                end if;
            else
                report "======== UNEXPECTED TRANSACTION ON DOUT SIGNAL (master to slave)! ========" severity failure;
            end if;
            count_rx <= count_rx + 1;
            wait for CLK_PERIOD;
        end loop;
        udo_done <= '1';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  TEST DONE CHECK
    -- -------------------------------------------------------------------------

    test_done_p : process
        variable v_test_done : std_logic;
    begin
        v_test_done := udo_done and spi_model_done;
        if (v_test_done = '1') then
            wait for 100*CLK_PERIOD;
            sim_done <= '1';
            report "======== SIMULATION SUCCESSFULLY COMPLETED! ========";
            wait;
        end if;
        wait for CLK_PERIOD;
    end process;

end architecture;
