import Vector::*;
import Fifo::*;
import Connectable::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;
import CreditTypes::*;

import Network::*;
import TrafficGeneratorUnit::*;
import TrafficGeneratorBuffer::*;
import CreditUnit::*;
import StatLogger::*;

(* synthesize *)
module mkTestBench();

  /********************************* States *************************************/
  Reg#(Data) clkCount  <- mkReg(0);
  Reg#(Bool) inited    <- mkReg(False);
  Reg#(Data) initCount <- mkReg(0);

  
  Vector#(MeshHeight, Vector#(MeshWidth, TrafficGeneratorUnit))    trafficGeneratorUnits       <- replicateM(replicateM(mkTrafficGeneratorUnit));
  Vector#(MeshHeight, Vector#(MeshWidth, TrafficGeneratorBuffer))  trafficGeneratorBufferUnits <- replicateM(replicateM(mkTrafficGeneratorBuffer));

  Vector#(MeshHeight, Vector#(MeshWidth, ReverseCreditUnit))  creditUnits    <- replicateM(replicateM(mkReverseCreditUnit));
  Vector#(MeshHeight, Vector#(MeshWidth, StatLogger))         statLoggers    <- replicateM(replicateM(mkStatLogger));

  /******************************** Submodule ************************************/

  Network meshNtk <- mkNetwork;

  rule init(!inited);
    if(initCount == 0) begin
      clkCount <= 0;
      for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
        for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
          trafficGeneratorUnits[i][j].initialize(fromInteger(i), fromInteger(j));
        end
      end
    end

    initCount <= initCount + 1;
    if(meshNtk.isInited && initCount > fromInteger(valueOf(MeshHeight)) + fromInteger(valueOf(MeshWidth)))  begin
      inited <= True;
    end 
  endrule

  rule doClkCount(inited && clkCount < fromInteger(valueOf(BenchmarkCycle)));
    if(clkCount % 10000 == 0) begin
      $display("Elapsed Simulation Cycles: %d",clkCount);
    end
    clkCount <= clkCount + 1;
  endrule

  rule finishBench(inited && clkCount == fromInteger(valueOf(BenchmarkCycle)));
      Data res = 0;
      Data send = 0;
      Data hop = 0;
      Data remainingFlits = 0;
      Data inflight = 0;
      Bit#(64) resLatency = 0;

      for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
        for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
          Data sendCount = statLoggers[i][j].getSendCount;
          Data recvCount = statLoggers[i][j].getRecvCount;
          Data latencyCount = statLoggers[i][j].getLatencyCount;
          Data remFlits = trafficGeneratorBufferUnits[i][j].getRemainingFlitsNumber;
//          Data extraLatency = trafficGeneratorBufferUnits[i][j].getExtraLatency(clkCount);
          Data hopCount = statLoggers[i][j].getHopCount;
          Data inflightCycle = statLoggers[i][j].getInflightLatencyCount;

          $display("send_count[%d][%d] = %d, recv_count[%d][%d] = %d", i, j, sendCount, i, j, recvCount);

          send = send + sendCount;
          res = res + recvCount;
          resLatency = resLatency + zeroExtend(latencyCount);// + zeroExtend(extraLatency);
          remainingFlits = remainingFlits + remFlits;
          hop = hop + hopCount;
          inflight = inflight + inflightCycle;

	    end
      end
      
      $display("Elapsed clock cycles: %d", clkCount);
      $display("Total injected packet: %d",send);
      $display("Total received packet: %d",res);
      $display("Total latency: %ld", resLatency);
      $display("Total hopCount: %d", hop);
      $display("Total inflight latency: %ld", inflight);
      $display("Number of remaiing Flits in traffic generator side: %d", remainingFlits);
      $finish;
  endrule


  //Credit Links
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin

      mkConnection(creditUnits[i][j].getCredit,
                     meshNtk.ntkPorts[i][j].putCredit);

      mkConnection(meshNtk.ntkPorts[i][j].getCredit,
                     trafficGeneratorUnits[i][j].putVC);
    end
  end


  //Data Links
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin

      rule genFlits(inited);
        trafficGeneratorUnits[i][j].genFlit(clkCount);
      endrule

      rule prepareFlits(inited);
        let flit <- trafficGeneratorUnits[i][j].getFlit;
        trafficGeneratorBufferUnits[i][j].putFlit(flit);//, clkCount);
      endrule

      rule putFlits(inited);
        let flit <- trafficGeneratorBufferUnits[i][j].getFlit;
        flit.stat.inflightCycle = clkCount;
        meshNtk.ntkPorts[i][j].putFlit(flit);
        statLoggers[i][j].incSendCount;
      endrule

      rule getFlits(inited);
        let flit <- meshNtk.ntkPorts[i][j].getFlit;
        Data hopCount = flit.stat.hopCount;

/*        
        if((flit.stat.dstX != fromInteger(j)) || (flit.stat.dstY != fromInteger(i))) begin
            $display("Warning: Missrouted.\n Received from(%d, %d) but the destination is (%d, %d) source: (%d, %d)", fromInteger(i), fromInteger(j), flit.stat.dstY, flit.stat.dstX, flit.stat.srcY, flit.stat.srcX);
        end
        
        else begin
            $display("Correct\n Received from(%d, %d). The destination is (%d, %d)  source: (%d, %d)", fromInteger(i), fromInteger(j), flit.stat.dstY, flit.stat.dstX, flit.stat.srcY, flit.stat.srcX);
        end
*/      
        statLoggers[i][j].incLatencyCount(clkCount - flit.stat.injectedCycle);
        statLoggers[i][j].incInflightLatencyCount(clkCount - flit.stat.inflightCycle);
        statLoggers[i][j].incRecvCount;
        statLoggers[i][j].incHopCount(hopCount);
        creditUnits[i][j].putCredit(Valid(CreditSignal_{vc: flit.vc, isTailFlit: True}));
      endrule

    end
  end

endmodule
