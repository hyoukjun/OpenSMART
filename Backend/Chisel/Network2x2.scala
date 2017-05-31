package SMART
import Chisel._

class Network2x2() extends Module {
    val io = new Bundle {
        val localFlitIn = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {new Flit().asInput}
        val localFlitInValid = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {Bool(INPUT)}

        val localFlitOut = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {new Flit().asOutput}
        val localFlitOutValid = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {Bool(OUTPUT)}

        val localIncCreditIn = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {Bool(INPUT)}
        val localIncCreditInVcid = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {UInt(INPUT, width = VCID_WIDTH)}

        val localIncCreditOut = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {Bool(OUTPUT)}
        val localIncCreditOutVcid = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {UInt(OUTPUT, width = VCID_WIDTH)}
    }
    val routers = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) {Module(new Router()).io}

    // assume router id assigned like this:
    //  2 ------ 3
    //  |        |
    //  0 ------ 1

    // vertical connections

            routers(2).incCurrCredit(SOUTH_) := routers(0).incPrevCredit(NORTH_)
            routers(2).incCurrCreditVcid(SOUTH_) := routers(0).incPrevCreditVcid(NORTH_)

            routers(0).flitIn(NORTH_) := routers(2).flitOut(SOUTH_)
            routers(0).flitInValid(NORTH_) := routers(2).flitOutValid(SOUTH_)

            routers(2).flitIn(SOUTH_) := routers(0).flitOut(NORTH_)
            routers(2).flitInValid(SOUTH_) := routers(0).flitOutValid(NORTH_)

            routers(0).incCurrCredit(NORTH_) := routers(2).incPrevCredit(SOUTH_)
            routers(0).incCurrCreditVcid(NORTH_) := routers(2).incPrevCreditVcid(SOUTH_)


            routers(3).incCurrCredit(SOUTH_) := routers(1).incPrevCredit(NORTH_)
            routers(3).incCurrCreditVcid(SOUTH_) := routers(1).incPrevCreditVcid(NORTH_)

            routers(1).flitIn(NORTH_) := routers(3).flitOut(SOUTH_)
            routers(1).flitInValid(NORTH_) := routers(3).flitOutValid(SOUTH_)

            routers(3).flitIn(SOUTH_) := routers(1).flitOut(NORTH_)
            routers(3).flitInValid(SOUTH_) := routers(1).flitOutValid(NORTH_)

            routers(1).incCurrCredit(NORTH_) := routers(3).incPrevCredit(SOUTH_)
            routers(1).incCurrCreditVcid(NORTH_) := routers(3).incPrevCreditVcid(SOUTH_)


    // horizontal connections
            routers(0).incCurrCredit(EAST_) := routers(1).incPrevCredit(WEST_)
            routers(0).incCurrCreditVcid(EAST_) := routers(1).incPrevCreditVcid(WEST_)

            routers(0).flitIn(EAST_) := routers(1).flitOut(WEST_)
            routers(0).flitInValid(EAST_) := routers(1).flitOutValid(WEST_)

            routers(1).flitIn(WEST_) := routers(0).flitOut(EAST_)
            routers(1).flitInValid(WEST_) := routers(0).flitOutValid(EAST_)

            routers(0).incCurrCredit(WEST_) := routers(1).incPrevCredit(EAST_)
            routers(0).incCurrCreditVcid(WEST_) := routers(1).incPrevCreditVcid(EAST_)


            routers(2).incCurrCredit(EAST_) := routers(3).incPrevCredit(WEST_)
            routers(2).incCurrCreditVcid(EAST_) := routers(3).incPrevCreditVcid(WEST_)

            routers(2).flitIn(EAST_) := routers(3).flitOut(WEST_)
            routers(2).flitInValid(EAST_) := routers(3).flitOutValid(WEST_)

            routers(3).flitIn(WEST_) := routers(2).flitOut(EAST_)
            routers(3).flitInValid(WEST_) := routers(2).flitOutValid(EAST_)

            routers(2).incCurrCredit(WEST_) := routers(3).incPrevCredit(EAST_)
            routers(2).incCurrCreditVcid(WEST_) := routers(3).incPrevCreditVcid(EAST_)

    // local connections
    for (i <- 0 until NETWORK_SIZE) {
        for (j <- 0 until NETWORK_SIZE) {
            io.localIncCreditOut(i+j*NETWORK_SIZE) := routers(i+j*NETWORK_SIZE).incPrevCredit(LOCAL_)
            io.localIncCreditOutVcid(i+j*NETWORK_SIZE) := routers(i+j*NETWORK_SIZE).incPrevCreditVcid(LOCAL_)
            io.localFlitOut(i+j*NETWORK_SIZE) := routers(i+j*NETWORK_SIZE).flitOut(LOCAL_)
            io.localFlitOutValid(i+j*NETWORK_SIZE) := routers(i+j*NETWORK_SIZE).flitOutValid(LOCAL_)

            routers(i+j*NETWORK_SIZE).flitIn(LOCAL_) := io.localFlitIn(i+j*NETWORK_SIZE)
            routers(i+j*NETWORK_SIZE).flitInValid(LOCAL_) :=  io.localFlitInValid(i+j*NETWORK_SIZE)
            routers(i+j*NETWORK_SIZE).incCurrCredit(LOCAL_) :=  io.localIncCreditIn(i+j*NETWORK_SIZE)
            routers(i+j*NETWORK_SIZE).incCurrCreditVcid(LOCAL_) :=  io.localIncCreditInVcid(i+j*NETWORK_SIZE)
        }
    }
    // zero vertical connections
    for (i <- 0 until NETWORK_SIZE) {
        routers(i).incCurrCredit(SOUTH_) := Bool(false)
        routers(i).incCurrCreditVcid(SOUTH_) := UInt(0)
        routers(i).flitIn(SOUTH_).init()
        routers(i).flitInValid(SOUTH_) := Bool(false)

        routers(NETWORK_SIZE-i).incCurrCredit(NORTH_) := Bool(false)
        routers(NETWORK_SIZE-i).incCurrCreditVcid(NORTH_) := UInt(0)
        routers(NETWORK_SIZE-i).flitIn(NORTH_).init()
        routers(NETWORK_SIZE-i).flitInValid(NORTH_) := Bool(false)
    }

    for (j <- 0 until NETWORK_SIZE) {
        routers(j*NETWORK_SIZE).incCurrCredit(WEST_) := Bool(false)
        routers(j*NETWORK_SIZE).incCurrCreditVcid(WEST_) := UInt(0)
        routers(j*NETWORK_SIZE).flitIn(WEST_).init()
        routers(j*NETWORK_SIZE).flitInValid(WEST_) := Bool(false)

        routers(j*NETWORK_SIZE+NETWORK_SIZE-1).incCurrCredit(EAST_) := Bool(false)
        routers(j*NETWORK_SIZE+NETWORK_SIZE-1).incCurrCreditVcid(EAST_) := UInt(0)
        routers(j*NETWORK_SIZE+NETWORK_SIZE-1).flitIn(EAST_).init()
        routers(j*NETWORK_SIZE+NETWORK_SIZE-1).flitInValid(EAST_) := Bool(false)
    }

    when (reset) {
        for (i <- 0 until NETWORK_SIZE) {
            for (j <- 0 until NETWORK_SIZE) {
                for (dir <- 0 until NUM_OF_DIRS) {
                    routers(i+j*NETWORK_SIZE).incCurrCredit(dir) := Bool(false)
                    routers(i+j*NETWORK_SIZE).incCurrCreditVcid(dir) := UInt(0)
                    routers(i+j*NETWORK_SIZE).flitIn(dir).init()
                    routers(i+j*NETWORK_SIZE).flitInValid(dir) := Bool(false)
                }
                io.localIncCreditOut(i+j*NETWORK_SIZE) := Bool(false)
                io.localIncCreditOutVcid(i+j*NETWORK_SIZE) := UInt(0)
                io.localFlitOut(i+j*NETWORK_SIZE).init()
                io.localFlitOutValid(i+j*NETWORK_SIZE) := Bool(false)
            }
        }
    }
}



