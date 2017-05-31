import Vector::*;
import Fifo::*;

import Types::*;
import VirtualChannelTypes::*;

interface TrafficGenVCAlloc;

  method ActionValue#(VCIdx) getVC;
  method Action putVC(VCIdx vc);

endinterface

(* synthesize *)
module mkTrafficGenVCAlloc(TrafficGenVCAlloc);

  Reg#(Bool)           inited     <- mkReg(False);
  Reg#(VCIdx)          initCount  <- mkReg(0);
  Fifo#(NumVCs, VCIdx) freeVCPool <- mkBypassFifo;

  rule initialize(!inited);
    if(initCount < fromInteger(valueOf(NumVCs))) begin
      freeVCPool.enq(initCount);    
      initCount <= initCount + 1;   
    end
    else begin
      inited <= True;    
    end    
  endrule

  method ActionValue#(VCIdx) getVC if(inited);
    freeVCPool.deq;    
    return freeVCPool.first;
  endmethod
  
  method Action putVC(VCIdx vc) if(inited);
     freeVCPool.enq(vc);
  endmethod
  
endmodule
