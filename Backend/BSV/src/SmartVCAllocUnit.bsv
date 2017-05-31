import Vector::*;
import Types::*;
import Fifo::*;
import VCAllocUnitTypes::*;

import CreditReg::*;
import VirtualChannelTypes::*;

interface SmartVCAllocUnit;
  method Bool isInited;
  method Bool hasVC;
  method Bool hasVC2;
  method ActionValue#(VCIdx) getNextVC;

  method Action putFreeVC(VCIdx vc);
endinterface

(* synthesize *)
module mkSmartVCAllocUnit(SmartVCAllocUnit);
  Reg#(Bool)                 inited     <- mkReg(False);
  Reg#(VCIdx)                initCount  <- mkReg(0);

  Fifo#(NumVCs, VCIdx)       freeVCPool <- mkBypassFifo;
//  CreditReg                  creditReg  <- mkCreditReg;

  rule initialize(!inited);
    if(initCount < fromInteger(valueOf(NumVCs))) begin
      freeVCPool.enq(initCount);
      initCount <= initCount+1;
    end
    else begin
      inited <= True;
    end
  endrule

  function Bool hasAvailableVC = freeVCPool.notEmpty;

  method Bool isInited = inited;
//  method Bool hasVC = freeVCPool.notEmpty;
  method Bool hasVC = hasAvailableVC;
  method Bool hasVC2 = hasAvailableVC;

  method ActionValue#(VCIdx) getNextVC;
    let vc = freeVCPool.first;
    freeVCPool.deq;
    return vc;
  endmethod	  

  method Action putFreeVC(VCIdx vc) if(inited);
    freeVCPool.enq(vc);
  endmethod
endmodule
