import Vector::*;
import Types::*;
import VirtualChannelTypes::*;

typedef Vector#(NumPorts, Maybe#(VCIdx)) VCBundle;
typedef VCBundle                         VARes;
typedef Vector#(NumPorts, VCBundle)      VAReq;


typedef VCBundle                         VCInfo;
