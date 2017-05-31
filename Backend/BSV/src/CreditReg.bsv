import CReg::*;
import Vector::*;
import Fifo::*;

import Types::*;
import CreditTypes::*;

interface CreditCheck;
  method Bool hasCredit;
endinterface

interface CreditReg;
  /* Inquire values */
  interface Vector#(NumPorts, CreditCheck) creditCheck;
  /* Update  values */
  method Action incCredit;
  method Action decCredit;
endinterface

(* synthesize *)
module mkCreditReg(CreditReg);
  CReg#(2, Credit)  creditCount    <- mkCReg(fromInteger(valueOf(InitialCredit)));

  /*****************************************************************************/

  function Bool checkCredit;
    return (creditCount[1] > 0);
  endfunction

  /*****************************************************************************/
  Vector#(NumPorts, CreditCheck) creditCheckDummy;
  for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort+1) begin
    creditCheckDummy[inPort] = 
      interface CreditCheck
        method Bool hasCredit = checkCredit;
      endinterface;
  end
  interface creditCheck = creditCheckDummy;

  method Action incCredit;
//    if(creditCount[0] < fromInteger(valueOf(InitialCredit)))
	creditCount[0] <= creditCount[0] +1;
  endmethod

  method Action decCredit;
    if(creditCount[1] > 0) begin
      creditCount[1] <= creditCount[1] -1;
    end
  endmethod

endmodule
