import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import MessageTypes::*;
import SwitchAllocTypes::*;
import RoutingTypes::*;

import CrossbarBuffer::*;

interface CrossbarPort;
  method Action putFlit(Flit traverseFlit, DirIdx destDirn);
  method ActionValue#(Flit) getFlit; 
endinterface

interface CrossbarSwitch;
  interface Vector#(NumPorts, CrossbarPort) crossbarPorts;
endinterface

(* synthesize *)
module mkCrossbarSwitch(CrossbarSwitch);
  
  Vector#(NumPorts, CrossbarBuffer) outBuffer <- replicateM(mkCrossbarBuffer);
 
  Vector#(NumPorts, CrossbarPort) crossbarPortsDummy;
  for(Integer prt = 0; prt < valueOf(NumPorts); prt = prt+1) begin
    crossbarPortsDummy[prt] = 
      interface CrossbarPort

        //Input side
        method Action putFlit(Flit traverseFlit, DirIdx destDirn);
          outBuffer[destDirn].bufferChannel[prt].putFlit(traverseFlit);
        endmethod

        //Output side
        method ActionValue#(Flit) getFlit;
          let ret <- outBuffer[prt].getFlit;
          return ret;
        endmethod
      endinterface;
  end
  interface crossbarPorts = crossbarPortsDummy;

endmodule
