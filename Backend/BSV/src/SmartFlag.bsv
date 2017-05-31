import Fifo::*;

import Types::*;
import SmartTypes::*;

interface SmartFlagUnit;
  method Bool               isStop;
  method Bool               isPass;
  method Action             deqFlag;
  method Action             setFlag(SmartFlag newFlag);
endinterface

(* synthesize *)
module mkSmartFlagUnit(SmartFlagUnit);

  Fifo#(1, SmartFlag) nextFlag <- mkPipelineFifo;
  Reg#(Bool) inited <- mkReg(False);

  rule doInit(!inited);
    nextFlag.enq(Stop);
      inited <= True;
  endrule

  method Bool isStop = (nextFlag.first == Stop);
  method Bool isPass = (nextFlag.first == Pass);  

  method Action deqFlag;
    nextFlag.deq;
  endmethod

  method Action setFlag(SmartFlag newFlag) if(inited);
    nextFlag.enq(newFlag);
  endmethod

endmodule
