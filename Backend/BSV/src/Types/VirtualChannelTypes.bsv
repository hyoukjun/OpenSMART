import Vector::*;
import Types::*;

typedef TMin#(MaxVCs, NumUserVCs)     NumVCs; 
typedef Bit#(TAdd#(1, TLog#(NumVCs))) VCIdx;

typedef Bit#(NumPorts) FreeVCInfo;
typedef Vector#(NumPorts, Maybe#(VCIdx)) VCBundle;

typedef 30 MaxVCs;

typedef NumFlitsPerDataMessage    DataVCDepth;
typedef NumFlitsPerControlMessage ControlVCDepth;
typedef TAdd#(1, TMax#(DataVCDepth, ControlVCDepth)) MaxVCDepth;

typedef enum {IDLE_, ACTIVE_} VCState deriving(Bits, Eq);

//Format converting
function Maybe#(VCIdx) arbitRes2Idx(Bit#(NumVCs) res);
  let ret = case(zeroExtend(res))
              30'b000000000000000000000000000001: Valid(0);
              30'b000000000000000000000000000010: Valid(1);
              30'b000000000000000000000000000100: Valid(2);
              30'b000000000000000000000000001000: Valid(3);
              30'b000000000000000000000000010000: Valid(4);
              30'b000000000000000000000000100000: Valid(5);
              30'b000000000000000000000001000000: Valid(6);
              30'b000000000000000000000010000000: Valid(7);
              30'b000000000000000000000100000000: Valid(8);
              30'b000000000000000000001000000000: Valid(9);
              30'b000000000000000000010000000000: Valid(10);
              30'b000000000000000000100000000000: Valid(11);
              30'b000000000000000001000000000000: Valid(12);
              30'b000000000000000010000000000000: Valid(13);
              30'b000000000000000100000000000000: Valid(14);
              30'b000000000000001000000000000000: Valid(15);
              30'b000000000000010000000000000000: Valid(16);
              30'b000000000000100000000000000000: Valid(17);
              30'b000000000001000000000000000000: Valid(18);
              30'b000000000010000000000000000000: Valid(19);
              30'b000000000100000000000000000000: Valid(20);
              30'b000000001000000000000000000000: Valid(21);
              30'b000000010000000000000000000000: Valid(22);
              30'b000000100000000000000000000000: Valid(23);
              30'b000001000000000000000000000000: Valid(24);
              30'b000010000000000000000000000000: Valid(25);
              30'b000100000000000000000000000000: Valid(26);
              30'b001000000000000000000000000000: Valid(27);
              30'b010000000000000000000000000000: Valid(28);
              30'b100000000000000000000000000000: Valid(29);
              default: Invalid;
            endcase;
  return ret;
endfunction

