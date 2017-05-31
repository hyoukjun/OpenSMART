package SMART

import Chisel._

class MatrixArbiter3 extends Module {
  val io = new Bundle {
    val enable = UInt(width = 1, dir = INPUT)
    val requests  = UInt(width = 3, dir = INPUT)
    val grants = UInt(width = 3, dir = OUTPUT)

  }
  val requests = io.requests.toBools
  val grants = Vec.fill(3){ Bool() }
  val disables = Vec.fill(3){ Bool() }

  val p10 = Reg(init = Bool(true))
  val p20 = Reg(init = Bool(true))
  val p21 = Reg(init = Bool(true))

  disables(0) := (requests(1) && p10) || (requests(2) && p20)
  disables(1) := (requests(0) && (!p10)) || (requests(2) && p21)
  disables(2) := (requests(0) && (!p20)) || (requests(1) && (!p21))

  grants(0) := requests(0) && (!disables(0))
  grants(1) := requests(1) && (!disables(1))
  grants(2) := requests(2) && (!disables(2))
  when (io.enable === UInt(1)) {
    when (grants(0)) {
      p20 := UInt(1)
      p10 := UInt(1)
    } .elsewhen (grants(1)) {
      p10 := UInt(0)
      p21 := UInt(1)
    } .elsewhen (grants(2)) {
      p21 := UInt(0)
      p20 := UInt(0)
    }
  }

  io.grants := grants.toBits().toUInt()
}

class MatrixArbiter3Tests(c: MatrixArbiter3) extends Tester(c) { 
  val req = 3

  poke(c.io.enable, 1)
  poke(c.io.requests, 7) // req 0 1 2
  expect(c.io.grants, 4) // grant 2
  step(1)


  poke(c.io.enable, 1)
  poke(c.io.requests, 7) // req 0 1 2
  step(1)
  expect(c.io.grants, 2) // grant 1

  poke(c.io.enable, 1)
  poke(c.io.requests, 7) // req 0 1 2
  step(1)
  expect(c.io.grants, 1) // grant 0

  poke(c.io.enable, 1)
  poke(c.io.requests, 4) // req 0 1 2
  step(1)
  expect(c.io.grants, 4) // grant 2

  poke(c.io.enable, 1)
  poke(c.io.requests, 2) // req 0 1 2
  step(1)
  expect(c.io.grants, 2) // grant 1

  poke(c.io.enable, 1)
  poke(c.io.requests, 1) // req 0 1 2
  step(1)
  expect(c.io.grants, 1) // grant 0
}