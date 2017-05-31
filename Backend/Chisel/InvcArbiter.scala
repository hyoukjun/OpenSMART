package SMART
import Chisel._


class InvcArbiter extends Module {
    val io = new Bundle {
        val flitInValid = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {Bool(INPUT)}}
        val flitIn = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {new Flit().asInput}}

        val flitOutValid = Vec.fill(NUM_OF_DIRS) {Bool(OUTPUT)}
        val flitOut = Vec.fill(NUM_OF_DIRS) {new Flit().asOutput}
        val vcidOut = Vec.fill(NUM_OF_DIRS) {UInt(OUTPUT, width = VCID_WIDTH)}
    }

    // ------------ Input VC Arbitration (SA-i) -------------

    val invcArbs = Vec.fill(NUM_OF_DIRS) {
        Module(new MatrixArbiter(n = NUM_OF_VC)).io
    }

    for (i <- 0 until NUM_OF_DIRS) {
        invcArbs(i).enable := UInt(1)
        invcArbs(i).requests := io.flitInValid(i).toBits().toUInt()

        when (PopCount(invcArbs(i).grants)!=UInt(0)) {
            io.vcidOut(i) := OHToUInt(invcArbs(i).grants)
            assert(io.flitInValid(i)(io.vcidOut(i))===Bool(true), "Flit must be valid when it passes invc arbitration")
            io.flitOutValid(i) := Bool(true)
        } .otherwise {
            io.flitOutValid(i) := Bool(false)
            io.vcidOut(i) := UInt(0)
        }
        io.flitOut(i) := io.flitIn(i)(io.vcidOut(i))
    }
}

class InvcArbiterTests(c: InvcArbiter) extends Tester(c) {
    poke(c.io.flitInValid(0)(0), 1)
    poke(c.io.flitInValid(0)(1), 1)
    poke(c.io.flitIn(0)(0).data, 1)
    poke(c.io.flitIn(0)(1).data, 2)
    peek(c.io.flitOutValid(0))
    peek(c.io.flitOut(0))
    peek(c.io.vcidOut(0))

    step(1)

    poke(c.io.flitInValid(0)(0), 1)
    poke(c.io.flitInValid(0)(1), 1)
    poke(c.io.flitIn(0)(0).data, 1)
    poke(c.io.flitIn(0)(1).data, 2)
    peek(c.io.flitOutValid(0))
    peek(c.io.flitOut(0))
    peek(c.io.vcidOut(0))

    step(1)

    poke(c.io.flitInValid(0)(0), 0)
    poke(c.io.flitInValid(0)(1), 1)
    poke(c.io.flitIn(0)(0).data, 1)
    poke(c.io.flitIn(0)(1).data, 2)
    peek(c.io.flitOutValid(0))
    peek(c.io.flitOut(0))
    peek(c.io.vcidOut(0))

    step(1)

    poke(c.io.flitInValid(0)(0), 0)
    poke(c.io.flitInValid(0)(1), 0)
    poke(c.io.flitIn(0)(0).data, 1)
    poke(c.io.flitIn(0)(1).data, 2)
    peek(c.io.flitOutValid(0))
    peek(c.io.flitOut(0))
    peek(c.io.vcidOut(0))

}