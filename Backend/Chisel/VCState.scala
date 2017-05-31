package SMART
import Chisel._

class VCStateUnit extends Module {
    val io = new Bundle {

        // from InputUnit
        val iuFlitOutValid = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {Bool(INPUT)}}
        val iuFlitOut = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {new Flit().asInput}}

        // to InvcArbiter
        val saiFlitInValid = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {Bool(OUTPUT)}}
        val saiFlitIn = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {new Flit().asOutput}}

        // from InvcArbiter
        val saiVcidOut = Vec.fill(NUM_OF_DIRS) {UInt(INPUT, width = VCID_WIDTH)}

        // From the router
        val flitOutReady = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {Bool(INPUT)}}

    }
    // ----------------- VC States Management -------------------------

    // Enum does not work, not sure why
    //val VC_ACTIVE :: VC_EMPTY :: VC_IDLE :: Nil = Enum(UInt(), 3)
    //val vcStateReg = Vec.fill(NUM_OF_DIRS) { Vec.fill(NUM_OF_VC) {Reg(init = VC_IDLE)} }
    val flitHeaderReg = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {Reg(init = new FlitHeader())}}

    for (i <- 0 until NUM_OF_DIRS) {
        for (vc <- 0 until NUM_OF_VC) {
            io.saiFlitInValid(i)(vc) := io.iuFlitOutValid(i)(vc)
            io.saiFlitIn(i)(vc).data := io.iuFlitOut(i)(vc).data

            // note: the header has the WRONG isTail/isHead information of the flit IF
            //       it uses the header info from the reg!


            when (io.iuFlitOut(i)(vc).header.isHead) {
                io.saiFlitIn(i)(vc).header := io.iuFlitOut(i)(vc).header
            } .otherwise {
                io.saiFlitIn(i)(vc).header := flitHeaderReg(i)(vc)
            }

            when (io.iuFlitOut(i)(vc).header.isHead && !io.iuFlitOut(i)(vc).header.isTail ) {
                flitHeaderReg(i)(vc) := io.iuFlitOut(i)(vc).header
            }
        }
    }
    // -----------------------------------------------------
}

class VCStateUnitTests(c:VCStateUnit) extends Tester(c) {
    poke(c.io.iuFlitOutValid(0)(0),1)
    poke(c.io.iuFlitOut(0)(0).header.isHead, 1)
    poke(c.io.iuFlitOut(0)(0).header.isTail, 0)
    poke(c.io.iuFlitOut(0)(0).data, 123)
    poke(c.io.saiVcidOut(0), 0)
    poke(c.io.flitOutReady(0)(0), 0)
    peek(c.io.saiFlitIn(0)(0))

    step(1)

    poke(c.io.iuFlitOutValid(0)(0),1)
    poke(c.io.iuFlitOut(0)(0).header.isHead, 0)
    poke(c.io.iuFlitOut(0)(0).header.isTail, 0)
    poke(c.io.iuFlitOut(0)(0).data, 234)
    poke(c.io.saiVcidOut(0), 0)
    poke(c.io.flitOutReady(0)(0), 0)
    peek(c.io.saiFlitIn(0)(0))
}