import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import RoutingTypes::*;
import VirtualChannelTypes::*;
import VCAllocUnitTypes::*;

import VCTableEntry::*;


interface VCTablePort;
  method Maybe#(VCIdx) getVC(VCIdx hostVC);
  method Action        putVC(VCIdx hostVC, VCIdx newTargetVC);
  method Action        invalidate(VCIdx hostVC);
endinterface

interface VCTable;
  interface Vector#(NumPorts, VCTablePort) vcTablePorts; 
endinterface

/*
  VCTable
  This module supports the multi-flit packets. It stores allocated VC for a specific packet.
  Allocated VC information is for the body and tail flits. The information in invalidated 
  when the tail flit of an entry leaves. Then, the entry is ready for another packet.

*/

module mkVCTable(VCTable);

  Vector#(NumPorts, Vector#(NumVCs, VCTableEntry)) vcTable <- replicateM(replicateM(mkVCTableEntry));

  Vector#(NumPorts, VCTablePort) vcTablePortsDummy;
  for(Integer prt = 0; prt < valueOf(NumPorts); prt=prt+1)
  begin
    vcTablePortsDummy[prt] =
      interface VCTablePort
        method Maybe#(VCIdx) getVC(VCIdx hostVC);
          return vcTable[prt][hostVC].getTargetVC;
        endmethod

        method Action putVC(VCIdx hostVC, VCIdx newTargetVC);
          vcTable[prt][hostVC].putTargetVC(newTargetVC);
        endmethod
	
        method Action invalidate(VCIdx hostVC);
          vcTable[prt][hostVC].invalidate;
        endmethod
      endinterface;
  end

  interface vcTablePorts = vcTablePortsDummy;

endmodule
