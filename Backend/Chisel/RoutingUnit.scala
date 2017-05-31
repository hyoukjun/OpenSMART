package SMART
import Chisel._

// Implementing the XY Routing Unit
class RoutingUnit() extends Module {
    val io = new Bundle {
        val xHops = UInt(INPUT, width = X_HOP_WIDTH)
        val yHops = UInt(INPUT, width = Y_HOP_WIDTH)
        val xDir = UInt(INPUT, width = 1)
        val yDir = UInt(INPUT, width = 1)

        val outport = UInt(OUTPUT, width = NUM_OF_DIRS)

        val xHopsNext = UInt(OUTPUT, width = X_HOP_WIDTH)
        val yHopsNext = UInt(OUTPUT, width = Y_HOP_WIDTH)
        val xDirNext = UInt(OUTPUT, width = 1)
        val yDirNext = UInt(OUTPUT, width = 1)
    }

    when (io.xHops =/= UInt(0)) {
        io.xHopsNext := io.xHops - UInt(1)
        io.yHopsNext := io.yHops
        when (io.xDir === UInt(1)) {
            io.outport := EAST_OH
        } .otherwise {
            io.outport := WEST_OH
        }
    } .elsewhen (io.yHops =/= UInt(0)) {
        io.xHopsNext := io.xHops
        io.yHopsNext := io.yHops - UInt(1)
        when (io.yDir === UInt(1)) {
            io.outport := NORTH_OH
        } .otherwise {
            io.outport := SOUTH_OH
        }
    } .otherwise {
        io.outport := LOCAL_OH
        io.xHopsNext := io.xHops
        io.yHopsNext := io.yHops
    }
    io.yDirNext := io.yDir
    io.xDirNext := io.xDir
}

class RoutingUnitTests(c: RoutingUnit) extends Tester(c) {
    poke(c.io.xHops, 3)
    poke(c.io.yHops, 3)
    poke(c.io.xDir, 0)
    poke(c.io.yDir, 1)
    expect(c.io.xHopsNext, 2)
    expect(c.io.yHopsNext, 3)
    expect(c.io.outport, WEST_OH.litValue())

step(1)
    poke(c.io.xHops, 2)
    poke(c.io.yHops, 2)
    poke(c.io.xDir, 1)
    poke(c.io.yDir, 1)
    peek(c.io)
step(1)
    poke(c.io.xHops, 0)
    poke(c.io.yHops, 2)
    poke(c.io.xDir, 1)
    poke(c.io.yDir, 1)
    peek(c.io)
    step(1)
}



// class RoutingUnit() extends Module {
//     val io = new Bundle {
//         val curCoord = new Coordinate().asInput
//         val destCoord = new Coordinate().asInput
//         val outDir = UInt(dir = OUTPUT, width = NUM_OF_DIRS)
//     }
//     when (io.curCoord.x != io.destCoord.x) {
//         when (io.curCoord.x > io.destCoord.x) {
//             io.outDir := WEST_OH
//         } .otherwise {
//             io.outDir := EAST_OH
//         }
//     } .elsewhen (io.curCoord.y != io.destCoord.y) {
//         when (io.curCoord.y > io.destCoord.y) {
//             io.outDir := SOUTH_OH
//         } .otherwise {
//             io.outDir := NORTH_OH
//         }
//     } .otherwise {
//         io.outDir := LOCAL_OH
//     }
// }

// class RoutingUnitTests(c: RoutingUnit) extends Tester(c) {
//     poke(c.io.curCoord.x, 0)
//     poke(c.io.curCoord.y, 0)
//     poke(c.io.destCoord.x, 0)
//     poke(c.io.destCoord.y, 0)
//     expect(c.io.outDir, 1)

//     poke(c.io.curCoord.x, 0)
//     poke(c.io.curCoord.y, 0)
//     poke(c.io.destCoord.x, 0)
//     poke(c.io.destCoord.y, 1)
//     peek(c.io.outDir)

//     poke(c.io.curCoord.x, 0)
//     poke(c.io.curCoord.y, 0)
//     poke(c.io.destCoord.x, 1)
//     poke(c.io.destCoord.y, 0)
//     peek(c.io.outDir)

//     poke(c.io.curCoord.x, 0)
//     poke(c.io.curCoord.y, 0)
//     poke(c.io.destCoord.x, 1)
//     poke(c.io.destCoord.y, 1)
//     peek(c.io.outDir)

//     poke(c.io.curCoord.x, 1)
//     poke(c.io.curCoord.y, 1)
//     poke(c.io.destCoord.x, 0)
//     poke(c.io.destCoord.y, 0)
//     peek(c.io.outDir)
// }
// }