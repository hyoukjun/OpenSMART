import Types::*;
import	Vector::*;
import	Fifo::*;

module mkMatrixArbiter#(Integer numReq)(NtkArbiter#(num));

  Reg#(Bool) inited <- mkReg(False);
  Vector#(num, Vector#(num, Reg#(Bit#(1)))) priorityBits <- replicateM(replicateM(mkReg(1)));

  function Action updatePriorityBits(Integer target);
  action
  /* 1. Clear the row */
  for(Integer j=0; j<numReq; j=j+1) begin
    priorityBits[target][j] <= 0;
  end

  /* 2. Set the column */
  for(Integer i=0; i<numReq; i=i+1) begin
    if(i != target) begin
      priorityBits[i][target] <= 1;
    end
  end
  endaction
  endfunction

  function ActionValue#(Bool) getPermitSignal(Bit#(numReq) reqVec, Integer idx);
  actionvalue
  Bit#(numReq)	priTest = ?;
  Bit#(numReq)	priBits = ?;

  for(Integer i=0; i<numReq; i=i+1)
  begin
    priBits[i] = (i>idx)? ~priorityBits[idx][i] : priorityBits[i][idx];
  end

  priTest = priBits & reqVec;

  return (priTest == 0);
  endactionvalue
  endfunction

  function ActionValue#(Integer) getGrantIdx(Bit#(num) reqVec);
  actionvalue		
  Integer ret = ?;

  for(Integer i=0; i<numReq; i=i+1)
  begin
    let isGoodToGo <- getPermitSignal(reqVec, i);
    if((reqVec[i] == 1) && isGoodToGo) begin
      ret = i;
    end
  end

  return ret;
  endactionvalue
  endfunction

  function Bit#(num)	packGrantIdx(Integer idx);
    Bit#(num) ret = 0;
    ret[idx] = 1;
    return ret;
  endfunction
	
  function Action	initialize_func();
  action
    for(Integer i=0; i<numReq; i=i+1) begin
      priorityBits[i][i] <= 0;
    end
    inited <= True;
  endaction
  endfunction

  function ActionValue#(Bit#(num)) doArbit(Bit#(num) reqBit);
  actionvalue
    if(reqBit == 0) begin
      return 0;
    end
    else begin
      //Process the arbitration request
      let idx <- getGrantIdx(reqBit);
      updatePriorityBits(idx);
      let ret = packGrantIdx(idx);
      return ret;
    end
  endactionvalue
  endfunction

  method ActionValue#(Bit#(num)) getArbit(Bit#(num) reqBit);
    let ret <- doArbit(reqBit);
    return ret;
  endmethod

  method Action initialize if(!inited);
    initialize_func();
  endmethod

endmodule
