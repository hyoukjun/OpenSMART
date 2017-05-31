import Vector::*;

import Types::*;
import MessageTypes::*;
import SmartTypes::*;
import CreditTypes::*;
import RoutingTypes::*;

`ifdef SMART
import SmartRouterTypes::*;
import SmartRouter::*;
import SSR_Manager::*;
//import SSR_Router::*;
//import SSR_Network::*;
`else
import BaselineRouter::*;
`endif


import Connectable::*;

interface NetworkOuterInterface;
  method Action                     putFlit(Flit flit);
  method ActionValue#(Flit)         getFlit;
  method Action                     putCredit(CreditSignal crd);
  method ActionValue#(CreditSignal) getCredit;
endinterface

interface Network;
  method Bool isInited;
  interface Vector#(MeshHeight, Vector#(MeshWidth, NetworkOuterInterface)) ntkPorts;
endinterface

(* synthesize *)
module mkNetwork(Network);

  Reg#(Bool) inited <- mkReg(False);

`ifdef SMART  
  //SSR managers
  Vector#(MeshHeight, Vector#(MeshWidth, SSR_Manager)) horizontal_SSR_Managers <- replicateM(replicateM(mkSSR_Manager));
  Vector#(MeshHeight, Vector#(MeshWidth, SSR_Manager)) vertical_SSR_Managers <- replicateM(replicateM(mkSSR_Manager));

//Tiles
  Vector#(MeshHeight, Vector#(MeshWidth, Router)) routers <- replicateM(replicateM(mkSmartRouter));
`else
  Vector#(MeshHeight, Vector#(MeshWidth, Router)) routers <- replicateM(replicateM(mkBaselineRouter));
`endif

  rule doInitialize(!inited);
    Bit#(1) isFullyInited = 1;

    for(Integer i=0; i< valueOf(MeshHeight); i=i+1) begin
      for(Integer j=0; j< valueOf(MeshWidth); j=j+1) begin
        isFullyInited = (isFullyInited ==1 && routers[i][j].isInited())? 1: 0;
      end
    end

    inited <= (isFullyInited == 1)? True:False;
  endrule

/* Interconnection among mesh nodes */
//Horizontal connections; W->E and E->W
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin

    // W->E
    for(Integer j=0; j<valueOf(MeshWidth)-1; j=j+1) begin
      //Flit link
      mkConnection(routers[i][j].dataLinks[dIdxEast].getFlit, 
                     routers[i][j+1].dataLinks[dIdxWest].putFlit);

      //Credit link
      mkConnection(routers[i][j].controlLinks[dIdxEast].getCredit, 
                     routers[i][j+1].controlLinks[dIdxWest].putCredit);
    end

    // E->W
    for(Integer j=1; j<valueOf(MeshWidth); j=j+1) begin
      //Flit link
      mkConnection(routers[i][j].dataLinks[dIdxWest].getFlit, 
                     routers[i][j-1].dataLinks[dIdxEast].putFlit);

      //Credit link
      mkConnection(routers[i][j].controlLinks[dIdxWest].getCredit, 
                   routers[i][j-1].controlLinks[dIdxEast].putCredit);
    end
  end

  //Vertical connections; N->S and S->N
  for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
    // N->S
    for(Integer i=0; i<valueOf(MeshHeight)-1; i=i+1) begin
      //Flit link
      mkConnection(routers[i][j].dataLinks[dIdxSouth].getFlit, 
                     routers[i+1][j].dataLinks[dIdxNorth].putFlit);

      //Credit link
      mkConnection(routers[i][j].controlLinks[dIdxSouth].getCredit, 
                     routers[i+1][j].controlLinks[dIdxNorth].putCredit);
    end

    // S->N
    for(Integer i=1; i<valueOf(MeshHeight); i=i+1)
    begin
      //Flit link
      mkConnection(routers[i][j].dataLinks[dIdxNorth].getFlit, 
                     routers[i-1][j].dataLinks[dIdxSouth].putFlit);

      //Credit link
      mkConnection(routers[i][j].controlLinks[dIdxNorth].getCredit, 
                     routers[i-1][j].controlLinks[dIdxSouth].putCredit);
    end
  end

