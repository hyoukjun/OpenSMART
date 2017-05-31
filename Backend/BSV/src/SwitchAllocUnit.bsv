import Vector::*;
import Fifo::*;

import Types::*;
import VirtualChannelTypes::*; 

import SwitchAllocTypes::*;
import NtkArbiter::*;

interface SwitchAllocUnit;
  method Bool isInited;
  method Action reqSA(SAReq req, FreeVCInfo freeVCInfo);
  method ActionValue#(SARes) getGrantedInPorts;
`ifdef SMART
  method ActionValue#(SARes) getGrantedOutPorts;
`endif
endinterface


// Arbiter gives the result in type Direction (Bit#(NumPorts))
// It represents the winner index in input sides.
// Ex) If a flit from north input port won the output switch toward east
//                                                     LWSEN
//       => When (outPort = dIdxEast), partialRes = 5'b00001

// By OR-ing every partial result, we get the bit representation of winners.
// Ex) If flits from N, S, W port won the switch
//                  LWSEN
//    => saRes = 5'b01101



(* synthesize *)
module mkSwitchAllocUnit(SwitchAllocUnit);

  /********************************* States *************************************/

  Reg#(Bool)                            inited             <- mkReg(False);
  Fifo#(1, SAReq)                       saReqBuf           <- mkBypassFifo;
  Fifo#(1, FreeVCInfo)                  freeVCInfoBuf      <- mkBypassFifo;
  Fifo#(1, SARes)                       grantedInPortsBuf  <- mkBypassFifo;
`ifdef SMART
  Fifo#(1, SARes)                       grantedOutPortsBuf <- mkBypassFifo;
`endif

  /******************************* Submodules ***********************************/
  Vector#(NumPorts, NtkArbiter#(NumPorts)) outPortArbiter  <- replicateM(mkOutPortArbiter);

  /******************************* Functions ***********************************/
  function SAReqBits genArbitReqBits(SAReq saReq, FreeVCInfo freeVCInfo);
  //Arbitration request bits are the transpose of SA request bits
  //If there is no avaialble VC, blocks the request
  //  => This increases the critical path, but it saves cycles 
  //     as it prevents failures due to VC availability after SA
	  
    SAReqBits saReqBits = newVector;

    for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort + 1) begin
      for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort + 1) begin
        saReqBits[outPort][inPort] = (freeVCInfo[outPort]==1)? saReq[inPort][outPort] : 0;
      end
    end
    
    return saReqBits;
  endfunction

  /************************* Initialization Behavior ***************************/
  rule doInitialize(!inited);
    inited <= True;

    for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort+1) begin
      outPortArbiter[outPort].initialize;
    end
  endrule


  rule doSA(inited && saReqBuf.notEmpty);
    SAReq req = saReqBuf.first;
    saReqBuf.deq;

    FreeVCInfo freeVCInfo = freeVCInfoBuf.first;
    freeVCInfoBuf.deq;

    SARes grantedInPorts = 0; 
    SARes grantedOutPorts = 0;

    let saReqBits = genArbitReqBits(req, freeVCInfo);

    for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort +1) begin
      let partialRes <- outPortArbiter[outPort].getArbit(saReqBits[outPort]);
      grantedInPorts = grantedInPorts | partialRes;
      grantedOutPorts[outPort] = (partialRes!=0)? 1:0;
    end
 
    grantedInPortsBuf.enq(grantedInPorts);
`ifdef SMART
    grantedOutPortsBuf.enq(grantedOutPorts);
`endif
  endrule

  /******************************* Interface ***********************************/

  method Bool isInited = inited;

  method Action reqSA(SAReq req, FreeVCInfo freeVCInfo);
    saReqBuf.enq(req);
    freeVCInfoBuf.enq(freeVCInfo);    
  endmethod

  method ActionValue#(SARes) getGrantedInPorts;
    grantedInPortsBuf.deq;
    return grantedInPortsBuf.first;
  endmethod
`ifdef SMART
  method ActionValue#(SARes) getGrantedOutPorts;
    grantedOutPortsBuf.deq;
    return grantedOutPortsBuf.first;
  endmethod
`endif
endmodule
