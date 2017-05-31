package SMART

import Chisel._

// CURRENTLY OBSOLETE
class VirtualChannel extends Module {
    val io = new Bundle {
        val flitDataIn = UInt(INPUT, width = DATA_WIDTH)
        val flitInValid = Bool(INPUT)
        val flitOutReady = Bool(INPUT) // if the pipeline is ready for next flit out of the fifo

        val flitDataOut = UInt(OUTPUT, width = DATA_WIDTH)
        val flitOutValid = Bool(OUTPUT)
        val flitInReady = Bool(OUTPUT) // if the fifo is ready to take the next input flit
    }
    val fifo = Module(new Queue(entries = INPUT_BUFFER_DEPTH, gen = UInt(width=DATA_WIDTH))).io
    fifo.enq.valid := io.flitInValid
    // fifo.deq.ready := io.flitOutReady && (io.creditCount != 0 || io.incCredit)
    fifo.deq.ready := io.flitOutReady // credit availability check is not done here 
    fifo.enq.bits := io.flitDataIn
    io.flitInReady := fifo.enq.ready
    io.flitOutValid := fifo.deq.valid
    io.flitDataOut := fifo.deq.bits
}

class VCTests(c: VirtualChannel) extends Tester(c) {

}