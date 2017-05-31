import Fifo::*;
import Vector::*;
import CReg::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;

interface VirtualChannel;
  method Action putFlit(Flit flit);
  method ActionValue#(Flit) getTopFlit;
  method Flit peekTopFlit;
  method Bool isReady;
endinterface

(* synthesize *)
module mkVirtualChannel(VirtualChannel);
  Fifo#(MaxVCDepth, Flit)  flitQueue <- mkPipelineFifo;

  rule rl_(...);

  endrule


  
  method Action putFlit(Flit flit);
    flitQueue.enq(flit);
  endmethod

  method ActionValue#(Flit) getTopFlit;
    flitQueue.deq;
    return flitQueue.first;
  endmethod

  method Flit peekTopFlit;
    return flitQueue.first;	
  endmethod

  method Bool isReady;
    return flitQueue.notEmpty;
  endmethod

endmodule
