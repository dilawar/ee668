-------------------------------------------------------------------------------
-- Pyri Villainicus, (c) 2013
-- His human form is known as Dilawar, pronounced 'the law were'. He can be
-- reached at dilawar@ee.iitb.ac.in
-------------------------------------------------------------------------------

-- NOTICE : VHDL does not differentiate between lower-case and upper-case words. 

-- These are standard libraries one HAS TO include. 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- All of your current designs are stored in WORK library. In ghdl you can 
-- change its path by --work option. We are pretending to use it as if a lot of 
-- work has been done in WORK library.
USE WORK.ALL;

-- Here goes the declaration of our entity.
ENTITY demoEntity IS 
  PORT(
  a, b : IN BIT;
  reset : IN BIT;
  clk : IN BIT;
  q   : OUT BIT
);
END ENTITY;

-- Structural architecture
ARCHITECTURE structural OF demoEntity IS 
  -- Declare components. These components have entity-architecture pairs 
  -- declared some other file (or may be in this file also). 
  -- We can also use already available components in some library like we 
  -- use functions available in some library.
  COMPONENT and2
    port(in1, in2 : in bit;
        out1 : out bit
      );
  end COMPONENT;

  COMPONENT or2
    port(in1, in2 : in bit;
         out1 : out bit
       );
  end COMPONENT;

  COMPONENT not1 
    port(in1 : in bit;
        out1 : out bit 
      );
  end COMPONENT;

  COMPONENT dff 
    port(d : IN BIT;
        clk : IN BIT;
        reset : IN BIT;
        q : OUT BIT
      );
  END COMPONENT;

  -- Local signal (like local variables in C).
  signal andOut, notOut : bit;
  signal orOut : bit;

BEGIN 
  -- Now inside the architecture, describe the structure of model. 
  -- Port map declares which port is connected with what.
  -- There is one more style to map the ports.
  A1 : and2 port map(a, b, andOut);
  N1 : not1 port map(b, notOut);
  O1 : or2 port map(andOut, notOut, orOut);
  D1 : dff port map(orOut, clk, reset, q);

END structural;

-- behavioural architecture
ARCHITECTURE behav of demoEntity IS 
BEGIN
PROCESS(clk, reset) 
  BEGIN 
    if(reset = '1') then 
      q <= '0';
    elsif(clk'event and clk='1') then 
      q <= ( a and b) or (not b);
    end if;
  END PROCESS;
END behav;
