import Vector::*;
import Fifo::*;

import Types::*;
import SmartTypes::*;

interface SSR_Buffer;
  method Action putSSRs(SSRBundle ssrSignal);
  method SSRBundle getSSRs;
  method ActionValue#(SSRBundle) deqSSRs;
endinterface

(* synthesize *)
module mkSSR_Buffer(SSR_Buffer);
  Fifo#(1, SSRBundle) buffer <- mkBypassFifo;

  method Action putSSRs(SSRBundle ssrSignal);
    buffer.enq(ssrSignal);
  endmethod

  method SSRBundle getSSRs;
    return buffer.first;
  endmethod

  method ActionValue#(SSRBundle) deqSSRs;
    buffer.deq;
    return buffer.first;
  endmethod
endmodule
