package SMART

import Chisel._

class MatrixArbiter4 extends Module {
  val io = new Bundle {
    val enable = UInt(width = 1, dir = INPUT)
    val requests  = UInt(width = 4, dir = INPUT)
    val grants = UInt(width = 4, dir = OUTPUT)
  }
  val requests = io.requests.toBools
  val grants = Vec.fill(4){ Bool() }
  val disables = Vec.fill(4){ Bool() }

  val p10 = Reg(init = Bool(true))
  val p20 = Reg(init = Bool(true))
  val p30 = Reg(init = Bool(true))
  val p31 = Reg(init = Bool(true))
  val p21 = Reg(init = Bool(true))
  val p32 = Reg(init = Bool(true))

  disables(0) := (requests(1) && p10) || (requests(2) && p20) || (requests(3) && p30)
  disables(1) := (requests(0) && (!p10)) || (requests(2) && p21) || (requests(3) && p31)
  disables(2) := (requests(0) && (!p20)) || (requests(1) && (!p21)) || (requests(3) && p32)
  disables(3) := (requests(0) && (!p30)) || (requests(1) && (!p31)) || (requests(2) && (!p32))

  grants(0) := requests(0) && (!disables(0))
  grants(1) := requests(1) && (!disables(1))
  grants(2) := requests(2) && (!disables(2))
  grants(3) := requests(3) && (!disables(3))

  when (io.enable === UInt(1)) {
    when (grants(0)) {
      p30 := UInt(1)
      p20 := UInt(1)
      p10 := UInt(1)
    } .elsewhen (grants(1)) {
      p10 := UInt(0)
      p21 := UInt(1)
      p31 := UInt(1)
    } .elsewhen (grants(2)) {
      p32 := UInt(1)
      p21 := UInt(0)
      p20 := UInt(0)
    } .elsewhen (grants(3)) {
      p32 := UInt(0)
      p31 := UInt(0)
      p30 := UInt(0)
    }
  }

  io.grants := grants.toBits().toUInt()
}

class MatrixArbiter4Tests(c: MatrixArbiter4) extends Tester(c) { 
  val req = 3

  poke(c.io.enable, 1)
  poke(c.io.requests, 0xF) // req 0 1 2 3
  expect(c.io.grants, 8) // grant 3
  step(1)

  poke(c.io.enable, 1)
  poke(c.io.requests, 0xF) // req 0 1 2 3
  expect(c.io.grants, 4) // grant 3
  step(1)

  poke(c.io.enable, 1)
  poke(c.io.requests, 0xF) // req 0 1 2 3
  expect(c.io.grants, 2) // grant 3
  step(1)

  poke(c.io.enable, 1)
  poke(c.io.requests, 0xF) // req 0 1 2 3
  expect(c.io.grants, 1) // grant 3
  step(1)

  poke(c.io.enable, 1)
  poke(c.io.requests, 0xF) // req 0 1 2 3
  expect(c.io.grants, 8) // grant 3
  step(1)
}
