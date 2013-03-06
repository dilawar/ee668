-- This program was a part of assignment in last year VLSI lab course.
-- Submitted by : Abhinav Mittal 
-- 
-- Modified by : Dilawar Singh
--       dilawar@ee.iitb.ac.in

-- Modification log:
--    Jan 17, 2012 . Created.

entity mux2 is
    port (in0 , in1 ,sel : in BIT; 
          zmux : out BIT);
end mux2;

architecture arch_mux of mux2 is
    
    component and2
        port (a,b:in BIT;zand:out BIT);
    end component;
    
    component or2
        port (a,b:in BIT;zor:out BIT);
    end component;
    
    component not2
        port (a:in BIT; znot:out BIT);
    end component;	
    
    signal selectbar,temp0,temp1:BIT;

begin

    N1: not2 port map (sel,selectbar);
    A1: and2 port map (selectbar,in0,temp0);
    A2: and2 port map (sel,in1,temp1);
    O1: or2 port map (temp0,temp1,zmux);

end arch_mux;


entity or2 is
	port (a,b:in BIT;zor:out BIT);
end or2;
architecture arch_or2 of or2 is 
begin
	zor <= a or b ;
end arch_or2;



entity and2 is
	port (a,b:in BIT;zand:out BIT);
end and2;

architecture arch_and2 of and2 is 
begin
	zand <= a and b ;
end arch_and2;


entity not2 is
	port (a:in BIT;znot:out BIT);
end not2;

architecture arch_not2 of not2 is 
begin
	znot <= not a ;
end arch_not2;