class Network2x2Tests(c: Network2x2) extends Tester(c) {
    val flit_in_count = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) { Reg(init = UInt(0, width = 32))}  
    val flit_out_count = Vec.fill(NETWORK_SIZE*NETWORK_SIZE) { Reg(init = UInt(0, width = 32)) }

    val cycles = 10
    val src_node = 0
    val dest_node = NETWORK_SIZE*NETWORK_SIZE - 1

    // sending node from 0 to 3
    for (i <- 0 until cycles) {
        poke(c.io.localFlitInValid(src_node),1)
        poke(c.io.localFlitIn(src_node).header.isHead,1)
        poke(c.io.localFlitIn(src_node).header.isTail,1)
        poke(c.io.localFlitIn(src_node).header.xHops,NETWORK_SIZE-2)
        poke(c.io.localFlitIn(src_node).header.yHops,NETWORK_SIZE-1)
        poke(c.io.localFlitIn(src_node).header.xDir,NORTH_INT)
        poke(c.io.localFlitIn(src_node).header.yDir,EAST_INT)
        poke(c.io.localFlitIn(src_node).header.outport,EAST_INT)
        poke(c.io.localFlitIn(src_node).header.vcid,0)

        for (node <- 0 until NETWORK_SIZE*NETWORK_SIZE) {
            //poke(c.io.localIncCreditIn(node), c.io.localFlitOutValid(node))
            //poke(c.io.localIncCreditInVcid(node), c.io.localFlitOutVcid(node))
            flit_out_count(node) := flit_out_count(node) + c.io.localFlitOutValid(node).toUInt()
            flit_in_count(node) := flit_out_count(node) + c.io.localFlitInValid(node).toUInt()
        }
    }

    for (i <- 0 until cycles) {
        peek(c.io.localFlitOut(NETWORK_SIZE*NETWORK_SIZE-1))
    }


}