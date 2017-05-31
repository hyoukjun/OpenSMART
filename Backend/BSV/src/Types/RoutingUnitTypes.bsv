import Vector::*;
import Types::*;
import MessageTypes::*;
import RoutingTypes::*;

typedef Vector#(NumPorts, Maybe#(RouteInfo)) RouteInfoBundle;

typedef RouteInfoBundle RCReq;
typedef RouteInfoBundle RCRes;
