import Vector::*;
import Fifo::*;

import Types::*;
import SmartTypes::*;

interface ManagerAndManager;
  method Action putSSRs(SSRBundle ssrSignal);
  method ActionValue#(SSRBundle) getSSRs;
endinterface

interface ManagerAndRouter;
  method Action putSSR(SSR ssr);
  method ActionValue#(SSRBundle) getSSRs;  
endinterface

interface SSR_Manager;
  interface Vector#(2, ManagerAndManager) managerChannel;
  interface Vector#(2, ManagerAndRouter)  routerChannel;
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


(* synthesize *)
module mkSSR_Manager(SSR_Manager);

  //Fake buffers
  Vector#(2, Fifo#(1, SSRBundle)) incomingSSRs <- replicateM(mkBypassFifo);
  Vector#(2, Fifo#(1, SSR))       newSSRs      <- replicateM(mkBypassFifo);
  Vector#(2, Fifo#(1, SSRBundle)) outgoingSSRs <- replicateM(mkBypassFifo);

  Reg#(Bool) inited <- mkReg(False);


  rule rl_init(!inited);
    inited <= True;
    for(Integer dir=0; dir<2; dir=dir+1) begin
      SSRBundle emptySSRs = replicate(0);
      incomingSSRs[dir].enq(emptySSRs);
    end
  endrule


  for(Integer dir=0; dir<2; dir=dir+1) begin
    rule rl_shiftSSRs(inited);
      SSRBundle newSSR_Signal = newVector;

      if(newSSRs[dir].notEmpty) begin
        newSSR_Signal = genNewSSR_Signal(newSSRs[dir].first);
        newSSRs[dir].deq;
      end
      else begin
        newSSR_Signal = shiftSSRs(incomingSSRs[dir].first);
      end

      incomingSSRs[dir].deq;
      outgoingSSRs[dir].enq(newSSR_Signal);

    endrule
  end


  /* Interface between the SSR Manager and the router */
  Vector#(2, ManagerAndRouter) routerChannelDummy;
  for(Integer dir = 0; dir < 2; dir = dir+1)
  begin
    routerChannelDummy[dir] = 
      interface ManagerAndRouter
        method Action putSSR(SSR ssr) if(inited);
          newSSRs[dir].enq(ssr);
        endmethod 
     
        method ActionValue#(SSRBundle) getSSRs if(inited);
          return incomingSSRs[dir].first;
        endmethod     
      endinterface;
  end

  Vector#(2, ManagerAndManager) managerChannelDummy;
  for(Integer dir=0; dir<2; dir=dir+1)
  begin
    managerChannelDummy[dir] = 
      interface ManagerAndManager

        method Action putSSRs(SSRBundle ssrSignal) if(inited);
          incomingSSRs[dir].enq(ssrSignal);
	endmethod

        method ActionValue#(SSRBundle) getSSRs if(inited);
          outgoingSSRs[dir].deq;
          return outgoingSSRs[dir].first;
        endmethod

      endinterface;
  end

  interface routerChannel = routerChannelDummy;
  interface managerChannel = managerChannelDummy;

endmodule
