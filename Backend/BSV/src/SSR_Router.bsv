import Vector::*;
import Fifo::*;

import Types::*;
import SmartTypes::*;
import RoutingTypes::*;

import SSR_Buffer::*;

interface InterManager;
  method Action putSSRs(SSRBundle ssrSignal);
  method ActionValue#(SSRBundle) getSSRs;
endinterface

interface InterRouter;
  method Action putSSR(SSR ssr);
  method ActionValue#(SSRBundle) getSSRs;  
endinterface

interface ControlPath;
  method Action setBorder;
endinterface

interface SSR_Router;
  interface Vector#(NumNormalPorts, ControlPath) controlChannel;
  interface Vector#(NumNormalPorts, InterManager) managerChannel;
  interface Vector#(NumNormalPorts, InterRouter) routerChannel;
endinterface


(* noinline *)
function SSRBundle shiftSSRs(SSRBundle sb);
  SSRBundle ret = rotateR(sb);
  ret = map(decreaseSSR, ret);
  ret[0] = 0;
  return ret;
endfunction

(* noinline *)
function SSRBundle genNewSSR_Signal(SSR newSSR);
  SSRBundle ret = replicate(0);
  ret[0] = newSSR;
  return ret;
endfunction

/*
  SSR router
  
  Input port side: inBuffers
  Output port side: outBuffers, fromRouter, isBorder
*/
(* synthesize *)
module mkSSR_Router(SSR_Router);

  Reg#(Bool) inited <- mkReg(False);

  //Virtual Buffers
  Vector#(NumNormalPorts, SSR_Buffer) inBuffers <- replicateM(mkSSR_Buffer);
  Vector#(NumNormalPorts, SSR_Buffer) outBuffers <- replicateM(mkSSR_Buffer);
  Vector#(NumNormalPorts, Fifo#(1, SSR)) fromRouter <- replicateM(mkBypassFifo);

  Vector#(NumNormalPorts, Reg#(Bool)) isBorder <- replicateM(mkReg(False));

  /***** Rules *****/

  rule rl_doInit(!inited);
    inited <= True;  

    SSRBundle emptySSRs = replicate(0);
    for(Integer prt=0; prt<valueOf(NumNormalPorts); prt=prt+1) begin
      inBuffers[prt].putSSRs(emptySSRs);
    end

  endrule

  for(DirIdx prt = 0; prt < fromInteger(valueOf(NumNormalPorts)) ; prt=prt+1)
  begin
    let inPort = prt;
//    let outPort = getReverseIdx(prt);
    rule rl_ShiftAndAttachNewSSR(inited);
      SSRBundle newSSR_Signal = newVector;

//      let outPort = (prt < 2)? (prt+2): (prt-2);
      let outPort = getDstPort(prt); 
      let incomingSSRs <- inBuffers[inPort].deqSSRs;

      if(fromRouter[outPort].notEmpty) begin
        newSSR_Signal = genNewSSR_Signal(fromRouter[outPort].first);
        fromRouter[outPort].deq;
      end
      else begin
        newSSR_Signal = shiftSSRs(incomingSSRs);
      end

      outBuffers[outPort].putSSRs(newSSR_Signal);
    endrule
  end


  for(DirIdx prt = 0; prt < fromInteger(valueOf(NumNormalPorts)) ; prt=prt+1)
  begin
    rule rl_manageBorder_Eject(inited && isBorder[prt]);
      let ssrs <- outBuffers[prt].deqSSRs;
    endrule

    rule rl_manageBorder_inject(inited && isBorder[prt]);
      SSRBundle emptySSRs = replicate(0);
      inBuffers[prt].putSSRs(emptySSRs);
    endrule
  end

  /***** Interfaces *****/
  Vector#(NumNormalPorts, ControlPath) controlChannelDummy;
  Vector#(NumNormalPorts, InterManager) managerChannelDummy;
  Vector#(NumNormalPorts, InterRouter) routerChannelDummy;

  for(Integer prt = 0; prt < valueOf(NumNormalPorts) ; prt=prt+1)
  begin
    let outPort = prt;
    let inPort = prt;

    controlChannelDummy[prt] = 
      interface ControlPath
        method Action setBorder if(!inited);
          isBorder[outPort] <= True;
        endmethod
      endinterface;

    managerChannelDummy[prt] = 
      interface InterManager
        method Action putSSRs(SSRBundle ssrSignal) if(inited && !isBorder[outPort]);
          inBuffers[inPort].putSSRs(ssrSignal);
        endmethod

        method ActionValue#(SSRBundle) getSSRs if(inited && !isBorder[outPort]);
          let ret <- outBuffers[outPort].deqSSRs;
          return ret;
        endmethod
      endinterface;


    routerChannelDummy[prt] =
      interface InterRouter
        method Action putSSR(SSR ssr) if(inited);
            fromRouter[outPort].enq(ssr);
        endmethod

        method ActionValue#(SSRBundle) getSSRs if(inited);
            let ret = inBuffers[inPort].getSSRs;
            return ret;
        endmethod
      endinterface;
  end

  interface controlChannel = controlChannelDummy;
  interface managerChannel = managerChannelDummy;
  interface routerChannel = routerChannelDummy;

endmodule

