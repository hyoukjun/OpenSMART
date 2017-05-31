import Vector::*;

import Types::*;
import VirtualChannelTypes::*;

import MatrixArbiter::*;

(* synthesize *)
module mkOutPortArbiter(NtkArbiter#(NumPorts));
  Integer n = valueOf(NumPorts);
  NtkArbiter#(NumPorts)	matrixArbiter <- mkMatrixArbiter(n);
  return matrixArbiter;
endmodule

(* synthesize *)
module mkInputVCArbiter(NtkArbiter#(NumVCs));
  Integer n = valueOf(NumVCs);
  NtkArbiter#(NumVCs) matrixArbiter <- mkMatrixArbiter(n);
  return matrixArbiter;
endmodule
