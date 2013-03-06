--  An entity is a testbench if and only if it does not have any ports.

use work.ALL;
use std.textio.ALL;


entity mux_tb is
end mux_tb;

architecture test of mux_tb is
    
    -- declare the component (DUT)
    component mux2 is
        port(  in0 : in bit;
               in1 : in bit;
               sel    : in bit;
               zmux   : out bit
            );
    end component;

    signal data_0, data_1, sel, zmux, clk : BIT;

begin

    dut: mux2 port map(data_0, data_1, sel, zmux);

    clk <= not clk after 1 ns;

    process(clk)
    begin
        -- generate test vectors.
        data_0 <= not sel after 1 ns;
        data_1 <= not data_0 after 3 ns;
        sel <= not sel after 5 ns;

    end process;
    
    -- write assertion etc.

end architecture test;
    
