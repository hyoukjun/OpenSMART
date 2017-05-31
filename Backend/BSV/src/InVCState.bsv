import Vector::*;
import Fifo::*;

import Types::*;
import MessageTypes::*;

interface InVCState;
  method Action         putHeader(Header routeInfo);
  method Maybe#(Header) peekHeader;
  method Action         deqHeader;
endinterface

(* synthesize *)
module mkInVCState(InVCState);
  Fifo#(1, Header) header <- mkPipelineFifo;

  method Action putHeader(Header hd);
    header.enq(hd);
  endmethod

  method Maybe#(Header) peekHeader;
    if(header.notEmpty) begin
      return Valid(header.first);
    end
    else begin
      return Invalid;
    end
  endmethod

  method Action deqHeader;
    header.deq;
  endmethod

endmodule
