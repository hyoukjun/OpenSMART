package SMART
import Chisel._

// still need to fix credit management performance issue
class Router() extends Module {
    val io = new Bundle {
        // to prev router
        val incPrevCredit = Vec.fill(NUM_OF_DIRS) {Bool(OUTPUT)}
        val incPrevCreditVcid = Vec.fill(NUM_OF_DIRS) {UInt(OUTPUT, width = VCID_WIDTH)}
        // from prev router
        val flitIn = Vec.fill(NUM_OF_DIRS) {new Flit().asInput}
        val flitInValid = Vec.fill(NUM_OF_DIRS) {Bool(INPUT)}
        // to next router
        val flitOut = Vec.fill(NUM_OF_DIRS) {new Flit().asOutput}
        val flitOutValid = Vec.fill(NUM_OF_DIRS) {Bool(OUTPUT)}
        // from next router
        val incCurrCredit = Vec.fill(NUM_OF_DIRS) {Bool(INPUT)}
        val incCurrCreditVcid = Vec.fill(NUM_OF_DIRS) {UInt(INPUT, width = VCID_WIDTH)}
    }

    // sub-module instantiation
    val IU =  Vec.fill(NUM_OF_DIRS) {Module(new InputUnit()).io}
    val VCSU = Module(new VCStateUnit()).io
    val SAI = Module(new InvcArbiter()).io
    val SA = Module(new SwitchAllocator(NumInports = NUM_OF_DIRS, NumOutports = NUM_OF_DIRS)).io
    val VA = Module(new VCAllocator()).io
    val RU = Vec.fill(NUM_OF_DIRS) {Module(new RoutingUnit()).io}
    val XBAR = Module(new Crossbar(NumInports = NUM_OF_DIRS, NumOutports = NUM_OF_DIRS)).io

    // internal signals

    // To InvcArbiter (SAI)
    for (i <- 0 until NUM_OF_DIRS) {
        for (vc <- 0 until NUM_OF_VC) {
            SAI.flitInValid(i)(vc) := VCSU.saiFlitInValid(i)(vc)
            SAI.flitIn(i)(vc) := VCSU.saiFlitIn(i)(vc)
        }
    }

    // to VCAllocator (VA)
    for (i <- 0 until NUM_OF_DIRS) {
        // static vc allocation
        VA.vcidIn(i) := SAI.vcidOut(i)
        // for (vc <- 0 until NUM_OF_VC) {
        //     VA(i).creditIncIn(vc) := io.incCurrCredit(i) && (io.incCurrCreditVcid(i) === UInt(vc))
        // }
    }

    // to credit management 
    val CreditRegs = Vec.fill(NUM_OF_DIRS) {Vec.fill(NUM_OF_VC) {Module(new CreditReg()).io}}
    val creditGrants = Vec.fill(NUM_OF_DIRS) {Bool()}

    for (i <- 0 until NUM_OF_DIRS) {
        for (vc <- 0 until NUM_OF_VC) {
            CreditRegs(i)(vc).inc := io.incCurrCredit(i) && (io.incCurrCreditVcid(i) === UInt(vc))
            // timing here is delicate... effect on buffer turnaround time
            // vc here might be the wrong vc
            CreditRegs(i)(vc).dec := orR(SA.grants(i)) && (VA.vcidOut(i) === UInt(vc))
        }
        creditGrants(i) := CreditRegs(i)(VA.vcidOut(i)).creditOut != UInt(0)
    }

    // to SwitchAllocator (SA)
    SA.enable := UInt(1)
    for (i <- 0 until NUM_OF_DIRS) {
        when (VA.vcidOutValid(i)) {
            SA.requests(i) := SAI.flitOut(i).header.outport
        } .otherwise {
            SA.requests(i) := UInt(0)
        }
    }
    val saGrantsInportsVec = Vec.fill(NUM_OF_DIRS) { Vec.fill(NUM_OF_DIRS) {Bool()} }
    val saGrantsInports = Vec.fill(NUM_OF_DIRS) {Bool()}
    for (inport <- 0 until NUM_OF_DIRS) {
        for (outport <- 0 until NUM_OF_DIRS) {
            // this signal includes CREDIT information
            saGrantsInportsVec(inport)(outport) := SA.grants(outport)(inport) && creditGrants(outport)
        }
    }
    for (i <- 0 until NUM_OF_DIRS) {
        saGrantsInports(i) := orR(saGrantsInportsVec(i).toBits())
    }

