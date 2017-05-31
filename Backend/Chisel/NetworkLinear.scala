

package SMART
import Chisel._

class NetworkLinear() extends Module {
    val io = new Bundle {
        val localFlitIn = Vec.fill(NETWORK_SIZE) {new Flit().asInput}
        val localFlitInValid = Vec.fill(NETWORK_SIZE) {Bool(INPUT)}

        val localFlitOut = Vec.fill(NETWORK_SIZE) {new Flit().asOutput}
        val localFlitOutValid = Vec.fill(NETWORK_SIZE) {Bool(OUTPUT)}

        val localIncCreditIn = Vec.fill(NETWORK_SIZE) {Bool(INPUT)}
        val localIncCreditInVcid = Vec.fill(NETWORK_SIZE) {UInt(INPUT, width = VCID_WIDTH)}

        val localIncCreditOut = Vec.fill(NETWORK_SIZE) {Bool(OUTPUT)}
        val localIncCreditOutVcid = Vec.fill(NETWORK_SIZE) {UInt(OUTPUT, width = VCID_WIDTH)}
    }
    val routers = Vec.fill(NETWORK_SIZE) {Module(new Router()).io}

    // assume router id assigned like this:
    //  2 ------ 3
    //  |        |
    //  0 ------ 1

    // horizontal connections
            routers(0).incCurrCredit(EAST_) := routers(1).incPrevCredit(WEST_)
            routers(0).incCurrCreditVcid(EAST_) := routers(1).incPrevCreditVcid(WEST_)

            routers(0).flitIn(EAST_) := routers(1).flitOut(WEST_)
            routers(0).flitInValid(EAST_) := routers(1).flitOutValid(WEST_)

            routers(1).flitIn(WEST_) := routers(0).flitOut(EAST_)
            routers(1).flitInValid(WEST_) := routers(0).flitOutValid(EAST_)

            routers(0).incCurrCredit(WEST_) := routers(1).incPrevCredit(EAST_)
            routers(0).incCurrCreditVcid(WEST_) := routers(1).incPrevCreditVcid(EAST_)

    // local connections
    for (i <- 0 until NETWORK_SIZE) {
            io.localIncCreditOut(i) := routers(i).incPrevCredit(LOCAL_)
            io.localIncCreditOutVcid(i) := routers(i).incPrevCreditVcid(LOCAL_)
            io.localFlitOut(i) := routers(i).flitOut(LOCAL_)
            io.localFlitOutValid(i) := routers(i).flitOutValid(LOCAL_)

            routers(i).flitIn(LOCAL_) := io.localFlitIn(i)
            routers(i).flitInValid(LOCAL_) :=  io.localFlitInValid(i)
            routers(i).incCurrCredit(LOCAL_) :=  io.localIncCreditIn(i)
            routers(i).incCurrCreditVcid(LOCAL_) :=  io.localIncCreditInVcid(i)
    }
    // zero vertical connections
    for (i <- 0 until NETWORK_SIZE) {
        routers(i).incCurrCredit(SOUTH_) := Bool(false)
        routers(i).incCurrCreditVcid(SOUTH_) := UInt(0)
        routers(i).flitIn(SOUTH_).init()
        routers(i).flitInValid(SOUTH_) := Bool(false)

        routers(i).incCurrCredit(NORTH_) := Bool(false)
        routers(i).incCurrCreditVcid(NORTH_) := UInt(0)
        routers(i).flitIn(NORTH_).init()
        routers(i).flitInValid(NORTH_) := Bool(false)
    }
}



class NetworkLinearTests(c: NetworkLinear) extends Tester(c) {
    val flit_in_count = Vec.fill(NETWORK_SIZE) { Reg(init = UInt(0, width = 32))}  
    val flit_out_count = Vec.fill(NETWORK_SIZE) { Reg(init = UInt(0, width = 32)) }

    val cycles = 10
    val src_node = 0
    val dest_node = NETWORK_SIZE - 1

    // sending node from 0 to 3
    for (i <- 0 until cycles) {
        poke(c.io.localFlitInValid(src_node),1)
        poke(c.io.localFlitIn(src_node).header.isHead,1)
        poke(c.io.localFlitIn(src_node).header.isTail,1)
        poke(c.io.localFlitIn(src_node).header.xHops,NETWORK_SIZE-2)
        poke(c.io.localFlitIn(src_node).header.yHops,0)
        poke(c.io.localFlitIn(src_node).header.xDir,NORTH_INT)
        poke(c.io.localFlitIn(src_node).header.yDir,EAST_INT)
        poke(c.io.localFlitIn(src_node).header.outport,EAST_INT)
        poke(c.io.localFlitIn(src_node).header.vcid,0)

        for (node <- 0 until NETWORK_SIZE) {
            //poke(c.io.localIncCreditIn(node), c.io.localFlitOutValid(node))
            //poke(c.io.localIncCreditInVcid(node), c.io.localFlitOutVcid(node))
            flit_out_count(node) := flit_out_count(node) + c.io.localFlitOutValid(node).toUInt()
            flit_in_count(node) := flit_out_count(node) + c.io.localFlitInValid(node).toUInt()
        }
    }

    for (i <- 0 until cycles) {
        peek(c.io.localFlitOut(NETWORK_SIZE-1))
    }


}