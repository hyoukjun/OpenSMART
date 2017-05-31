import Vector::*;
import CReg::*;

import Types::*;
import SmartTypes::*;

interface SmartUnitSetup;
  method Action setupSSR(Bool hasSSR);
  method Action updateInfo(Bool hasVC, Bool hasLocal);
endinterface

interface SmartUnitRead;
  method SmartFlag getFlag;
endinterface

interface SmartFlagUnit;
  Vector#(NumNormalPorts, SmartUnitSetup) smartSetupLinks;
  Vector#(NumNormalPorts, SmartUnitRead)  smartReadLinks;
endinterface

/* SmartUnit description
1. Port number and direction 
    0: from N => NS
    1: from E => EW
    2: from S => SN
    3: from W => WE       

2. Concept
  Flag: A traffic signal that controls SMART flits. If the flas is "Pass",
        corresponding SMART flit may pass. Or, it stops at the router.

3. Timing
  SSR comes a cycle before the SMART flit traverses. It is saved on the CReg
  (Concurrent Register). 

  When it traverses, we need to see if
    1) There is a local flit that tries to use the same output port 
       as the SMART flit
    2) There is an available VC in the next router

  Simultaneously, this module should received new SSRs.

  To solve this timing problem, I appropriately used concurrent register.
    Creg#(2, SmartFlag) smartFlag
      smartFlag[0].read : From the previous cycle
      smartFlag[0].write: Update current local flit/VC availability info
      smartFlag[1].read : Actual flags that current SMART flags see
      smartFlag[1].write: Update currently incoming SSR for the next cycle
  
  * The higher port number in the Concurrent register gets high priority.
  * In the same port number, read occurs first, and then write occurs.

*/

(* synthesize *)
module mkSmartFlagUnit(SmartFlagUnit);

  Vector#(NumNormalPorts, CReg#(3, SmartFlag)) smartFlags <- replicateM(mkCReg(Stop));
  
  Vector#(NumNormalPorts, SmartUnitSetup) smartSetupLinksDummy;
  for(Integer dir = 0; dir < valueOf(NumNormalPorts); dir = dir+1)
  begin
    smartSetupLinksDummy[dir] =
      interface SmartUnitSetup
        method Action setupSSR(Bool hasSSR); 
          smartFlags[dir][1] <= hasSSR? Pass: Stop;
        endmethod

        method Action updateInfo(Bool hasVC, Bool hasLocal);
          smartFlags[dir][0] <= (hasVC && hasLocal)? smartFlags[0]: Stop;
        endmethod
      endinterface; 
  end
  interface smartSetupLinks = smartSetupLinksDummy; 
  
  Vector#(NumNormalPorts, SmartUnitRead)  smartReadLinksDummy;
  for(Integer dir = 0; dir < valueOf(NumNormalPorts); dir = dir+1)
  begin
    smartReadLinksDummy[dir] =
      interface SmartUnitRead
        method SmartFlag getFlag;
          return smartFlags[dir][1];
        endmethod
      endinterface;
  end
  interface smartReadLinks = smartReadLinksDummy;

endmodule
