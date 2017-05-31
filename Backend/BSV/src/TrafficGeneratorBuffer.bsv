import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;


interface TrafficGeneratorBuffer;
  method Data getRemainingFlitsNumber;
//  method Data getExtraLatency(Data clkCount);
  method Action putFlit(Flit flit);//, Data clkCount);
  method ActionValue#(Flit) getFlit;
endinterface

(* synthesize *)
module mkTrafficGeneratorBuffer(TrafficGeneratorBuffer);
  Fifo#(NumTrafficGeneratorBufferSlots, Flit) tempFifo <- mkBypassFifo;
//  CReg#(2, Data) clkCountReg <- mkCReg(0);
  CReg#(2, Data) remainingFlits <- mkCReg(0);
  
  method Data getRemainingFlitsNumber = remainingFlits[0];

/*
  method Data getExtraLatency(Data clkCount);
    return (clkCount * remainingFlits[0] - clkCountReg[0]);
  endmethod
*/

  method Action putFlit(Flit flit);//, Data clkCount);
    remainingFlits[0] <= remainingFlits[0] + 1;
//    clkCountReg[0] <= clkCountReg[0] + clkCount;

//    flit.stat.injectedCycle = clkCount;
    tempFifo.enq(flit);
  endmethod

  method ActionValue#(Flit) getFlit;
    let flit = tempFifo.first;
    remainingFlits[1] <= remainingFlits[1] - 1;
//    clkCountReg[1] <= clkCountReg[1] - flit.stat.injectedCycle;
    tempFifo.deq;
    return flit;
  endmethod

endmodule

