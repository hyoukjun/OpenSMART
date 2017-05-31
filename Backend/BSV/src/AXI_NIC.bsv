import Fifo::*;

import AXI_Types::*;
import Types::*;
import MessageTypes::*; 


/*
  This is a frame of AXI interface with minimal NIC functionality. Please change the contents of the functions for your target systems.
*/

interface AXI_Interface;
  /* Write Address  */
  method Action axi_putWrAddr(AXI_WriteAddr writeAddr);
  method ActionValue#(AXI_WriteAddr) axi_getWrAddr;
  /* Write Data */
  method Action axi_putWrData(AXI_WriteData writeData);
  method ActionValue#(AXI_WriteData) axi_getWrData;

  /* Write Response */
  method Action axi_putWrResp(AXI_WriteResponse writeResponse);
  method ActionValue#(AXI_WriteResponse) axi_getWrResp;


  /* Read Address */
  method Action axi_putRdAddr(AXI_ReadAddress readAddress);
  method ActionValue#(AXI_ReadAddress) axi_getRdAddr;

  /* Read Data */
  method Action axi_putRdData(AXI_ReadData readData);
  method ActionValue#(AXI_ReadData) axi_getRdData;

  method ActionValue#(Flit) getFlit;
  method Action putFlit(Flit flit);
endinterface


(* synthesize *)
module mkAXINIC(AXI_Interface);
  Fifo#(1, AXI_WriteAddr) wrAddrIn <- mkPipelineFifo;
  Fifo#(1, AXI_WriteAddr) wrAddrOut <- mkPipelineFifo;
  
  Fifo#(1, AXI_WriteData) wrDataIn <- mkPipelineFifo;
  Fifo#(1, AXI_WriteData) wrDataOut <- mkPipelineFifo;

  Fifo#(1, AXI_WriteResponse) wrRespIn <- mkPipelineFifo;
  Fifo#(1, AXI_WriteResponse) wrRespOut <- mkPipelineFifo;

  Fifo#(1, AXI_ReadAddress) rdAddrIn <- mkPipelineFifo;
  Fifo#(1, AXI_ReadAddress) rdAddrOut <- mkPipelineFifo;

  Fifo#(1, AXI_ReadData) rdDataIn <- mkPipelineFifo;
  Fifo#(1, AXI_ReadData) rdDataOut <- mkPipelineFifo;

  Fifo#(1, Flit) flitIn <- mkPipelineFifo;
  Fifo#(1, Flit) flitOut <- mkPipelineFifo;

  rule wrAddrFlit(wrAddrIn.notEmpty);
    AXI_WriteAddr wrAddr = wrAddrIn.first;
    wrAddrIn.deq;

    let addrData = pack(wrAddr);

    Flit flit = ?;
    flit.flitData = truncate(addrData);

    flitOut.enq(flit);
  endrule

  rule wrDataFlit(wrDataIn.notEmpty);
    AXI_WriteData wrData = wrDataIn.first;
    wrDataIn.deq;

    let addrData = pack(wrData);

    Flit flit = ?;
    flit.flitData = truncate(addrData);
    flitOut.enq(flit);
  endrule

  rule wrRespFlit(wrRespIn.notEmpty);
    AXI_WriteResponse wrResp = wrRespIn.first;
    wrRespIn.deq;

    let respData= pack(wrResp);

    Flit flit = ?;
    flit.flitData = zeroExtend(respData);
    flitOut.enq(flit);
  endrule

  rule rdAddrFlit(rdAddrIn.notEmpty);
    AXI_ReadAddress rdAddr = rdAddrIn.first;
    rdAddrIn.deq;

    let rdAddrData= pack(rdAddr);

    Flit flit = ?;
    flit.flitData = truncate(rdAddrData);
    flitOut.enq(flit);
  endrule

  rule rdDataFlit(rdDataIn.notEmpty);
    AXI_ReadData rdData = rdDataIn.first;
    rdDataIn.deq;

    let rdDataData = pack(rdData);

    Flit flit = ?;
    flit.flitData = truncate(rdDataData);
    flitOut.enq(flit);
  endrule

  rule processFlit(flitIn.notEmpty);
    Flit flit = flitIn.first;
    flitIn.deq;
    //An example of fixed vc for each data class
    case(flit.vc)
      0: begin   
        let wrAddr = ?;
        wrAddr.awaddr = truncate(flit.flitData);
        wrAddrOut.enq(wrAddr);
      end

      1: begin   
        let wrData = ?;
        wrData.wdata = flit.flitData;
        wrDataOut.enq(wrData);
      end 
      
      2: begin
        let wrResp = ?;
        wrResp.bresp = truncate(flit.flitData);
        wrRespOut.enq(wrResp);
      end

      3: begin
        let rdAddr = ?;
        rdAddr.araddr = truncate(flit.flitData);
        rdAddrOut.enq(rdAddr);
      end

      4: begin
        let rdData = ?;
        rdData.rdata = flit.flitData;
        rdDataOut.enq(rdData);
      end


    endcase

  endrule

  /* Write Address  */
  method Action axi_putWrAddr(AXI_WriteAddr writeAddr);
    wrAddrIn.enq(writeAddr);
  endmethod 

  method ActionValue#(AXI_WriteAddr) axi_getWrAddr;
    wrAddrOut.deq;
    return wrAddrOut.first;
  endmethod

  /* Write Data */
  method Action axi_putWrData(AXI_WriteData writeData);
    wrDataIn.enq(writeData);
  endmethod

  method ActionValue#(AXI_WriteData) axi_getWrData;
    wrDataOut.deq;
    return wrDataOut.first;
  endmethod

  /* Write Response */
  method Action axi_putWrResp(AXI_WriteResponse writeResponse);
    wrRespIn.enq(writeResponse);
  endmethod

  method ActionValue#(AXI_WriteResponse) axi_getWrResp;
    wrRespOut.deq;
    return wrRespOut.first;
  endmethod

  /* Read Address */
  method Action axi_putRdAddr(AXI_ReadAddress readAddress);
    rdAddrIn.enq(readAddress);
  endmethod

  method ActionValue#(AXI_ReadAddress) axi_getRdAddr;
    rdAddrOut.deq;
    return rdAddrOut.first;
  endmethod

  /* Read Data */
  method Action axi_putRdData(AXI_ReadData readData);
    rdDataIn.enq(readData);
  endmethod

  method ActionValue#(AXI_ReadData) axi_getRdData;
    rdDataOut.deq;
    return rdDataOut.first;
  endmethod

  method ActionValue#(Flit) getFlit;
    flitOut.deq;
    return flitOut.first;
  endmethod

  method Action putFlit(Flit flit);
    flitIn.enq(flit);
  endmethod 

endmodule

