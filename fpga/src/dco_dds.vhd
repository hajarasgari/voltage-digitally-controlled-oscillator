library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


entity DCO_DDS is
    Generic (
        WORD_SIZE : natural := 12; -- size of transfer word in bits, must be power of two
        BIT_CNT_WIDTH : natural := 32
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- INPUT INTERFACE
        TW          : in unsigned(BIT_CNT_WIDTH-1 downto 0); -- Tuning word
        -- OUTPUT INTERFACE
        F_DCO       : out std_logic 
    );
end entity;

architecture RTL of DCO_DDS is

-- component pll_149MHz 
--     port(
--         ref_clk_i: in std_logic;
--         rst_n_i: in std_logic;
--         outcore_o: out std_logic;
--         outglobal_o: out std_logic
--     );
-- end component;

signal clk_149MHz 		    : std_logic;
signal clk_149MHz_r			: std_logic;
signal acc_tmp              : unsigned(BIT_CNT_WIDTH downto 0);



begin

-- pll_149_MHz: pll_149MHz port map(
--    ref_clk_i=>CLK,
--    rst_n_i=>RST,
--    outcore_o=>clk_149MHz_r,
--    outglobal_o=>clk_149MHz
-- );

clk_149MHz <= CLK;
    -- -------------------------------------------------------------------------
    --  GENERATE F_VDCO WITH PRIOD TW
    -- -------------------------------------------------------------------------

    -- The counter counts received bits from the master. Counter is enabled when
    -- falling edge of SPI clock is detected and not asserted cs_n_reg.
    acc_dds : process (clk_149MHz)
    begin
        if (rising_edge(clk_149MHz)) then
            if (RST = '1') then
                acc_tmp <= '0'& TW;
            else
                if (acc_tmp(BIT_CNT_WIDTH) = '1') then
                    acc_tmp <= '0'& TW;
                else
                    acc_tmp <= acc_tmp + TW;
                end if;
            end if;
        end if;
    end process;

    -- The flag of maximal value of the bit counter.
    F_DCO <= acc_tmp(BIT_CNT_WIDTH);

end architecture;