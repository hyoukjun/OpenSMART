package SMART
import Chisel._

class CreditReg extends Module {
    val io = new Bundle {
        val inc = Bool(dir = INPUT)
        val dec = Bool(dir = INPUT) // if dec == 1, inc
        val creditOut = UInt(dir = OUTPUT, width = CREDIT_WIDTH)
    }
    
    val credit = Reg(init = UInt(INPUT_BUFFER_DEPTH))
    assert(credit <= UInt(INPUT_BUFFER_DEPTH), "credit value must not be greater than INPUT_BUFFER_DEPTH")

    when (io.dec) {
        when (io.inc) {
            io.creditOut := credit
        } .otherwise {
            assert(credit != UInt(0), "cannot decrement credit when value is 0")
            credit := credit - UInt(1)
            io.creditOut := credit - UInt(1)
        } 
    } .otherwise {
        when (io.inc) {
            credit := credit + UInt(1)
            io.creditOut := credit + UInt(1)
        } .otherwise {
            io.creditOut := credit
        }
    }
    io.creditOut := credit
}

class CreditRegTests(c: CreditReg) extends Tester(c) {
    peek(c.credit)
    poke(c.io.inc, 1)
    poke(c.io.dec, 1)
    peek(c.io.creditOut)
    step(1)

    peek(c.credit)
    poke(c.io.inc, 0)
    poke(c.io.dec, 1)
    peek(c.io.creditOut)
    step(1)

    peek(c.credit)
    poke(c.io.inc, 0)
    poke(c.io.dec, 1)
    peek(c.io.creditOut)
    step(1)

    peek(c.credit)
    poke(c.io.inc, 1)
    poke(c.io.dec, 0)
    peek(c.io.creditOut)
    step(1)
}