package SMART

import Chisel._

class Crossbar (NumInports: Int, NumOutports: Int) extends Module {
  val io = new Bundle {
    val flitIn = Vec.fill(NumInports) { new Flit().asInput }
    val grants = Vec.fill(NumOutports) { UInt(width = NumInports, dir = INPUT) }
    val flitOut = Vec.fill(NumOutports) { new Flit().asOutput }
    val outValid = Vec.fill(NumOutports) { Bool(dir = OUTPUT) }
  }
  // assert((NumInports == NumOutports), "Crossbar have different number of in/out ports")
  // assume "grants" signal is legal (one-hot)

  // initialize outputs to zeros
  io.flitOut := Vec.fill(NumOutports) { new Flit() }
  io.outValid := Vec.fill(NumOutports) {Bool(false)}

  for (i <- 0 until NumOutports) {
    for (j <- 0 until NumInports) {
        when (io.grants(i)(j).toBool()) {
            io.flitOut(i) := io.flitIn(j)
            io.outValid(i) := Bool(true)
        }
    }
  }
  // todo: make some assertions to check if "grants" signal is legal
}

class CrossbarTests(c: Crossbar) extends Tester(c) { 
  poke(c.io.flitIn(0).data, 0)
  poke(c.io.flitIn(1).data, 1)
  poke(c.io.flitIn(2).data, 2)
  poke(c.io.flitIn(3).data, 3)
  poke(c.io.flitIn(4).data, 4)

  poke(c.io.grants(0), 0x01)
  poke(c.io.grants(1), 0x02)
  poke(c.io.grants(2), 0x04)
  poke(c.io.grants(3), 0x08)
  poke(c.io.grants(4), 0x10)

  expect(c.io.flitOut(0).data, 0)
  expect(c.io.flitOut(1).data, 1)
  expect(c.io.flitOut(2).data, 2)
  expect(c.io.flitOut(3).data, 3)
  expect(c.io.flitOut(4).data, 4)

  expect(c.io.outValid(0), 1)
  expect(c.io.outValid(1), 1)
  expect(c.io.outValid(2), 1)
  expect(c.io.outValid(3), 1)
  expect(c.io.outValid(4), 1)

  step(1)
}