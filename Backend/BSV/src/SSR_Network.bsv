import Vector::*;

import Types::*;
import MessageTypes::*;
import SmartTypes::*;
import CreditTypes::*;
import RoutingTypes::*;

import SSR_Router::*; 
import Connectable::*;


interface SSR_Network;
  interface  Vector#(MeshHeight, Vector#(MeshWidth, Vector#(NumNormalPorts, InterRouter))) routerChannel;
endinterface

(* synthesize *)
module mkSSR_Network(SSR_Network);

  Reg#(Bool) inited <- mkReg(False);
  Vector#(MeshHeight, Vector#(MeshWidth, SSR_Router)) ssrRouters <- replicateM(replicateM(mkSSR_Router));


  /********** Initialization **********/
  rule rl_doInit(!inited);
    inited <= True;
  endrule

  for(Integer i=0; i<valueOf(MeshHeight); i=i+1)  begin
    rule rl_doInit_LR(!inited); //Left and Right side
      ssrRouters[i][0].controlChannel[dIdxWest].setBorder;
      ssrRouters[i][fromInteger(valueOf(MeshWidth))-1].controlChannel[dIdxEast].setBorder;
    endrule
  end

  for(Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
    rule rl_doInit_AB(!inited); //Above and Below side
      ssrRouters[0][j].controlChannel[dIdxNorth].setBorder;
      ssrRouters[fromInteger(valueOf(MeshHeight))-1][j].controlChannel[dIdxSouth].setBorder;
    endrule
  end


  /********** SSR link connection **********/
  //W->E
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1)  begin
    for(Integer j=0; j<valueOf(MeshWidth)-1; j=j+1)  begin
      mkConnection(ssrRouters[i][j].managerChannel[dIdxEast].getSSRs,
                     ssrRouters[i][j+1].managerChannel[dIdxWest].putSSRs);
    end
  end

  //E->W
  for(Integer i=0; i<valueOf(MeshHeight); i=i+1)  begin
    for(Integer j=1; j<valueOf(MeshWidth); j=j+1)  begin
      mkConnection(ssrRouters[i][j].managerChannel[dIdxWest].getSSRs,
                     ssrRouters[i][j-1].managerChannel[dIdxEast].putSSRs);
    end
  end

  //N->S
  for(Integer i=0; i<valueOf(MeshHeight)-1; i=i+1)  begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1)  begin
      mkConnection(ssrRouters[i][j].managerChannel[dIdxSouth].getSSRs,
                     ssrRouters[i+1][j].managerChannel[dIdxNorth].putSSRs);
    end
  end

  //S->N
  for(Integer i=1; i<valueOf(MeshHeight); i=i+1)  begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1)  begin
      mkConnection(ssrRouters[i][j].managerChannel[dIdxNorth].getSSRs,
                     ssrRouters[i-1][j].managerChannel[dIdxSouth].putSSRs);
    end
  end



  /********** Interfaces **********/
  Vector#(MeshHeight, Vector#(MeshWidth, Vector#(NumNormalPorts, InterRouter))) routerChannelDummy = newVector;

  for(Integer i=0; i<valueOf(MeshHeight); i=i+1)  begin
    for(Integer j=0; j<valueOf(MeshWidth); j=j+1)  begin
      for(Integer prt=0; prt<valueOf(NumNormalPorts); prt=prt+1) begin
        routerChannelDummy[i][j][prt] = 
          interface InterRouter
          
            method Action putSSR(SSR ssr);
              ssrRouters[i][j].routerChannel[prt].putSSR(ssr);
            endmethod

            method ActionValue#(SSRBundle) getSSRs;  
              let ret <- ssrRouters[i][j].routerChannel[prt].getSSRs;
              return ret;
            endmethod

          endinterface;
      end
    end
  end

  interface routerChannel = routerChannelDummy;

endmodule
