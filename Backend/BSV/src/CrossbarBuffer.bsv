import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import MessageTypes::*;
import SwitchAllocTypes::*;
import RoutingTypes::*;


interface CrossbarBufferChannel;
  method Action putFlit(Flit flit);
endinterface

interface CrossbarBuffer;
  method ActionValue#(Flit) getFlit;
  interface Vector#(NumPorts, CrossbarBufferChannel) bufferChannel;
endinterface

(* synthesize *)
module mkCrossbarBuffer(CrossbarBuffer);

  CReg#(TAdd#(NumPorts, 1), Maybe#(Flit)) buffer <- mkCReg(Invalid);

  Vector#(NumPorts, CrossbarBufferChannel) bufferChannelDummy;
  for(Integer prt=0; prt<valueOf(NumPorts); prt=prt+1) begin
    bufferChannelDummy[prt] = 
      interface CrossbarBufferChannel
        method Action putFlit(Flit flit);
          buffer[prt] <= Valid(flit);
        endmethod
      endinterface;
  end

  interface bufferChannel = bufferChannelDummy;

  method ActionValue#(Flit) getFlit if(isValid(buffer[valueOf(NumPorts)]));
    buffer[valueOf(NumPorts)] <= Invalid;
    return validValue(buffer[valueOf(NumPorts)]);
  endmethod

endmodule

