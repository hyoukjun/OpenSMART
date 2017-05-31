import Vector::*;
import FShow::*;
import Types::*;

function Fmt showDirection(Direction dirn);
  Fmt retv = fshow("");
  case(dirn)
    north_: retv = fshow("North");
    east_: retv = fshow("East");
    south_: retv = fshow("South");
    west_: retv = fshow("West");
    local_: retv = fshow("Local");
    default: retv= fshow("Unknown direction");
  endcase
  return retv;
endfunction

function Fmt showDirectionB(DirIdx dirn);
  Fmt retv = fshow("");
  case(dirn)
    dIdxNorth: retv = fshow("North");
    dIdxEast: retv = fshow("East");
    dIdxSouth: retv = fshow("South");
    dIdxWest: retv = fshow("West");
    dIdxLocal: retv = fshow("Local");
    default: retv= fshow("Unknown direction");
  endcase
  return retv;
endfunction


function Fmt showDirectionI(Integer dirn);
  Fmt retv = fshow("");
  case(dirn)
    0: retv = fshow("North");
    1: retv = fshow("East");
    2: retv = fshow("South");
    3: retv = fshow("West");
    4: retv = fshow("Local");
    default: retv= fshow("Unknown direction");
  endcase
  return retv;
endfunction

