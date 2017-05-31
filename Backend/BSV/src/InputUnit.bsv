import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;

import NtkArbiter::*;

interface InputUnit;
  method Bool           isInited;

  /* Flit */
  method Action         putFlit(Flit flit);
  method Maybe#(Flit)   peekFlit;
  method Action         deqFlit;

  /* Header Information */
  method Maybe#(Header) peekHeader;
endinterface

(* synthesize *)
module mkInputUnit(InputUnit);
  /********************************* States *************************************/
  Reg#(Bool)              inited <- mkReg(False);
  CReg#(4, Maybe#(VCIdx)) nextVC <- mkCReg(Invalid);

  /******************************* Submodules ***********************************/

  CReg#(3, Maybe#(Flit))                         arrivingFlit <- mkCReg(Invalid);

  Vector#(NumVCs, CReg#(3, Data)) numFlits <- replicateM(mkCReg(0));

  Vector#(NumVCs, Fifo#(MaxVCDepth, Flit))   vcs       <- replicateM(mkBypassFifo);
  Vector#(NumVCs, Fifo#(1, Header))          headers   <- replicateM(mkBypassFifo);
  NtkArbiter#(NumVCs)                        vcArbiter <- mkInputVCArbiter;  //Arbiter
  
  /******************************* Functions ***********************************/
  function Bit#(NumVCs) getArbitReqBits;
  //Generate an arbitration request bit by investigating the VC queues
    Bit#(NumVCs) reqBit = 0;
  
    for(VCIdx vc=0; vc<fromInteger(valueOf(NumVCs)); vc=vc+1)
    begin
      reqBit[vc] = (numFlits[vc][2] == 0)? 0:1;
    end

    if(isValid(arrivingFlit[2])) begin
      let newFlit = validValue(arrivingFlit[2]);
      reqBit[newFlit.vc] = 1;
    end

    return reqBit;
  endfunction

  function ActionValue#(Maybe#(VCIdx)) getNextVC;
  actionvalue
    let reqBit = getArbitReqBits();
    let arbitRes <- vcArbiter.getArbit(reqBit);

    let winnerIdx = arbitRes2Idx(arbitRes);  //winner index is Invalid if there is no winner.

    return winnerIdx;
  endactionvalue
  endfunction


  function Action doArbit;
  action
    let reqBit = getArbitReqBits();
    let arbitRes <- vcArbiter.getArbit(reqBit);
`ifdef DEBUG    
    if(reqBit != 0) 
      $display("Arbit Request: %b, res: %b",reqBit,arbitRes);
`endif

    let winnerIdx = arbitRes2Idx(arbitRes);  //winner index is Invalid if there is no winner.
    nextVC[3] <= winnerIdx;
  endaction
  endfunction


  /**************************** InputUnit Behavior *****************************/
  rule doInitialize(!inited);
    inited <= True;
    vcArbiter.initialize;
  endrule

  rule rl_loadFlit(inited && isValid(arrivingFlit[0]));
    /*
    let flit = arrivingFlit.first;
    arrivingFlit.deq;
    */

    let flit = validValue(arrivingFlit[0]);
    let vc = flit.vc;
    vcs[vc].enq(flit);

    if(isHead(flit)) begin
      headers[vc].enq(Header{vc: vc, routeInfo: flit.routeInfo});
    end
    arrivingFlit[0] <= Invalid;
  endrule

  rule rl_doArbit(inited);// && !isValid(nextVC[2]));
    doArbit;
  endrule

  /******************************* Interfaces **********************************/
  method Bool isInited = inited;
 
  method Maybe#(Header) peekHeader if(inited);
    if(isValid(nextVC[1])) begin
      let vc = validValue(nextVC[1]);
      return Valid(headers[vc].first);
    end
    else begin
        return Invalid;
    end
  endmethod

  method Action putFlit(Flit flit) if(inited);
    numFlits[flit.vc][0] <= numFlits[flit.vc][0] + 1;
    arrivingFlit[1] <= Valid(flit);
//    arrivingFlit.enq(flit);
  endmethod

  method Maybe#(Flit) peekFlit if(inited);
    if(isValid(nextVC[1])) begin
      let vc = validValue(nextVC[1]);
      let topFlit = vcs[vc].first;
      return Valid(topFlit);
    end
    else begin
        return Invalid;
    end
  endmethod

  method Action deqFlit if(inited && isValid(nextVC[1]));
      if(isValid(nextVC[1])) begin
        let vc = validValue(nextVC[1]);
        vcs[vc].deq;
        numFlits[vc][1] <= numFlits[vc][1]-1;
        if(isTail(vcs[vc].first)) begin
          headers[vc].deq;
      //  if(isValid(nextVC[2]) && (validValue(nextVC[2]) == vc))
//          nextVC[2] <= Invalid; //multi-flit
        end
      end
  endmethod
endmodule
