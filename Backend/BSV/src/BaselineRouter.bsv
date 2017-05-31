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

import InputUnit::*;
import OutputUnit::*;
import CreditUnit::*;
import SwitchAllocUnit::*;
import CrossbarSwitch::*;
import SmartVCAllocUnit::*;

import RoutingUnit::*;


/* Get/Put Context 
 *  Think from outside of the module; 
 *  Ex) I am "getting" a flit from this module. 
 *      I am "putting" a flit toward this module.
 */

typedef struct {
  SARes grantedInPorts;
  SARes grantedOutPorts;
  HeaderBundle hb;
  FlitBundle fb;
} SA2CB deriving (Bits, Eq);

interface DataLink;
  method ActionValue#(Flit)         getFlit;
  method Action                     putFlit(Flit flit);
endinterface

interface ControlLink;
  method ActionValue#(CreditSignal) getCredit;
  method Action                     putCredit(CreditSignal creditSig);
endinterface

interface Router;
  method Bool isInited;
  interface Vector#(NumPorts, DataLink)    dataLinks;
  interface Vector#(NumPorts, ControlLink) controlLinks;
endinterface

(* noinline *)
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

(* noinline *)
function RouteInfoBundle getRB(HeaderBundle hb, SARes grantedInPorts); 

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


(* synthesize *)
module mkBaselineRouter(Router);

  /********************************* States *************************************/
  Reg#(Bool)                                   inited        <- mkReg(False);

  //To break rules
  Fifo#(1, FlitBundle)                         flitsBuf      <- mkBypassFifo;
  Fifo#(1, HeaderBundle)                       headersBuf    <- mkBypassFifo;
  Fifo#(1, SARes)                              saResBuf      <- mkBypassFifo;

  //Pipelining
  Fifo#(1, SA2CB)                              sa2cb         <- mkPipelineFifo;
  /******************************* Submodules ***********************************/

  /* Input Side */
  Vector#(NumPorts, InputUnit)          inputUnits   <- replicateM(mkInputUnit);
  Vector#(NumPorts, ReverseCreditUnit)  crdUnits     <- replicateM(mkReverseCreditUnit);

  /* In the middle */
  SwitchAllocUnit                       localSAUnit  <- mkSwitchAllocUnit;
  CrossbarSwitch                        cbSwitch     <- mkCrossbarSwitch;

  /* Output Side */
  Vector#(NumPorts, OutputUnit)         outputUnits  <- replicateM(mkOutputUnit);
  Vector#(NumPorts, SmartVCAllocUnit)   vcAllocUnits <- replicateM(mkSmartVCAllocUnit);
  Vector#(NumPorts, RoutingUnit)        routingUnits <- replicateM(mkRoutingUnit); 

  /******************************* Functions ***********************************/
  /* Read Inputs */
  function FlitBundle readFlits;
    FlitBundle currentFlits = newVector;

    for(Integer inPort=0; inPort<valueOf(NumPorts) ; inPort=inPort+1) begin
      currentFlits[inPort] = inputUnits[inPort].peekFlit;
    end

    return currentFlits;
  endfunction

  function HeaderBundle readHeaders;
    HeaderBundle hb = newVector;

    for(Integer inPort = 0; inPort<valueOf(NumPorts); inPort = inPort +1) begin
      hb[inPort] =  inputUnits[inPort].peekHeader;
    end

    return hb;
  endfunction

  function Action deqWinnerFlits(SARes saRes, FlitBundle fb);
  action
    for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort+1) begin
      if(saRes[inPort] == 1) begin
        let currFlit = validValue(fb[inPort]);
        inputUnits[inPort].deqFlit;
        crdUnits[inPort].putCredit(Valid(CreditSignal_{vc: currFlit.vc, isTailFlit:True})); 
      end
    end
  endaction
  endfunction

  function Action putFlit2XBar(SARes saRes, FlitBundle fb, HeaderBundle hb);
  action

    for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort+1) begin
      if(saRes[inPort] == 1) begin
        let currFlit = validValue(fb[inPort]);
        let destDirn = dir2Idx(validValue(hb[inPort]).routeInfo.nextDir);
        cbSwitch.crossbarPorts[inPort].putFlit(currFlit, destDirn);
      end
    end

  endaction
  endfunction

  function FreeVCInfo getFreeVCInfo;
    FreeVCInfo ret = ?;

    for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort+1) begin
      ret[outPort] = vcAllocUnits[outPort].hasVC? 1:0;
    end

    return ret;
  endfunction

  /****************************** Router Behavior ******************************/
  rule doInitialize(!inited);
    Bit#(1) saInited = localSAUnit.isInited? 1:0;
    Bit#(1) iuInited = 1;
    Bit#(1) vaInited = 1;

    for(DirIdx dirn=0; dirn<fromInteger(valueOf(NumPorts)); dirn=dirn+1) begin
      iuInited = (iuInited == 1  && inputUnits[dirn].isInited)? 1:0;
      vaInited = (vaInited == 1 && vcAllocUnits[dirn].isInited)? 1:0;
    end

    if(saInited==1 && iuInited==1 && vaInited==1) begin
      inited <= True;
    end
  endrule 

  // Critical Path Analysis
  // BR -> SA -> SSR Send -> SSR Receive -> SSR Setup
