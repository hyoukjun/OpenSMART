import Vector::*;
import Types::*;
import Fifo::*;
import VCAllocUnitTypes::*;

import CreditReg::*;
import HostTableEntry::*;

interface VCAllocUnit;
  method Bool isInited;

  method Maybe#(VCIdx)  getNextVC;
  method ActionValue#(VCBundle) vcAllocation(VCBundle vaReq);

  /* VC Status */
  method Action setActive(VCIdx vc, DirIdx dirn);
  method Action setIdle(VCIdx vc);

  /* Credit count management */
  method Action incCredit(VCIdx vc);
  method Action decCredit(VCIdx vc);
endinterface

(* synthesize *)
module mkVCAllocUnit(VCAllocUnit);
  Reg#(Bool)                       inited          <- mkReg(False);
  Reg#(VCIdx)                      initCount       <- mkReg(0);
  Vector#(NumVCs, CreditReg)       creditRegs      <- replicateM(mkCreditReg);
  Fifo#(1, VCIdx)                  nextVC          <- mkBypassFifo;
  Fifo#(1, VCIdx)                  nextVCInfo      <- mkBypassFifo;
//  Vector#(NumVCs, HostTableEntry)  hostTable       <- replicateM(mkHostTableEntry);

  Fifo#(NumVCs, VCIdx) freeVCPool <- mkBypassFifo;

  /*****************************************************************************/

  rule initialize(!inited);
    if(initCount < fromInteger(valueOf(NumVCs))) begin
      freeVCPool.enq(initCount);
      initCount <= initCount+1;
    end
    else begin
      inited <= True;
    end
  endrule

  /*****************************************************************************/
  method Bool isInited = inited;

  rule updateNextVC(inited);
    if(freeVCPool.notEmpty) begin
      nextVC.enq(freeVCPool.first);
      nextVCInfo.enq(freeVCPool.first);
    end
  endrule

  method ActionValue#(Maybe#(VCIdx)) getNextVC;  
    if(nextVCInfo.notEmpty)
    begin
      nextVCInfo.deq;    
      return Valid(nextVCInfo.first);
    end
    else begin
      return Invalid;
    end    
  endmethod

  method ActionValue#(VCBundle) vcAllocation(VCBundle vaReq) if(inited);
    VCBundle freeVCInfo = newVector;
//    Bit#(NumPorts) foundEntry = 0;
      
    for(DirIdx inPort  = 0; inPort < fromInteger(valueOf(NumPorts)); inPort = inPort+1) begin
      if(isValid(vaReq[inPort])) begin

        /* Check occupied VCs */
//        let incomingVC = validValue(vaReq[inPort]);
//        for(VCIdx vc = 0; vc < fromInteger(valueOf(NumVCs)); vc = vc+1) begin
 //         if(hostTable[vc].entryChecker[inPort].checkEntry(incomingVC, inPort)) begin
//            foundEntry[inPort] = 1;
//            freeVCInfo[inPort] = creditRegs[vc].creditCheck[inPort].hasCredit()? Valid(vc) : Invalid;
//          end
//        end //end for 

//	if(foundEntry[inPort] == 0) begin
          if(nextVC.notEmpty) begin
            nextVC.deq; 
            let newVC = nextVC.first;
            let hasCredit = creditRegs[newVC].creditCheck[inPort].hasCredit();
	    freeVCInfo[inPort] = hasCredit? Valid(freeVCPool.first) : Invalid;
          end
	  else begin
            freeVCInfo[inPort] = Invalid;
          end

//        end
      end //end if
      else begin
        if(nextVC.notEmpty) begin
          nextVC.deq;
	end	
        freeVCInfo[inPort] = Invalid;
      end      
    end //end for
           
    return freeVCInfo;
  endmethod      

  /* VCState */
  
  method Action setActive(VCIdx vc, DirIdx dirn) if(inited);
    // Called only if the flit was head. 
    // Rationale: Head flit should be from the free VC pool. Otherwise, flits should be follow their header.
    freeVCPool.deq;
//    hostTable[vc].putHostVC(vc);
//    hostTable[vc].putHostDirn(dirn);

  endmethod

  method Action setIdle(VCIdx vc) if(inited);
    freeVCPool.enq(vc);
//    hostTable[vc].invalidate();
  endmethod
  
  /* Credits */
  method Action incCredit(VCIdx vc) if(inited);
    creditRegs[vc].incCredit();
  endmethod
		
  method Action decCredit(VCIdx vc) if(inited);
    creditRegs[vc].decCredit();
  endmethod

endmodule
