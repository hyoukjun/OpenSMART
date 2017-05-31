package SMART

import Chisel._

class MatrixArbiter(n: Int) extends Module {
  val io = new Bundle {
    val enable = UInt(width = 1, dir = INPUT)
    val requests  = UInt(width = n, dir = INPUT)
    val grants = UInt(width = n, dir = OUTPUT)
  }
  val requests = io.requests.toBools
  val grants = Vec.fill(n){ Bool() }
  val disables = Vec.fill(n){ Bool() }
  val priority = Vec.fill(n) { Vec.fill(n) {Reg(init = Bool(true))} }

  val disablesBits = Vec.fill(n) { Vec.fill(n) { Bool()} }
  for (i <- 0 until n) {
    for (j <- 0 until n) {
      if (j > i) {
        // if j sents a request, and p(j,i) = true, disable i.
        disablesBits(i)(j) := requests(j) && priority(j)(i)
      } else if (j < i) {
        // if j sends a request, and p(i,j) = false, disable i.
        disablesBits(i)(j) := requests(j) && !priority(i)(j)
      } else {
        disablesBits(i)(j) := Bool(false);
      }
    }
    disables(i) := orR(disablesBits(i).toBits())
    grants(i) := requests(i) && (!disables(i))
  }
  when (io.enable === UInt(1)) {
    for (i <- 0 until n) {
      // when req(i) is granted, set all p(x,i) to 1, and p(i,y) to 0.
      when (grants(i)) {
        for (j <- 0 until n) {
          if (j > i) {
            priority(j)(i) := Bool(true)
          } else if (j < i) {
            priority(i)(j) := Bool(false)
          }
        }
      }
    }
  }

  io.grants := grants.toBits().toUInt()
}

class MyMatrixArbiter extends MatrixArbiter(n = 5)

class MyMatrixArbiterTests(c: MyMatrixArbiter) extends Tester(c) { 

  val n = 5
  poke(c.io.enable, 1)
  poke(c.io.requests, 0x1F) // req 0 1 2 3

  expect(c.io.grants, 0x10) // grant 3
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
  for (i <- 0 until n) {
    for (j <- 0 until i) {
      peek(c.priority(i)(j))
    }
  }
  expect(c.io.grants, 1) // grant 3
  step(1)

  poke(c.io.enable, 1)
  poke(c.io.requests, 0xF) // req 0 1 2 3
  expect(c.io.grants, 8) // grant 3
  step(1)
}
