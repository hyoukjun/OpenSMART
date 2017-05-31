import Vector::*;
import Types::*;
import SmartTypes::*;
import SwitchAllocTypes::*;

interface GlobalSwitchAlloc;
  method SmartFlag getSmartFlag(Bool localGrant, Bool incomingSSR, Bool hasVC);
endinterface

interface GlobalSwitchAllocUnit;
  interface Vector#(NumNormalPorts, GlobalSwitchAlloc) globalSwitchAllocLinks;
endinterface

(* synthesize *)
module mkGlobalSwitchAllocUnit(GlobalSwitchAllocUnit);

  Vector#(NumNormalPorts, GlobalSwitchAlloc) globalSwitchAllocLinksDummy;

  for(Integer prt = 0; prt<valueOf(NumNormalPorts); prt=prt+1)
  begin
    globalSwitchAllocLinksDummy[prt] = 
      interface GlobalSwitchAlloc
        method SmartFlag getSmartFlag(Bool localGrant, Bool incomingSSR, Bool hasVC);
          if(localGrant) begin
            return Stop;
          end
          else begin  
            if(incomingSSR && hasVC) begin
              return Pass;
            end	    
            else begin
              return Stop;
            end		    
          end		  
        endmethod
      endinterface;
  end
  interface globalSwitchAllocLinks = globalSwitchAllocLinksDummy;

endmodule
