import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import MessageTypes::*;

interface OutputUnit;
  method Action putFlit(Flit flit);
  method ActionValue#(Flit) getFlit;
endinterface

(* synthesize *)
module mkOutputUnit(OutputUnit);

  Fifo#(1, Flit) outBuffer <- mkPipelineFifo;

  method Action putFlit(Flit flit);
    outBuffer.enq(flit);
  endmethod

  method ActionValue#(Flit) getFlit;
    outBuffer.deq;
    return outBuffer.first;
  endmethod

endmodule