//  (* descending_urgency = "rl_ReqLocalSA, rl_GetLocalSARes, rl_PrepareLocalFlits, rl_deqBufs" *)
  /*********** SA-L ***********/
  rule rl_ReqLocalSA(inited);
    //Read necessary data
    let flits        = readFlits();
    let headers      = readHeaders();
    let saReq        = getSAReq(headers);
    let freeVCInfo   = getFreeVCInfo; 

    flitsBuf.enq(flits);
    headersBuf.enq(headers);
    localSAUnit.reqSA(saReq, freeVCInfo);
  endrule

  rule rl_GetLocalSARes(inited);
    let grantedInPorts  <- localSAUnit.getGrantedInPorts;
    saResBuf.enq(grantedInPorts);
  endrule


  rule rl_deqFlits(inited);
    let flits = flitsBuf.first;
    let headers = headersBuf.first;
    let grantedInPorts = saResBuf.first;
    deqWinnerFlits(grantedInPorts, flits);

    //2 stage
//    putFlit2XBar(grantedInPorts, flits, headers);    
    //3 stage
    sa2cb.enq(SA2CB{grantedInPorts: grantedInPorts, 
                    grantedOutPorts: ?, 
                    hb: headers, 
                    fb: flits});
    
  endrule
  /****************************/
  //For 3-stage
  rule rl_PrepareLocalFlits(inited);
    let x = sa2cb.first;
    let flits           = x.fb;
    let headers         = x.hb;
    let grantedInPorts  = x.grantedInPorts;

    sa2cb.deq;

    putFlit2XBar(grantedInPorts, flits, headers);
  endrule
  
  /***********************************/

  /*********** Deque temporary Buffers ***********/

  rule rl_deqBufs(inited);
    flitsBuf.deq;
    headersBuf.deq;
    saResBuf.deq;
  endrule

  /**********************************************/


  for(Integer prt=0; prt<valueOf(NumPorts); prt = prt+1)
  begin
    rule rl_enqOutBufs(inited);
      let flit <- cbSwitch.crossbarPorts[prt].getFlit;
      outputUnits[prt].putFlit(flit);
    endrule
  end


  /***************************** Router Interface ******************************/

  /* SubInterface routerLinks 
   *  => It parameterizes the number of Flit/Credit Links.
   */
  Vector#(NumPorts, DataLink) dataLinksDummy;
  for(DirIdx prt = 0; prt < fromInteger(valueOf(NumPorts)); prt = prt+1)
  begin
      dataLinksDummy[prt] =

        interface DataLink
          method ActionValue#(Flit) getFlit;
            let retFlit <- outputUnits[prt].getFlit;
//            let retFlit <- cbSwitch.crossbarPorts[prt].getFlit;

            //Update VC
            let newVC <- vcAllocUnits[prt].getNextVC;
            retFlit.vc = newVC;

            //Update Routing Information
//            retFlit.routeInfo = nextRoutingInfo(retFlit.routeInfo); // Source Routing
            retFlit.routeInfo = routingUnits[prt].smartOutportCompute(retFlit.routeInfo, prt);

            retFlit.stat.hopCount = retFlit.stat.hopCount + 1;
            return retFlit;
	  endmethod

          method Action putFlit(Flit flit);
            inputUnits[prt].putFlit(flit);
          endmethod

        endinterface;
  end 

  Vector#(NumPorts, ControlLink) controlLinksDummy;
  for(DirIdx prt = 0; prt < fromInteger(valueOf(NumPorts)); prt = prt+1)
  begin
    controlLinksDummy[prt] =
      interface ControlLink
        method ActionValue#(CreditSignal) getCredit if(inited);
          let credit <- crdUnits[prt].getCredit();
          return credit;
        endmethod

        method Action putCredit(CreditSignal creditSig) if(inited);
          if(isValid(creditSig)) begin
            vcAllocUnits[prt].putFreeVC(validValue(creditSig).vc);
          end
        endmethod

      endinterface;
  end

  interface dataLinks = dataLinksDummy;
  interface controlLinks = controlLinksDummy;

  method Bool isInited;
    return inited; 
  endmethod

endmodule
