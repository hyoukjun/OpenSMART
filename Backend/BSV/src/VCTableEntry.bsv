import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import RoutingTypes::*;
import VirtualChannelTypes::*;

import VCAllocUnitTypes::*;


interface VCTableEntry;
  method Maybe#(VCIdx) getTargetVC;
  method Action        putTargetVC(VCIdx newTargetVC);
  method Action        invalidate;
endinterface

/*
  Method order
    isValidEntry < getTargetVC < putTargetVC < invalidate
*/

(* synthesize *)
module mkVCTableEntry(VCTableEntry);

  CReg#(2, Maybe#(VCIdx))  targetVCReg <- mkCReg(Invalid);

  method Action putTargetVC(VCIdx newTargetVC);
    targetVCReg[1] <= Valid(newTargetVC);
  endmethod 
  
  method Maybe#(VCIdx)  getTargetVC;
    return targetVCReg[0];
  endmethod

  method Action invalidate;
    dirnReg[2] <= Invalid;
  endmethod
endmodule
