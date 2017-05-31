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
import SmartRouterTypes::*;

import InputUnit::*;
import OutputUnit::*;
import CreditUnit::*;
import SwitchAllocUnit::*;
import CrossbarSwitch::*;
import SmartVCAllocUnit::*;
import GlobalSwitchAllocUnit::*;
import SmartFlag::*;
import RoutingUnit::*;
import SSR_IO_Unit::*;

/* Get/Put Context 
 *  Think from outside of the module; 
 *  Ex) I am "getting" a flit from this module. 
 *      I am "putting" a flit toward this module.
 */


/*
typedef struct {
  SARes grantedInPorts;
  SARes grantedOutPorts;
  HeaderBundle hb;
  FlitBundle fb;
} SA2CB deriving (Bits, Eq);
*/


typedef struct {
  Header header; 
  Flit flit;
} SA2CB deriving (Bits, Eq);


(* synthesize *)
module mkSmartRouter(Router);

  /********************************* States *************************************/
  Reg#(Bool)                                   inited        <- mkReg(False);

  Vector#(NumPorts, Fifo#(1, Flit))            smartFlitBuf  <- replicateM(mkBypassFifo);

  //To break rules
  Fifo#(1, FlitBundle)                         flitsBuf      <- mkBypassFifo;
  Fifo#(1, HeaderBundle)                       headersBuf    <- mkBypassFifo;
  Fifo#(1, SARes)                              saResInBuf    <- mkBypassFifo;

  //Pipelining
  // Stage 1 to 2
  Vector#(NumPorts, Fifo#(1, SA2CB))    sa2cb               <- replicateM(mkPipelineFifo);
  Fifo#(1, HeaderBundle)                pipe_headers        <- mkPipelineFifo;
  Fifo#(1, SARes)                       pipe_grantedInputs  <- mkPipelineFifo;
  Fifo#(1, SARes)                       pipe_grantedOutputs <- mkPipelineFifo;

  //Stage 2 to 3
  Vector#(NumPorts, OutputUnit)         outputUnits  <- replicateM(mkOutputUnit);

  /******************************* Submodules ***********************************/

  /* Input Side */
  Vector#(NumPorts, InputUnit)          inputUnits   <- replicateM(mkInputUnit);
  Vector#(NumPorts, ReverseCreditUnit)  crdUnits     <- replicateM(mkReverseCreditUnit);
  GlobalSwitchAllocUnit                 globalSAUnit <- mkGlobalSwitchAllocUnit;

  /* In the middle */
  SwitchAllocUnit                       localSAUnit  <- mkSwitchAllocUnit;
  CrossbarSwitch                        cbSwitch     <- mkCrossbarSwitch;

  /* Output Side */
  Vector#(NumPorts, SmartVCAllocUnit)   vcAllocUnits <- replicateM(mkSmartVCAllocUnit);
  Vector#(NumPorts, RoutingUnit)        routingUnits <- replicateM(mkRoutingUnit); 
  Vector#(NumPorts, SSR_IO_Unit)        ssrIOUnits   <- replicateM(mkSSR_IO_Unit);
  Vector#(NumPorts, SmartFlagUnit)      smartFlags   <- replicateM(mkSmartFlagUnit);

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

  function Action putFlit2XBar(Flit flit, Header header, DirIdx inPort);
  action
    let destDirn = dir2Idx(header.routeInfo.nextDir);
    cbSwitch.crossbarPorts[inPort].putFlit(flit, destDirn);

  endaction
  endfunction

  function FreeVCInfo getFreeVCInfo;
    FreeVCInfo ret = ?;

    for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort+1) begin
      ret[outPort] = vcAllocUnits[outPort].hasVC? 1:0;
    end

    return ret;
  endfunction

  function FreeVCInfo getFreeVCInfo2;
    FreeVCInfo ret = ?;

    for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort+1) begin
      ret[outPort] = vcAllocUnits[outPort].hasVC2? 1:0;
    end

    return ret;
  endfunction



  function Action sendSSR (SARes grantedInPorts, HeaderBundle hb);
  action
    //It converts the input side routing info toward output side
    RouteInfoBundle rb = extractValidRoutingInfos(hb, grantedInPorts);
    SmartHopsBundle sHops = getSHops(rb);

    for(Integer outPort = 0; outPort < valueOf(NumNormalPorts); outPort=outPort+1)
    begin
      ssrIOUnits[outPort].putOutSSR(encodeSSR(sHops[outPort])); //Encode # of hops to one-hot code
    end
  endaction  
  endfunction

  function Action setupFlags(SARes grantedOutPorts, FreeVCInfo freeVCInfo);
  action  

    for(Integer outPort = 0; outPort < valueOf(NumNormalPorts); outPort = outPort+1)
    begin

      let hasSSR <- ssrIOUnits[outPort].hasInSSR_Requester;

      let newFlag = (grantedOutPorts[outPort] == 0    // 1. No local winner for the output port(outPort)
                      && hasSSR)?                     // 2. Has at least one incoming SSR
                      && freeVCInfo[outPort] == 1)?  // 3. Has a free VC at the next router
                                                       //   -> Winner implies it has at least one free VC
                      Pass:Stop;

        smartFlags[outPort].setFlag(newFlag);
  end

  endaction
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

  /****************************************/
  /*********** Pipeline Stage 1 ***********/
  /****************************************/
  // Buffer Read & SA-L
  rule rl_ReqLocalSA(inited);
    //Read necessary data
    let flits        = readFlits();
    let headers      = readHeaders();
    let saReq        = getSAReq(headers);
    let freeVCInfo   = getFreeVCInfo; //Local ports are marked as no VC
    
    flitsBuf.enq(flits);
    headersBuf.enq(headers);

    pipe_headers.enq(headers);

    localSAUnit.reqSA(saReq, freeVCInfo);
  endrule

  rule rl_RespLocalSA(inited);
    let grantedInPorts  <- localSAUnit.getGrantedInPorts;
    let grantedOutPorts <- localSAUnit.getGrantedOutPorts;

    saResInBuf.enq(grantedInPorts);

    pipe_grantedInputs.enq(grantedInPorts);
    pipe_grantedOutputs.enq(grantedOutPorts);
  endrule


  rule rl_GetLocalSARes(inited);
    let flits = flitsBuf.first;
    let headers = headersBuf.first;

    let grantedInPorts = saResInBuf.first;

    for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort + 1)
    begin
      if(grantedInPorts[inPort] == 1) begin
        let flit = validValue(flits[inPort]);
        let header = validValue(headers[inPort]);
        inputUnits[inPort].deqFlit;
        crdUnits[inPort].putCredit(Valid(CreditSignal_{vc: flit.vc, isTailFlit:True})); 
        sa2cb[inPort].enq(SA2CB{header:header, flit: flit});
      end
    end
  endrule

  rule rl_deqTempBufs(inited);
    headersBuf.deq;
    flitsBuf.deq;
    saResInBuf.deq;
  endrule


  /****************************************/
  /*********** Pipeline Stage 2 ***********/
  /****************************************/

  /*********** SA-G ***********/


  //Send SSR
  
  rule rl_SendSSR(inited);
    let headers = pipe_headers.first;
    let grantedInPorts = pipe_grantedInputs.first; 
    pipe_headers.deq;
    pipe_grantedInputs.deq; 

    sendSSR(grantedInPorts, headers);
  endrule
  
  // Set up flags
  rule rl_GlobalSA(inited);
    let grantedOutPorts = pipe_grantedOutputs.first;
    pipe_grantedOutputs.deq;

    let freeVCInfo = getFreeVCInfo2;

    setupFlags(grantedOutPorts, freeVCInfo);
  endrule

  for(Integer outPort=0; outPort<valueOf(NumNormalPorts); outPort = outPort+1)
  begin
    rule rl_deqFlags(inited);
      smartFlags[outPort].deqFlag;
    endrule
  end


  /****************************/

  /*********** Local Flits ***********/
  for(DirIdx inPort=0; inPort<fromInteger(valueOf(NumPorts)); inPort = inPort+1)
  begin

    rule rl_PrepareLocalFlits(inited);
      let x = sa2cb[inPort].first;
      sa2cb[inPort].deq;

      let flit = x.flit;
      let header = x.header;

      putFlit2XBar(flit, header, inPort);
    endrule

  end

  for(Integer outPort=0; outPort<valueOf(NumPorts); outPort = outPort+1)
  begin
    rule rl_enqOutBufs(inited);
      let flit <- cbSwitch.crossbarPorts[outPort].getFlit;
      outputUnits[outPort].putFlit(flit);
    endrule
  end


  /****************************************/
  /*********** Pipeline Stage 3 ***********/
  /****************************************/

  // Link traversals

  /***************************** Router Interface ******************************/

  /* SubInterface routerLinks 
   *  => It parameterizes the number of Flit/Credit Links.
   */
  Vector#(NumPorts, DataLink) dataLinksDummy;
  for(DirIdx prt = 0; prt < fromInteger(valueOf(NumPorts)); prt = prt+1)
  begin
      dataLinksDummy[prt] =

        interface DataLink
          //getFlit: output side
          method ActionValue#(Flit) getFlit if(inited);
            let dstPrt = getDstPort(prt);
            let retFlit = ?;
            if(smartFlags[prt].isPass) begin
              smartFlitBuf[prt].deq;
              retFlit = smartFlitBuf[prt].first;
              crdUnits[dstPrt].putCreditSMART(Valid(CreditSignal_{vc: retFlit.vc, isTailFlit:True})); 
            end
            else begin
              let localFlit <- outputUnits[prt].getFlit;
              retFlit = localFlit;
              retFlit.stat.hopCount = retFlit.stat.hopCount + 1; //Increase hopCount
            end

            let newVC <- vcAllocUnits[prt].getNextVC;
            retFlit.vc = newVC;

            retFlit.routeInfo = routingUnits[prt].smartOutportCompute(retFlit.routeInfo, prt);
            return retFlit;

          endmethod

          method Action putFlit(Flit flit) if(inited);

            if(prt == dIdxLocal) begin
              inputUnits[prt].putFlit(flit);
            end
            else begin
              let dstPrt = getDstPort(prt);

              if(smartFlags[dstPrt].isStop) begin
                inputUnits[prt].putFlit(flit);
              end
              else begin
                smartFlitBuf[dstPrt].enq(flit); //Bypass
              end
            end
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

        method Action putSSRs(SSRBundle incomingSSRs) if(inited);
          ssrIOUnits[prt].putInSSR(incomingSSRs);
        endmethod
	 
        method ActionValue#(SSR) getSSR if(inited);
          let ssr <- ssrIOUnits[prt].getOutSSR;
          return ssr;
        endmethod
      endinterface;
  end

  interface dataLinks = dataLinksDummy;
  interface controlLinks = controlLinksDummy;
  
  method Bool isInited;
    return inited; 
  endmethod

endmodule
