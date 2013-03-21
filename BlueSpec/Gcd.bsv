package Gcd;
import FIFO::*;
import Vector::*;

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

  Integer vecSize = 10;

  Vector#(10, FIFO#(int)) fifoVec <- replicateM(mkFIFO);

  for(Integer i = 0; i < vecSize - 1; i = i+1) begin 
    rule r;
      let f = fifoVec[i];
      let ff = fifoVec[i+1];
      let v = f.first; f.deq;
      $display(" v = %0h", v);
      ff.enq(v+1);
    endrule   
  end 
  
  method Action send(int a);
    let f = fifoVec[0];
    f.enq(a);
  endmethod

  method ActionValue#(int) recieve ();
    let f = fifoVec[9];
    let v = f.first;
    $display(" v = %0h", v);
    f.deq;
    return v;
  endmethod

endmodule : mkPipe

endpackage:Gcd
