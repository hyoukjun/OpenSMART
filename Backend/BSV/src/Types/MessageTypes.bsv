/*
 Message Types

 Author: Hyoukjun Kwon(hyoukjun@gatech.edu)
 

*/


/********** Native Libraries ************/
import Vector::*;
/******** User-Defined Libraries *********/
import Types::*;
import VirtualChannelTypes::*;
import RoutingTypes::*;

/************* Definitions **************/

//1. Sub-definitions for Flit class

  //Message class and Flit types
  typedef enum {Data, Control}              MsgType  deriving(Bits, Eq);
  typedef enum {Head, Body, Tail, HeadTail} FlitType deriving(Bits, Eq);

  //Statistic information for tests
  typedef struct {
//    Data      flitId;
    Data      hopCount;
    MeshWIdx  srcX;
    MeshHIdx  srcY;
    MeshWIdx  dstX;
    MeshHIdx  dstY;
    Data      injectedCycle;
    Data      inflightCycle;
  } FlitStatistics deriving(Bits, Eq);

`ifdef SOURCE_ROUTING
    typedef SourceRoutingInfo RouteInfo;
`else
    typedef LookAheadRouteInfo RouteInfo;
`endif

  typedef Vector#(NumPorts, Maybe#(RouteInfo)) RouteInfoBundle;

  typedef Data FlitData;

  typedef struct {
    VCIdx vc;
    RouteInfo routeInfo;
  } Header deriving (Bits, Eq);

//2. Main definition
  // Flit Type
  typedef struct {
    MsgType   msgType;
    VCIdx     vc;
    FlitType  flitType;  //Head, Body, Tail, HeadTail
    RouteInfo routeInfo;
    FlitData  flitData;
// `ifdef DETAILED_STATISTICS
    FlitStatistics stat;
// `endif
  } Flit deriving (Bits, Eq);

/* Bundles */
typedef Vector#(NumPorts, Maybe#(Header))   HeaderBundle;
typedef Vector#(NumPorts, Maybe#(FlitType)) FlitTypeBundle;
typedef Vector#(NumPorts, Maybe#(Flit))     FlitBundle;

function Bool isHead(Flit flit);
  return (flit.flitType == Head || flit.flitType == HeadTail);
endfunction

function Bool isTail(Flit flit);
  return (flit.flitType == Tail || flit.flitType == HeadTail);
endfunction

function Bool isValidFlitBundle (FlitBundle fb, DirIdx idx);
  return isValid(fb[idx]);
endfunction

function Flit fb_getFlit(FlitBundle fb, Integer idx);
  return validValue(fb[idx]);
endfunction

function Direction getFlitDirection(Flit flit);
`ifdef SOURCE_ROUTING
  return idx2Dir(flit.routeInfo[0]);
`else
  return flit.routeInfo.nextDir;
`endif
endfunction
