import Vector::*;
import Fifo::*;
import Randomizable::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;

interface TrafficGenerator;
  method Action initialize(MeshHIdx yID, MeshWIdx xID);
  method ActionValue#(Flit) getFlit;
endinterface

(* synthesize *)
module mkUniformRandom(TrafficGenerator);

  Randomize#(MeshHIdx) hIdRand	<- mkConstrainedRandomizer(0, fromInteger(valueOf(MeshHeight)-1));
  Randomize#(MeshWIdx) wIdRand	<- mkConstrainedRandomizer(0, fromInteger(valueOf(MeshWidth)-1));
  Randomize#(Data)     injRand  <- mkConstrainedRandomizer(0, 99); 
  
  Fifo#(1, Flit) outFlit <- mkBypassFifo;

  Reg#(Bool)     startInit            <- mkReg(False);
  Reg#(Bool)     inited	              <- mkReg(False);
  Reg#(Data)     initReg              <- mkReg(0);
  Reg#(MeshWIdx) wID                  <- mkRegU;
  Reg#(MeshHIdx) hID                  <- mkRegU;

  rule doInitialize(!inited && startInit);
    if(initReg == 0) begin
      hIdRand.cntrl.init;
      wIdRand.cntrl.init;
      injRand.cntrl.init;
    end
    else if(initReg < zeroExtend(wID) + zeroExtend(hID)) begin
      let injRnd <- injRand.next;
      let wRnd <- wIdRand.next;
      let hRnd <- hIdRand.next;
    end
    else begin
      inited <= True;
    end
    initReg <= initReg + 1;
  endrule

  rule genFlit(inited);
    let injVar <- injRand.next;
    //InjectionRate = {XX| injRate = 0.XX}
    if(injVar < fromInteger(valueOf(InjectionRate))) 
    begin
      Flit flit = ?;
		
      flit.vc = 0;

      let wDest <- wIdRand.next;
      DirIdx xDir = (wDest>wID)? dIdxEast:dIdxWest;
      MeshWIdx xHops = (wDest > wID)? (wDest-wID) : (wID-wDest);

      let hDest <- hIdRand.next;
      DirIdx yDir = (hDest>hID)? dIdxSouth:dIdxNorth;
      MeshHIdx yHops = (hDest > hID)? (hDest-hID) : (hID-hDest);
    
      //Look-ahead routing
      //It is modified for SMART
//        flit.routeInfo.numXhops = (wDest > wID)? (wDest-wID)-1 : (wID-wDest)-1;
      flit.routeInfo.dirX = (wDest > wID)? WE_ : EW_;
      flit.routeInfo.numXhops = xHops;

      //Y-axis direction
//      let hDest <- hIdRand.next;

      //It is modified for SMART
//      flit.routeInfo.numYhops = (hDest>hID)? (hDest-hID)-1: (hID-hDest)-1;
      flit.routeInfo.dirY = (hDest > hID)? NS_ : SN_;
      flit.routeInfo.numYhops = yHops;

      //Decides initial direction
      if(wDest != wID) begin// Initial direction: X 
        flit.routeInfo.nextDir = (wDest > wID)? east_ : west_;
      end
      else if(hDest !=hID) begin //Initial direction: Y
        flit.routeInfo.nextDir = (hDest > hID)? south_:north_;
      end
      else begin
        flit.routeInfo.nextDir = local_;
	  end

      flit.flitType = HeadTail; 
      flit.stat.hopCount = 0;
      flit.stat.dstX = wDest;
      flit.stat.dstY = hDest;
      flit.stat.srcX = wID;
      flit.stat.srcY = hID;

      if(flit.routeInfo.nextDir != local_) begin
        outFlit.enq(flit);
      end
    end// Injection rate if ends
  endrule


  method Action initialize(MeshHIdx yID, MeshWIdx xID) if(!inited && !startInit);
    startInit <= True;
    hID <= yID;
    wID <= xID;
  endmethod

  method ActionValue#(Flit)	getFlit if(inited);
    outFlit.deq;
    return outFlit.first;
  endmethod
endmodule



module mkBitComplement(TrafficGenerator);
  
  Randomize#(Data)     injRand  <- mkConstrainedRandomizer(0, 99); 
  
  Fifo#(1, Flit) outFlit <- mkBypassFifo;

  Reg#(Bool)     startInit            <- mkReg(False);
  Reg#(Bool)     inited	              <- mkReg(False);
  Reg#(Data)     initReg              <- mkReg(0);
  Reg#(MeshWIdx) wID                  <- mkRegU;
  Reg#(MeshHIdx) hID                  <- mkRegU;

  rule doInitialize(!inited && startInit);
    if(initReg == 0) begin
      injRand.cntrl.init;
    end
    else if(initReg < zeroExtend(wID) + zeroExtend(hID)) begin
      let injRnd <- injRand.next;
    end
    else begin
      inited <= True;
    end
    initReg <= initReg + 1;
  endrule

  rule genFlit(inited);
    let injVar <- injRand.next;
    //InjectionRate = {XX| injRate = 0.XX}
    if(injVar < fromInteger(valueOf(InjectionRate))) 
    begin
      Flit flit = ?;
		
      flit.vc = 0;

      let wDest = fromInteger(valueOf(MeshWidth)) - 1 - wID;
      let hDest = fromInteger(valueOf(MeshHeight)) - 1 - hID;

      DirIdx xDir = (wDest>wID)? dIdxEast:dIdxWest;
      MeshWIdx xHops = (wDest > wID)? (wDest-wID) : (wID-wDest);

      DirIdx yDir = (hDest>hID)? dIdxSouth:dIdxNorth;
      MeshHIdx yHops = (hDest > hID)? (hDest-hID) : (hID-hDest);
    
      //Look-ahead routing
//        flit.routeInfo.numXhops = (wDest > wID)? (wDest-wID)-1 : (wID-wDest)-1;
      flit.routeInfo.dirX = (wDest > wID)? WE_ : EW_;
      flit.routeInfo.numXhops = xHops;

      //Y-axis direction
//      let hDest <- hIdRand.next;

//      flit.routeInfo.numYhops = (hDest>hID)? (hDest-hID)-1: (hID-hDest)-1;
      flit.routeInfo.dirY = (hDest > hID)? NS_ : SN_;
      flit.routeInfo.numYhops = yHops;

      //Decides initial direction
      if(wDest != wID) begin// Initial direction: X 
        flit.routeInfo.nextDir = (wDest > wID)? east_ : west_;
      end
      else if(hDest !=hID) begin //Initial direction: Y
        flit.routeInfo.nextDir = (hDest > hID)? south_:north_;
      end
      else begin
        flit.routeInfo.nextDir = local_;
	  end

      flit.flitType = HeadTail; 
      flit.stat.hopCount = 0;
      flit.stat.dstX = wDest;
      flit.stat.dstY = hDest;
      flit.stat.srcX = wID;
      flit.stat.srcY = hID;

//      $display("TrafficGenerator: from(%d, %d) send to (%d, %d).\n  Initial direction: %d\n  NumXhops = %d, NumYhops = %d",hID, wID, hDest, wDest, dir2Idx(flit.routeInfo.nextDir), xHops, yHops);

      if(flit.routeInfo.nextDir != local_) begin
        outFlit.enq(flit);
      end
    end// Injection rate if ends
  endrule


  method Action initialize(MeshHIdx yID, MeshWIdx xID) if(!inited && !startInit);
    startInit <= True;
    hID <= yID;
    wID <= xID;
  endmethod

  method ActionValue#(Flit)	getFlit if(inited);
    outFlit.deq;
    return outFlit.first;
  endmethod
endmodule


