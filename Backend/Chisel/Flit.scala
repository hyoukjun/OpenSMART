package SMART

import Chisel._

class Flit extends Bundle {
    val header = new FlitHeader()
    val data = UInt(width = DATA_WIDTH)

    def init() : Unit = {
        this.data := UInt(0)
        this.header.init()
    }
}

// todo: implement head/body/tail/headtail flit types. now all flits carry routing info
class FlitHeader extends Bundle {
    val isHead = Bool()
    val isTail = Bool()

    // routing info
    val xHops = UInt(width = X_ADDR_WIDTH)
    val yHops = UInt(width = Y_ADDR_WIDTH)
    val xDir = UInt(width = 1)
    val yDir = UInt(width = 1)
    val outport = UInt(width = NUM_OF_DIRS)

    // vc info
    val vcid = UInt(width = VCID_WIDTH)


    def init(): Unit = {
        this.isHead := Bool(false)
        this.isTail := Bool(false)
        this.xHops := UInt(0)
        this.yHops := UInt(0)
        this.xDir := UInt(0)
        this.yDir := UInt(0)
        this.outport := UInt(0)
        this.vcid := UInt(0)
    }

}

class Coordinate extends Bundle {
    val x = UInt(width = X_ADDR_WIDTH)
    val y = UInt(width = Y_ADDR_WIDTH)
}