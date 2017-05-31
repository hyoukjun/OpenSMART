package SMART
import Chisel._

// This is a static vc allocator, where vcidIn = vcidOut.
// currently VCA is NOT in charge of credit flow control any more!
class VCAllocator extends Module {
    val io = new Bundle {
        // val creditIncIn = Vec.fill(NUM_OF_VC) {Bool(INPUT)}
        // val creditCount = Vec.fill(NUM_OF_VC) {UInt(OUTPUT, width = CREDIT_WIDTH)}
        val vcidIn = Vec.fill(NUM_OF_DIRS) {UInt(INPUT, width = VCID_WIDTH)}
        val vcidOut = Vec.fill(NUM_OF_DIRS) {UInt(OUTPUT, width = VCID_WIDTH)}
        val vcidOutValid = Vec.fill(NUM_OF_DIRS) {Bool(OUTPUT)} 

        // val vcAvailable =  Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VCS) {Bool(INPUT)}}
    }

    // val creditRegs = Vec.fill(NUM_OF_VC) {Module(new CreditReg()).io}

    // for (i <- 0 until NUM_OF_VC) {
    //     creditRegs(i).inc := io.creditIncIn(i)
    //     creditRegs(i).dec := (io.vcidIn === UInt(i)) && io.vcidOutValid
    // }
    //io.vcidOutValid := (creditRegs(io.vcidOut).creditOut != UInt(0) || io.creditIncIn(io.vcidOut))

    for (i <- 0 until NUM_OF_DIRS) {
        io.vcidOutValid(i) := Bool(true)
        io.vcidOut(i) := io.vcidIn(i)
    }

}

class VCAllocatorTests(c: VCAllocator) extends Tester(c) {
    // vc1 request
    // poke(c.io.vcidIn, 0)
    // peek(c.io.vcidOut)
    // peek(c.io.vcidOutValid)

    // step(1)
    // poke(c.io.vcidIn, 0)
    // peek(c.io.vcidOut)
    // peek(c.io.vcidOutValid)
    // step(1)
    // poke(c.io.vcidIn, 0)
    // peek(c.io.vcidOut)
    // peek(c.io.vcidOutValid)
    // step(1)
    // poke(c.io.vcidIn, 0)
    // peek(c.io.vcidOut)
    // peek(c.io.vcidOutValid)
    // step(1)
    // poke(c.io.vcidIn, 0)
    // peek(c.io.vcidOut)
    // peek(c.io.vcidOutValid)
    // step(1)
    // poke(c.io.vcidIn, 0)
    // poke(c.io.creditIncIn(0), 1)
    // peek(c.io.vcidOut)
    // peek(c.io.vcidOutValid)

}