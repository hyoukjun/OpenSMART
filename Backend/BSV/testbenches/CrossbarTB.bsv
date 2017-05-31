import Vector::*;
import Fifo::*;
import CReg::*;

import Types::*;
import MessageTypes::*;
import SwitchAllocTypes::*;
import RoutingTypes::*;

import CrossbarSwitch::*;
import CrossbarBuffer::*;

typedef 100 TestCount;

(* synthesize *)
module mkCrossbarTestBench();
  Reg#(Data) count <- mkReg(0);
  CrossbarSwitch cb <- mkCrossbarSwitch;

  rule doCount;
    if(count < fromInteger(valueOf(TestCount))) begin
      count <= count + 1;
    end
    else begin
      $finish;
    end
  endrule

  rule rl_insertFlits(count < fromInteger(valueOf(TestCount)));
    Flit flit = ?;
//    $display("[Count:%d] inserted flits", count);

    if(count == 10) begin
      cb.crossbarPorts[0].putFlit(flit, 1); //N->E
      cb.crossbarPorts[1].putFlit(flit, 0); //E->N
      cb.crossbarPorts[2].putFlit(flit, 4); //S->L
      cb.crossbarPorts[3].putFlit(flit, 2); //W->S
      cb.crossbarPorts[4].putFlit(flit, 3); //L->W
    end
    else if(count == 11) begin
      cb.crossbarPorts[0].putFlit(flit, 4); //N->L
      cb.crossbarPorts[4].putFlit(flit, 1); //L->E
    end
    else if(count == 12) begin
      cb.crossbarPorts[0].putFlit(flit, 2); //N->S
      cb.crossbarPorts[1].putFlit(flit, 3); //E->W
      cb.crossbarPorts[2].putFlit(flit, 4); //S->L
      cb.crossbarPorts[3].putFlit(flit, 0); //W->N
      cb.crossbarPorts[4].putFlit(flit, 1); //L->E
    end

  endrule

  for(DirIdx i = 0; i<5; i=i+1) begin
    rule rl_getFlits(count < fromInteger(valueOf(TestCount)));
      let flit <- cb.crossbarPorts[i].getFlit;
      $display("[Count:%d] got a flit from %d", count, i);
    endrule
  end

endmodule
