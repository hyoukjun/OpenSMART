package SMART
import Chisel._

class FlitQueue extends Module {
    val io = new QueueIO(new Flit(), 2)
    val q = Module(new Queue(new Flit(), 2))
    q.io.enq <> io.enq
    io.deq <> q.io.deq
}
class QueueTest(c: FlitQueue) extends Tester(c) {
    for (i <- 0 until 10) {
        poke(c.io.enq.valid, true)
        poke(c.io.deq.ready, 1)
        poke(c.io.enq.bits.data, i)
        peek(c.io.enq.ready)
        peek(c.io.deq.valid)
        peek(c.io.deq.bits)
        step(1)
    }

}