import Vector::*;
import Types::*;
import RoutingTypes::*;

typedef Vector#(NumPorts, Direction) DirectionBitBundle;
typedef DirectionBitBundle           SAReqBits;

typedef DirectionBitBundle SAReq;
typedef Bit#(NumPorts)     SARes;

function DirIdx arbitRes2DirIdx(Bit#(NumPorts) arbitRes);
  
  let ret = case(arbitRes)
              5'b00001: dIdxNorth;
              5'b00010: dIdxEast;
              5'b00100: dIdxSouth;
              5'b01000: dIdxWest;
              5'b10000: dIdxLocal;
              default: dIdxNULL;
            endcase;
  return ret;
  
 /*
  let ret = case(arbitRes)
              1: dIdxNorth;
              2: dIdxEast;
              4: dIdxSouth;
              8: dIdxWest;
              16: dIdxLocal;
              default: dIdxNULL;
            endcase;
  return ret;
*/


endfunction
