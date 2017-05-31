import Types::*;
import RoutingTypes::*;
import MessageTypes::*;
import RoutingUnitTypes::*;

interface RoutingUnit;
//  method RouteInfo outportCompute(RouteInfo route);
  method RouteInfo smartOutportCompute(RouteInfo route, DirIdx outPort);
endinterface

(* noinline *)
function Direction outportComputeXY(RouteInfo route);

  let nextDirn	= ?;
  let dirX		= route.dirX;
  let numXhops	= route.numXhops;
  let dirY		= route.dirY;
  let numYhops	= route.numYhops;
	
  //Check the X direction first
  if(numXhops > 0) begin
    if(dirX == WE_) begin
      nextDirn = east_;
    end
    else begin
      nextDirn = west_;
    end
  end
  else if(numYhops > 0) begin
    if(dirY == SN_) begin
      nextDirn = north_;
    end
    else begin
      nextDirn = south_;
    end
  end
  else begin //Reached the destination
    nextDirn = local_; //Local
  end

  return nextDirn;
endfunction

(* noinline *)
function RouteInfo updateRouteInfoXY(RouteInfo route, Direction nextDirn);
  let ret = route;
  /* Num-hops */
  if(nextDirn == east_ || nextDirn == west_) begin
    ret.numXhops = route.numXhops-1;
  end
  else if(nextDirn == north_ || nextDirn == south_) begin
    ret.numYhops = route.numYhops-1;
  end
  ret.nextDir = nextDirn;
  //We don't need to update the dirX or dirY as it is XY routing(does not change).
  return ret;
endfunction

(* noinline *)
function RouteInfo smartOutportComputeFunc(RouteInfo route, DirIdx outPort);
  let newRouteInfo = route; 
  case(currentRoutingAlgorithm)
    XY_: begin
      case(outPort)
        dIdxEast, dIdxWest: begin
          newRouteInfo.numXhops = route.numXhops - 1;
          if(route.numXhops == 1) begin
            if(route.numYhops == 0) begin
              newRouteInfo.nextDir = local_;
            end
            else begin
              newRouteInfo.nextDir = (route.dirY == NS_)? south_:north_;
            end
          end
        end
        dIdxNorth, dIdxSouth: begin
          newRouteInfo.numYhops = route.numYhops - 1;
          if(route.numYhops == 1) begin
            newRouteInfo.nextDir = local_; 
          end
        end

//	  default: Local. Do nothing
      endcase
    end
/* YX routing. Not yet implemented.     
      default: begin        
      end
*/
  endcase
  return newRouteInfo;
endfunction




(* synthesize *)
module mkRoutingUnit(RoutingUnit);
/*
  method RouteInfo outportCompute(RouteInfo route);
    RouteInfo ret = ?;
    
    case(currentRoutingAlgorithm)
      XY_: begin
        let nextDir = outportComputeXY(route);
        ret = updateRouteInfoXY(route, nextDir);
      end
      default: begin //Default: XY
        let nextDir = outportComputeXY(route);
        ret = updateRouteInfoXY(route, nextDir);
      end
    endcase

    return ret;
  endmethod
*/
  method RouteInfo smartOutportCompute(RouteInfo route, DirIdx outPort);
    return smartOutportComputeFunc(route, outPort);
  endmethod

endmodule
