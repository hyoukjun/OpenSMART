package SMART

import Chisel._

object testProgram {
  def main(args: Array[String]): Unit = {
    val margs = 
      Array("--backend", "c", "--genHarness", "--compile", "--test") 
    chiselMainTest(margs, () => 
        Module(new Router())) { 
        c => new RouterTests(c) 
        }
  }
}