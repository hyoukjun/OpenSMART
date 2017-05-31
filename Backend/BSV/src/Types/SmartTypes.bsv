import Types::*;
import MessageTypes::*;
import RoutingTypes::*;

import Vector::*;

typedef TMin#(UserHPCMax, TSub#(TMin#(MeshWidth, MeshHeight),1)) HPCMax;
typedef Bit#(TAdd#(TLog#(HPCMax),1))                             SmartHops;
typedef Vector#(NumPorts, SmartHops)                             SmartHopsBundle;

typedef Vector#(NumPorts, Bool)                                  SmartFlitInfo;
typedef Maybe#(Flit)                                             SmartFlit;
typedef Vector#(NumNormalPorts, SmartFlit)                       SmartFlitBundle;

typedef Bit#(TSub#(HPCMax,1))                                    SSR;
typedef Vector#(TSub#(HPCMax,1), SSR)                            SSRBundle;
//typedef Vector#(Tsub#(HPCMax,1), SmartHops)                               SSRBundle;

typedef enum {Pass, Stop}                                        SmartFlag deriving(Bits,Eq);
typedef Vector#(NumNormalPorts, SmartFlag)                       SmartFlagBundle;

typedef enum {Local, Bypass}	                                 SmartSel deriving(Bits, Eq);
typedef DirX                                                     SmartDirX;
typedef DirY                                                     SmartDirY;

typedef enum {SSR, Traversal}                                    SmartStage deriving(Bits, Eq);


/*
function Bool hasSSRequester(SSRBundle sb);
  Bool ret = False;

  for(Integer i=0; i<valueOf(HPCMax); i=i+1) begin
    if(isValid(sb[i])) begin
      ret = True;
    end
  end
	
  return ret;
endfunction
*/

/*
  Used ont-hot encoding for SSR signals.
  This enables a shift-based low-overhead remaining hops calcuation in SSR managers.

  Ex) When HPC_max = 4, encodings are like below
    100: 4
    010: 3
    001: 2
    000: 1, 0 => Both 1 and 0 means "Stop" in routers.
*/

//(* noinline *)
function SSR encodeSSR(SmartHops nextHops);
  SSR ssr = 0;

  if(nextHops > 1) begin
    ssr[nextHops-2] = 1;
//    ssr[nextHops-1] = 1;
  end
  
  return ssr;
endfunction

//(* noinline *)
function Bool hasSSR_Requester(SSRBundle sb);
  Bool ret = False;
  for(Integer ssrSourceOffset = 0; ssrSourceOffset < valueOf(HPCMax)-1; ssrSourceOffset=ssrSourceOffset+1) begin
    if(sb[ssrSourceOffset] != 0) begin
      ret = True;
    end
  end
  return ret;
endfunction

function SSR decreaseSSR(SSR ssr);
  return ssr >> 1; //Implicitly logical shift due to the type. (Bit)
endfunction

function DirIdx getDstPort(DirIdx incomingPort);
  if(incomingPort == dIdxLocal) begin
    return dIdxLocal;
  end
  else begin
    let ret = (incomingPort < dIdxSouth)? incomingPort + 2 : incomingPort -2;
    return ret;
  end
  /*
  let ret =  case(incomingPort)
               dIdxNorth : dIdxSouth; //N->S
               dIdxEast  : dIdxWest;  //E->W
               dIdxSouth : dIdxNorth; //S->N
               dIdxWest  : dIdxEast;  //W->E
               dIdxLocal : dIdxLocal; //L->L; Since local flag is always "stop", it does not incur any problem
               default   : dIdxNULL;
             endcase;
  return ret;
  */
endfunction
