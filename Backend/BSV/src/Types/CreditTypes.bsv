import Types::*;
import VirtualChannelTypes::*;

//Credits
typedef TMax#(ControlVCDepth, DataVCDepth)    MaxCreditCount;
typedef Bit#(TAdd#(1, TLog#(MaxCreditCount))) Credit;
typedef TMin#(ControlVCDepth, DataVCDepth)    InitialCredit; 

typedef struct {
  VCIdx vc;
  Bool isTailFlit;
} CreditSignal_ deriving(Bits, Eq);

typedef Maybe#(CreditSignal_) CreditSignal;

