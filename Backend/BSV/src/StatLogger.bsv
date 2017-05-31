import Vector::*;
import Fifo::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;
import CreditTypes::*;

interface StatLogger;
  method Action incSendCount;
  method Action incRecvCount;
  method Action incLatencyCount(Data latency);
  method Action incHopCount(Data hopCount);
  method Action incInflightLatencyCount(Data latency);

  method Data getSendCount;
  method Data getRecvCount;
  method Data getLatencyCount;
  method Data getHopCount;
  method Data getInflightLatencyCount;
endinterface

(* synthesize *)
module mkStatLogger(StatLogger);

  Reg#(Data) send_count             <- mkReg(0);
  Reg#(Data) recv_count             <- mkReg(0);
  Reg#(Data) latency_count          <- mkReg(0);
  Reg#(Data) hop_count              <- mkReg(0);
  Reg#(Data) inflight_latency_count <- mkReg(0);


  method Action incSendCount;
    send_count <= send_count + 1;
  endmethod

  method Action incRecvCount;
    recv_count <= recv_count + 1;
  endmethod

  method Action incLatencyCount(Data latency); 
    latency_count <= latency_count + latency;
  endmethod

  method Action incHopCount(Data hopCount);
    hop_count <= hop_count + hopCount;
  endmethod

  method Action incInflightLatencyCount(Data latency); 
    inflight_latency_count <= inflight_latency_count + latency;
  endmethod


  method Data getSendCount = send_count;
  method Data getRecvCount = recv_count;
  method Data getLatencyCount = latency_count;
  method Data getHopCount = hop_count;
  method Data getInflightLatencyCount = inflight_latency_count;

endmodule
