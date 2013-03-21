package Gcd;
import FIFO::*;

(* synthesize *)
module mkGcd (Empty);

  Reg#(int) x <- mkReg(0);
  Pipe_ifc pipe <- mkPipe;

  rule fill;
    pipe.send (x);
    x <= x + 1;
  endrule

  rule drain;
    let y <- pipe.recieve();
    $display("   y = %0h", y);
    if(y > 'h80) $finish(0);
  endrule 
endmodule

interface Pipe_ifc;
  method Action send(int a);
  method ActionValue#(int) recieve();
endinterface

(* synthesize *)
module mkPipe (Pipe_ifc);

  FIFO#(int) f1 <- mkFIFO;
  FIFO#(int) f2 <- mkFIFO;
  FIFO#(int) f3 <- mkFIFO;
  FIFO#(int) f4 <- mkFIFO;

  rule r2;
    let v1 = f1.first; f1.deq;
    $display(" v1 = %0h", v1);
    f2.enq(v1+1);
  endrule 

  rule r3;
    let v2 = f2.first; f2.deq;
    $display(" v2 = %0h", v2);
    f3.enq(v2+1);
  endrule 

 rule r4;
    let v3 = f3.first; f3.deq;
    $display(" v3 = %0h", v3);
    f4.enq(v3+1);
  endrule 

  method Action send(int a);
    f1.enq (a);
  endmethod

  method ActionValue#(int) recieve ();
    let v4 = f4.first;
    $display(" v4 = %0h", v4);
    f4.deq;
    return v4;
  endmethod

endmodule : mkPipe

endpackage:Gcd