`ifdef SMART
  /* SSR Links */
  //Between SSR manager and Router
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin

    // W->E
    mkConnection(routers[i][j].controlLinks[dIdxEast].getSSR,
                   horizontal_SSR_Managers[i][j].routerChannel[0].putSSR);

    mkConnection(routers[i][j].controlLinks[dIdxEast].putSSRs,
                   horizontal_SSR_Managers[i][j].routerChannel[0].getSSRs);

    // E->W
    mkConnection(routers[i][j].controlLinks[dIdxWest].getSSR,
                   horizontal_SSR_Managers[i][j].routerChannel[1].putSSR);

    mkConnection(routers[i][j].controlLinks[dIdxWest].putSSRs,
                   horizontal_SSR_Managers[i][j].routerChannel[1].getSSRs);

    // N->S
    mkConnection(routers[i][j].controlLinks[dIdxSouth].getSSR,
                   vertical_SSR_Managers[i][j].routerChannel[0].putSSR);

    mkConnection(routers[i][j].controlLinks[dIdxSouth].putSSRs,
                   vertical_SSR_Managers[i][j].routerChannel[0].getSSRs);

    // S->N
    mkConnection(routers[i][j].controlLinks[dIdxNorth].getSSR,
                   vertical_SSR_Managers[i][j].routerChannel[1].putSSR);

    mkConnection(routers[i][j].controlLinks[dIdxNorth].putSSRs,
                   vertical_SSR_Managers[i][j].routerChannel[1].getSSRs);
    end
  end

  //Between neighboring managers
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
    // W->E
    for(Integer j=0; j<valueOf(MeshWidth)-1; j=j+1) begin
      mkConnection(horizontal_SSR_Managers[i][j].managerChannel[0].getSSRs,
                     horizontal_SSR_Managers[i][j+1].managerChannel[0].putSSRs);
    end

    // E->W
    for(Integer j=1; j<valueOf(MeshWidth); j=j+1) begin
        mkConnection(horizontal_SSR_Managers[i][j].managerChannel[1].getSSRs,
                       horizontal_SSR_Managers[i][j-1].managerChannel[1].putSSRs);
    end
  end

  //Vertical connections; N->S and S->N
  for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
    // N->S
    for(Integer i=0; i<valueOf(MeshHeight)-1; i=i+1) begin
      mkConnection(vertical_SSR_Managers[i][j].managerChannel[0].getSSRs,
                     vertical_SSR_Managers[i+1][j].managerChannel[0].putSSRs);
    end

    // S->N
    for(Integer i=1; i<valueOf(MeshHeight); i=i+1) begin
        mkConnection(vertical_SSR_Managers[i][j].managerChannel[1].getSSRs,
                       vertical_SSR_Managers[i-1][j].managerChannel[1].putSSRs);
    end
  end

  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
    rule rl_removeEdgeSSRs_Left(inited);
      let sb <- horizontal_SSR_Managers[i][0].managerChannel[1].getSSRs;
    endrule

    rule rl_injectEdgeSSRs_Left(inited);
      SSRBundle dummy = replicate(0);
      horizontal_SSR_Managers[i][0].managerChannel[0].putSSRs(dummy);
    endrule


    rule rl_removeEdgeSSRs_Right(inited);
      let sb <- horizontal_SSR_Managers[i][fromInteger(valueOf(MeshWidth))-1].managerChannel[0].getSSRs;
    endrule

    rule rl_injectEdgeSSRs_Right(inited);
      SSRBundle dummy = replicate(0);
      horizontal_SSR_Managers[i][fromInteger(valueOf(MeshWidth))-1].managerChannel[1].putSSRs(dummy);
    endrule
  end

  for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
    rule rl_removeEdgeSSRs_Above(inited);
      let sb <- vertical_SSR_Managers[0][j].managerChannel[1].getSSRs;
    endrule

    rule rl_injectEdgeSSRs_Above(inited);
      SSRBundle dummy = replicate(0);
      vertical_SSR_Managers[0][j].managerChannel[0].putSSRs(dummy);
    endrule

    rule rl_removeEdgeSSRs_Below(inited);
      let sb <- vertical_SSR_Managers[fromInteger(valueOf(MeshHeight))-1][j].managerChannel[0].getSSRs;
    endrule

    rule rl_injectEdgeSSRs_Below(inited);
      SSRBundle dummy = replicate(0);
      vertical_SSR_Managers[fromInteger(valueOf(MeshHeight))-1][j].managerChannel[1].putSSRs(dummy);
    endrule
  end
`endif

/* External Interfaces */
  Vector#(MeshHeight, Vector#(MeshWidth, NetworkOuterInterface)) extInfc = newVector;
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
      extInfc[i][j] = 
        interface NetworkOuterInterface                
          method Action putFlit(Flit flit) if(inited);
            routers[i][j].dataLinks[dIdxLocal].putFlit(flit);
          endmethod

          method ActionValue#(Flit) getFlit if(inited);
            let flit <- routers[i][j].dataLinks[dIdxLocal].getFlit;
            return flit;
          endmethod

          method Action putCredit(CreditSignal crd);
            routers[i][j].controlLinks[dIdxLocal].putCredit(crd);
          endmethod

          method ActionValue#(CreditSignal) getCredit; 
            let credit <- routers[i][j].controlLinks[dIdxLocal].getCredit;
            return credit;  
          endmethod
        endinterface;
    end
  end
  interface ntkPorts = extInfc;

  method Bool isInited;
    return inited;
  endmethod

endmodule