    // // defining control registers
    val flitOutReadyReg = Vec.fill(NUM_OF_DIRS) {Reg(init = Bool(false))}
    val vcidOutReg = Vec.fill(NUM_OF_DIRS) {Reg(init = UInt(x = 0, width = VCID_WIDTH))}
    flitOutReadyReg := saGrantsInports
    vcidOutReg := SAI.vcidOut

    // To InputUnit (IU)
    for (i <- 0 until NUM_OF_DIRS) {
        IU(i).flitIn := io.flitIn(i)
        IU(i).flitInValid := io.flitInValid(i)
        IU(i).flitOutReady := saGrantsInports(i) 
        IU(i).vcidOut := SAI.vcidOut(i)
    }


    // To VCStateUnit (VCSU)
    for (i <- 0 until NUM_OF_DIRS) {
        for (j <- 0 until NUM_OF_VC) {
            VCSU.iuFlitOut(i)(j) := ( IU(i).flitOut(j) ) // try to fix the type mismatch bug
            VCSU.iuFlitOutValid(i)(j) := IU(i).flitOutValid(j)
        }
        VCSU.saiVcidOut(i) := SAI.vcidOut(i)
        VCSU.flitOutReady(i) := saGrantsInports(i)
    }

    // defining Xbar registers
    val xbarGrantReg = Vec.fill(NUM_OF_DIRS) {Reg(init = UInt(width = NUM_OF_DIRS, x = 0)) } 
    val xbarFlitInReg = Vec.fill(NUM_OF_DIRS) { Reg(init = new Flit()) }

    // to XbarReg
    xbarGrantReg := SA.grants
    for (i <- 0 until NUM_OF_DIRS) {
        xbarFlitInReg(i).data := SAI.flitOut(i).data
        // new header generation
        xbarFlitInReg(i).header.isHead := SAI.flitOut(i).header.isHead
        xbarFlitInReg(i).header.isTail := SAI.flitOut(i).header.isTail
        xbarFlitInReg(i).header.xDir := RU(i).xDirNext
        xbarFlitInReg(i).header.yDir := RU(i).yDirNext
        xbarFlitInReg(i).header.xHops := RU(i).xHopsNext
        xbarFlitInReg(i).header.yHops := RU(i).yHopsNext
        xbarFlitInReg(i).header.outport := RU(i).outport
        xbarFlitInReg(i).header.vcid := VA.vcidOut(i)
    }

    // to Xbar
    for (i <- 0 until NUM_OF_DIRS) {
        XBAR.grants(i) := xbarGrantReg(i)
        XBAR.flitIn(i) := xbarFlitInReg(i)
    }


    // to RoutingUnit (RU)
    for (i <- 0 until NUM_OF_DIRS) {
        RU(i).xHops := SAI.flitOut(i).header.xHops
        RU(i).yHops := SAI.flitOut(i).header.yHops
        RU(i).xDir := SAI.flitOut(i).header.xDir
        RU(i).yDir := SAI.flitOut(i).header.yDir
    }

    // to next router
    io.flitOut := XBAR.flitOut
    io.flitOutValid := XBAR.outValid

    // to prev router
    for (i <- 0 until NUM_OF_DIRS) {
        io.incPrevCredit(i) := orR(flitOutReadyReg(i))
        // this assignment below is wrong if we are not using static VC allocation!
        io.incPrevCreditVcid(i) := vcidOutReg(i)
    }
}

class RouterTests(c: Router) extends Tester(c) {
    val flit_in_count = Reg(init = UInt(0, width = 32))
    val flit_out_count = Vec.fill(NUM_OF_DIRS) { Reg(init = UInt(0, width = 32)) } 

    val cycles = 100

    for (i <- 0 until cycles) {
        step(1)
        poke(c.io.flitIn(0).data, i)
        poke(c.io.flitIn(0).header.isHead, 1)
        poke(c.io.flitIn(0).header.isTail, 1)
        poke(c.io.flitIn(0).header.xHops, 2)
        poke(c.io.flitIn(0).header.yHops, 2)
        poke(c.io.flitIn(0).header.xDir, 1)
        poke(c.io.flitIn(0).header.yDir, 1)
        poke(c.io.flitIn(0).header.outport, 4)
        poke(c.io.flitIn(0).header.vcid, 0)
        poke(c.io.flitInValid(0), 1)
        poke(c.io.incCurrCreditVcid(3), 0)

        for (j <- 0 until NUM_OF_DIRS) {
            if (peek(c.io.flitOutValid(j)) == 1) {
                flit_out_count(j) := flit_out_count(j) + UInt(1)
                poke(c.io.incCurrCredit(j), 1)
            }
        }

    }
    for (i <- 0 until NUM_OF_DIRS) {
        print(flit_out_count(i))

    }

}