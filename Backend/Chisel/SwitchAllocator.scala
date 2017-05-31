package SMART

import Chisel._

// A two stage switch allocator. 
// First stage picks a winner among all VCs of an inport,
// Second stage picks a winner among all inports
class SwitchAllocator(NumInports: Int, NumOutports: Int) extends Module {
    val io = new Bundle {
      val enable = UInt(width = 1, dir = INPUT)
      val requests  = Vec.fill(NumInports) { UInt(width = NumOutports, dir = INPUT) }
      val grants = Vec.fill(NumOutports) {UInt(width = NumInports, dir = OUTPUT)}
    }

    val inportArbiters = Vec.fill(NumInports) { Module(new MatrixArbiter(n=NumOutports)).io }
    val outportArbiters = Vec.fill(NumOutports) { Module(new MatrixArbiter(n=NumInports)).io }
    val middleRequests = Vec.fill(NumOutports) { Vec.fill(NumInports) { Bool() } }

    for (i <- 0 until NumInports) {
        inportArbiters(i).enable := io.enable
        inportArbiters(i).requests := io.requests(i)
        for (j <- 0 until NumOutports) {
          middleRequests(j)(i) := inportArbiters(i).grants(j)
        }
    }
    for (i <- 0 until NumOutports) {
      outportArbiters(i).enable := io.enable
      io.grants(i) := outportArbiters(i).grants
      outportArbiters(i).requests := (middleRequests(i)).toBits().toUInt()
    }

}

class MySA extends SwitchAllocator(NumInports = 4, NumOutports = 4)

class MySATests(c: MySA) extends Tester(c) {
  poke(c.io.enable, 1)
  for (j <- 0 until 4) {
    for (i <- 0 until 4) {
        poke(c.io.requests(i), 3 << i)
    }
    for (i <- 0 until 4) {
        peek(c.io.grants(i))
    }
    step(1)
  }

}