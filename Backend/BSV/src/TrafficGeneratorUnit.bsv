import Vector::*;
import Fifo::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;
import CreditTypes::*;

import TrafficGenerator::*;
import SmartVCAllocUnit::*;

interface TrafficGeneratorUnit;
  method Action initialize(MeshHIdx yID, MeshWIdx xID);
  method Action genFlit(Data clkCount);
  method ActionValue#(Flit) getFlit;
  method Action putVC(CreditSignal sig);
endinterface

(* synthesize *)
module mkTrafficGeneratorUnit(TrafficGeneratorUnit);
  SmartVCAllocUnit vcAllocUnit <- mkSmartVCAllocUnit;
  TrafficGenerator trafficGenerator <- mkUniformRandom;
//  TrafficGenerator trafficGenerator <- mkBitComplement;

  Fifo#(NumTrafficGeneratorBufferSlots, Flit) tempFifo <- mkBypassFifo;
  Fifo#(1, Flit) outFifo <- mkBypassFifo;

/*
  rule rl_getFlit;
    let flit <- trafficGenerator.getFlit;
    tempFifo.enq(flit);
  endrule
*/

  rule rl_getVC;
    let flit = tempFifo.first;
    tempFifo.deq;
    let vc <- vcAllocUnit.getNextVC;
    flit.vc = vc;
    outFifo.enq(flit);
  endrule

  method Action genFlit(Data clkCount);
    let flit <- trafficGenerator.getFlit;
    flit.stat.injectedCycle = clkCount;
    tempFifo.enq(flit);
  endmethod

  method Action initialize(MeshHIdx yID, MeshWIdx xID);
    trafficGenerator.initialize(yID, xID);
  endmethod

  method ActionValue#(Flit) getFlit;
    outFifo.deq;
    return outFifo.first;
  endmethod

  method Action putVC(CreditSignal sig);
    if(isValid(sig)) begin
      vcAllocUnit.putFreeVC(validValue(sig).vc);
    end
  endmethod

endmodule
