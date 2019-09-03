import Vector::*;

//User parameters
//typedef 100000  BenchmarkCycle;
typedef 100000  BenchmarkCycle;

typedef 32      DataSz;
typedef 1       NumFlitsPerDataMessage;
typedef 1       NumFlitsPerControlMessage;

typedef 6       UserHPCMax;

typedef 4       MeshWidth;
typedef 4       MeshHeight;
typedef 2       NumUserVCs;

typedef 10     InjectionRate; //Injection Rate: 0.XX

typedef 4      NumTrafficGeneratorBufferSlots;

RoutingAlgorithms currentRoutingAlgorithm = XY_;

///////////////////////////////////////////////////////////////
//Fixed and derived Types

typedef enum {XY_, YX_} RoutingAlgorithms deriving(Bits, Eq);
typedef TMul#(MeshWidth, MeshHeight) NumMeshNodes;

typedef	Bit#(DataSz) Data;

//Dimensions, fixed for mesh network
typedef 5                  NumPorts;       //N, E, S, W, L
typedef TSub#(NumPorts, 1) NumNormalPorts; //N, E, S, W

typedef NumPorts           MaxNumPorts;    //For arbitrary topology
typedef NumNormalPorts     MaxNumNormalPorts; 

//Mesh dimensions
typedef	TAdd#(1, TLog#(MeshWidth))	MeshWidthBitSz;
typedef	TAdd#(1, TLog#(MeshHeight))	MeshHeightBitSz;

typedef	Bit#(MeshWidthBitSz)	MeshWIdx;
typedef	Bit#(MeshHeightBitSz)	MeshHIdx;

interface NtkArbiter#(numeric type numRequesters);
  method Action                            initialize;
  method ActionValue#(Bit#(numRequesters)) getArbit(Bit#(numRequesters) reqBit);
endinterface
