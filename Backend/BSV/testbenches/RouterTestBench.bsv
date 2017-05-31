import Types::*;
import Vector::*;
import Router::*;
import Fifo::*;
import Router::*;

/*
  Just for Area/Power estimation of a single router
*/

interface RouterTestBench;
  method Action startRun;
  method Bool isFinished;
  method ActionValue#(Data) getFLitCount;
endinterface

module mkRouterTestBench(RouterTestBench);
  Router router <- mkRouter;
  Reg#(Bool) started <- mkReg(False);
  Reg#(Data) clkCount <- mkReg(0);
  Reg#(Data) flitCount <- mkReg(0);

 
  rule doCount(started);
    if(clkCount == 100000) begin
      started <= False;
      clkCount <= 0;
    end
    else begin
      clkCount <= clkCount +1;
    end

  endrule

  for(Integer i=0;i<valueOf(NumPorts); i=i+1) begin
    rule insertFlits(started);
      Flit flit = ?;
      flit.vc = 0;
      flit.routeInfo.nextDir = case(i)
                                 0: east_;
				 1: south_;
				 2: west_;
				 3: local_;
				 4: north_;
			       endcase;
      router.routerLinks[i].putFlit(flit);
    endrule

    rule getFlits(started);
      let flit <- router.routerLinks[i].getFlit;
      flitCount <= flitCount + 1;
    endrule

    rule putCredits(started);
      router.routerLinks[i].putCredit(CreditSignal{vc:0, isTailFlit: True});
    endrule

  end



  method ActionValue#(Data) getFLitCount;
    return flitCount;
  endmethod

  method Action startRun;
    started <= True;
  endmethod

  method Bool isFinished = !started;

endmodule
