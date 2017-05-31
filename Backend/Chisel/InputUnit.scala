package SMART
import Chisel._

// One InputUnit PER DIRECTION
class InputUnit extends Module {
    val io = new Bundle {
      
        // Inputs from prev Router
        val flitIn        =  new Flit().asInput
        val flitInValid   = Bool(INPUT).asInput
        
        // Inputs from VCStateUnit
        val flitOutReady  = Bool(INPUT)
        //val vcidOut       = UInt(INPUT, width = VCID_WIDTH).asOutput
                
        // Outputs
        val flitOutValid = Vec.fill(NUM_OF_VC) {Bool(OUTPUT)} 
        // flitOut is a vector (for peeking)
        val flitOut = Vec.fill(NUM_OF_VC) {new Flit().asOutput}
    }
    // submodule initialization
    val vc = Vec.fill(NUM_OF_VC) {
        // flow = true mean that this is a bypass fifo
        Module(new Queue(entries = INPUT_BUFFER_DEPTH, flow = false, gen = UInt(width = DATA_WIDTH))).io
    }

    val headerQueue = Vec.fill(NUM_OF_VC) {
        Module(new Queue(entries = 1, flow = false, gen = new FlitHeader())).io
    }

    val arbiter = Module(new MatrixArbiter(n = NUM_OF_VC)).io

    arbiter.enable := UInt(1)

    arbiter.requests := io.flitOutValid.toBits().toUInt()

    // VC wiring
    for (i <- 0 until NUM_OF_VC) {
        vc(i).enq.valid := (UInt(i) === io.flitIn.header.vcid) && io.flitInValid
        // dequeue the flit if it wins invc arbitration & the direction is clear
        vc(i).deq.ready := arbiter.grants(i) && io.flitOutReady
        vc(i).enq.bits := io.flitIn.data

        // enqueue the header if head flit is enqueueing
        headerQueue(i).enq.valid := vc(i).enq.valid && io.flitIn.header.isHead
        // dequeue the header if a tail flit is dequeueing
        headerQueue(i).deq.ready := vc(i).deq.ready && headerQueue(i).deq.bits.isTail
        headerQueue(i).enq.bits := io.flitIn.header

        io.flitOut(i).data := vc(i).deq.bits
        io.flitOut(i).header := headerQueue(i).deq.bits
        io.flitOutValid(i) := vc(i).deq.valid && headerQueue(i).deq.valid
        assert(vc(i).count =/= UInt(INPUT_BUFFER_DEPTH), "VC overflow")
    }

}

class InputUnitTests(c: InputUnit) extends Tester(c) {
    poke(c.io.flitIn.data, 1)
    poke(c.io.flitIn.header.vcid, 0)
    poke(c.io.flitIn.header.isHead, 1)
    poke(c.io.flitInValid, 1)
    poke(c.io.flitOutReady, 0)
    //poke(c.io.vcidOut, 0)
    peek(c.io)
    peek(c.arbiter.grants)
    peek(c.vc(0).deq.ready)
    step(1)

    poke(c.io.flitIn.data, 2)
    poke(c.io.flitIn.header.vcid, 0)
    poke(c.io.flitIn.header.isHead, 0)
    poke(c.io.flitIn.header.isTail, 1)
    poke(c.io.flitInValid, 1)
    poke(c.io.flitOutReady, 1)
    //poke(c.io.vcidOut, 0)
    peek(c.io)
        peek(c.arbiter.grants)
            peek(c.vc(0).deq.ready)

    step(1)

    poke(c.io.flitIn.data, 3)
    poke(c.io.flitIn.header.vcid, 0)
    poke(c.io.flitIn.header.isHead, 0)
    poke(c.io.flitInValid, 0)
    poke(c.io.flitOutReady, 1)
    //poke(c.io.vcidOut, 0)
    peek(c.io)
            peek(c.arbiter.grants)
                peek(c.vc(0).deq.ready)


    step(1)

    poke(c.io.flitIn.data, 3)
    poke(c.io.flitIn.header.vcid, 0)
    poke(c.io.flitIn.header.isHead, 0)
    poke(c.io.flitInValid, 0)
    poke(c.io.flitOutReady, 0)
    //poke(c.io.vcidOut, 0)
    peek(c.io)
            peek(c.arbiter.grants)

    step(1)


}