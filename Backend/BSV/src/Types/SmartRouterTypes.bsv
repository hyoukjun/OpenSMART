import Vector::*;
import Fifo::*;

import Types::*;
import MessageTypes::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;
import CreditTypes::*;

import SwitchAllocTypes::*;
import VCAllocUnitTypes::*;
import RoutingUnitTypes::*;
import SmartTypes::*;


interface DataLink;
  method ActionValue#(Flit)         getFlit;
  method Action                     putFlit(Flit flit);
endinterface

interface ControlLink;
  method ActionValue#(CreditSignal) getCredit;
  method Action                     putCredit(CreditSignal creditSig);
  //Added for SMART
  method Action            putSSRs(SSRBundle sb);
  method ActionValue#(SSR) getSSR;
endinterface

interface Router;
  method Bool isInited;
//  method Action initialize(MeshWIdx widthID, MeshHIdx heightID);
  interface Vector#(NumPorts, DataLink)    dataLinks;
  interface Vector#(NumPorts, ControlLink) controlLinks;
endinterface

//(* noinline *)
function FlitTypeBundle getFlitTypes(FlitBundle fb);
  FlitTypeBundle ftb = newVector;

  for(Integer inPort = 0;inPort<valueOf(NumPorts);inPort=inPort+1) begin
     ftb[inPort] = isValid(fb[inPort])? Valid(validValue(fb[inPort]).flitType) : Invalid;
  end

  return ftb;
endfunction

//(* noinline *)
function SAReq getSAReq(HeaderBundle hb);
  SAReq saReqBits = newVector;

  for(Integer inPort = 0; inPort<valueOf(NumPorts); inPort=inPort+1) begin
//ifdef SOURCE_ROUTING
//        saReqBits[inPort] = isValid(hb[inPort])? idx2Dir(validValue(hb[inPort]).routeInfo[0]) : null_;
//endif
      saReqBits[inPort] = isValid(hb[inPort])? validValue(hb[inPort]).routeInfo.nextDir : null_;

  end

  return saReqBits;
endfunction

//(* noinline *)
function RouteInfoBundle extractValidRoutingInfos(HeaderBundle hb, SARes grantedInPorts); 

  RouteInfoBundle rb = replicate(Invalid);

  for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort +1)
  begin
    if(isValid(hb[inPort]) && grantedInPorts[inPort] == 1) begin
      let header = validValue(hb[inPort]);
      let nextDirn = getNextDirn(header.routeInfo);
      rb[nextDirn] = Valid(header.routeInfo); 
    end
  end      

  return rb;

endfunction

//(* noinline *)
function SmartHopsBundle getSHops(RouteInfoBundle rb);

    SmartHopsBundle sHops = newVector;
    
    for(DirIdx outPort = 0; outPort < fromInteger(valueOf(NumPorts)); outPort = outPort +1)
    begin
      if(isValid(rb[outPort])) begin

        if(outPort == dIdxNorth || outPort == dIdxSouth) begin
          let remainingYhops = validValue(rb[outPort]).numYhops;
          sHops[outPort] = (remainingYhops > fromInteger(valueOf(HPCMax)))? fromInteger(valueOf(HPCMax)) : truncate(remainingYhops);
        end
        else if(outPort == dIdxEast || outPort == dIdxWest) begin
          let remainingXhops = validValue(rb[outPort]).numXhops;
          sHops[outPort] = (remainingXhops > fromInteger(valueOf(HPCMax)))? fromInteger(valueOf(HPCMax)) : truncate(remainingXhops);
        end
        else begin //Local
          sHops[outPort] = 0;
        end
      end
      else begin
        sHops[outPort] = 0;
      end       
    end

    return sHops;

endfunction

/* GetSHops for source routing
`ifdef SOURCE_ROUTING
        SmartHops sHop = 0;
        Bool finishTraverse = False;

        let routingInfo = validValue(rb[outPort]);

        for(Integer hops = 0; hops < valueOf(HPCMax); hops = hops+1)
        begin
          if(!finishTraverse) begin
            if(routingInfo[hops] == outPort) begin
              sHop = sHop + 1);
            end
            else begin
              finishTraverse = True;     
            end
          end  
        end
        sHops[outPort] = sHop;
`else //Look-ahead routing
*/


