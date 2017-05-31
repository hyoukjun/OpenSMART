/*

 This is for real synthesis, just for the area estimation.

*/

import Types::*;
import Vector::*;
import Network::*;
import Router::*;
import Fifo::*;
import Connectable::*;
import TrafficGenerator::*;

typedef 100000 SimCycles;

interface RealTestBench;
  method Action startRun;
  method ActionValue#(Data) getInjectCount;
  method ActionValue#(Data) getRecvCount;
  method ActionValue#(Data) getLatencyCount;
endinterface

(* synthesize *)
module mkRealTestBench(RealTestBench);

  /********************************* States *************************************/
  Reg#(Data) clkCount  <- mkReg(0);
  Reg#(Bool) inited    <- mkReg(False);
  Reg#(Bool) runSig    <- mkReg(False);
  Reg#(Bit#(2)) initCount <- mkReg(0);

  Vector#(MeshHeight, Vector#(MeshWidth, TrafficGenerator))  trafficGen     <- replicateM(replicateM(mkUniformRandom));
  Vector#(MeshHeight, Vector#(MeshWidth, Reg#(Data)))        send_count     <- replicateM(replicateM(mkRegU));
  Vector#(MeshHeight, Vector#(MeshWidth, Reg#(Data)))        recv_count     <- replicateM(replicateM(mkRegU));
  Vector#(MeshHeight, Vector#(MeshWidth, Reg#(Data)))        latency_count  <- replicateM(replicateM(mkRegU));

  Fifo#(1, Data) totalInjection <- mkPipelineFifo;
  Fifo#(1, Data) totalReceive   <- mkPipelineFifo;
  Fifo#(1, Data) totalLatency   <- mkPipelineFifo;

  /******************************** Submodule ************************************/
  Network meshNtk <- mkBaselineMesh;

  rule init(!inited);
    if(initCount == 0) begin
      clkCount <= 0;
      for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
        for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
          trafficGen[i][j].initialize(fromInteger(i), fromInteger(j));
          latency_count[i][j] <= 0;
          send_count[i][j] <= 0;
          recv_count[i][j] <= 0;
        end
      end
      initCount <= initCount + 1;
    end

    if(meshNtk.isInited) begin
      inited <= True;
    end 
  endrule

  rule doClkCount(inited && runSig);
    clkCount <= clkCount + 1;
  endrule

  rule finishBench(inited && clkCount == fromInteger(valueOf(SimCycles)));
    Data recv = 0;
    Data send = 0;
    Data resLatency = 0;
    for(Integer i=0; i<valueOf(MeshHeight); i=i+1)
    begin
      for(Integer j=0; j<valueOf(MeshWidth); j=j+1)
      begin
        send = send + send_count[i][j];
        recv = recv + recv_count[i][j];
        resLatency = resLatency + latency_count[i][j];
      end
    end
      
    totalInjection.enq(send);
    totalReceive.enq(recv);
    totalLatency.enq(resLatency);

    runSig <= False;
    clkCount <= 0;
  endrule


  for(Integer i=0; i<valueOf(MeshHeight); i=i+1)
  begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1)
    begin

      rule putFlits(inited && runSig && clkCount < fromInteger(valueOf(SimCycles)));
	
        let flit <- trafficGen[i][j].getTraffic;
	if(isValid(flit)) begin
          send_count[i][j] <= send_count[i][j] + 1;
          let injectingFlit = validValue(flit);
	  injectingFlit.routeInfo.injectedCycle = clkCount;
          meshNtk.ntkPorts[i][j].putFlit(injectingFlit);
        end
      endrule

    end
  end

  for(Integer i=0; i<valueOf(MeshHeight); i=i+1)
  begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1)
    begin

      rule updateRecvCount(inited && runSig && clkCount < fromInteger(valueOf(SimCycles)));
        let flit <- meshNtk.ntkPorts[i][j].getFlit;
          latency_count[i][j] <= latency_count[i][j] + clkCount - flit.routeInfo.injectedCycle;
          recv_count[i][j] <= recv_count[i][j] + 1;
      endrule

    end
  end


  method Action startRun if(inited);
    runSig <= True;
  endmethod

  method ActionValue#(Data) getInjectCount;
    totalInjection.deq;
    return totalInjection.first;
  endmethod 

  method ActionValue#(Data) getRecvCount;
    totalReceive.deq;
    return totalReceive.first;
  endmethod

  method ActionValue#(Data) getLatencyCount;
    totalLatency.deq; 
    return totalLatency.first;
  endmethod
endmodule
