import Vector::*;
import Fifo::*;

import SmartTypes::*;


interface SSR_IO_Unit;
  method Action putInSSR(SSRBundle ssrs);
  method ActionValue#(Bool) hasInSSR_Requester;
  method Action putOutSSR(SSR ssr);
  method ActionValue#(SSR) getOutSSR;
endinterface


(* synthesize *)
module mkSSR_IO_Unit(SSR_IO_Unit);
 Fifo#(1, SSRBundle) ssrInBuf  <- mkBypassFifo;
 Fifo#(1, SSR)       ssrOutBuf <- mkBypassFifo;

  method Action putInSSR(SSRBundle ssrs);
    ssrInBuf.enq(ssrs);
  endmethod

  method ActionValue#(Bool) hasInSSR_Requester;
    if(ssrInBuf.notEmpty) begin
      let incomingSSRs = ssrInBuf.first;
      ssrInBuf.deq;
      return hasSSR_Requester(incomingSSRs);
    end
    else begin
      return False;
    end
  endmethod

  method Action putOutSSR(SSR ssr);
    ssrOutBuf.enq(ssr);
  endmethod
  
  method ActionValue#(SSR) getOutSSR;
    ssrOutBuf.deq;
    return ssrOutBuf.first;
  endmethod

endmodule




