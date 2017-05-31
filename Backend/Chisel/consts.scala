package SMART

package constants {

import Chisel._

trait SMARTConstants {
    // val LINK_WIDTH = 128
    val NETWORK_SIZE = 2
    
    val MAX_X = 4
    val MAX_Y = 4
    val NUM_OF_VC = 2
    val NUM_OF_VNET = 1
    assert(isPow2(MAX_X))
    assert(isPow2(MAX_Y))
    assert(isPow2(NUM_OF_VC))
    val X_ADDR_WIDTH = log2Up(MAX_X)
    val Y_ADDR_WIDTH = log2Up(MAX_Y)
    val X_HOP_WIDTH = X_ADDR_WIDTH + 1
    val Y_HOP_WIDTH = Y_ADDR_WIDTH + 1 
    val VCID_WIDTH = log2Up(NUM_OF_VC)
    val VNET_WIDTH = log2Up(NUM_OF_VNET)

    val FLIT_HEADER_WIDTH = (new FlitHeader()).getWidth
    // val DATA_WIDTH = LINK_WIDTH - FLIT_HEADER_WIDTH
    val DATA_WIDTH = 128

    val NUM_OF_DIRS = 5
    val DIRS_BITS_WIDTH = 3
    
    // Credit Management
    val INPUT_BUFFER_DEPTH = 4
    val CREDIT_WIDTH = log2Up(INPUT_BUFFER_DEPTH)+1 // because need to represent value "INPUT_BUFFER_DEPTH"


    //val N_::S_::W_::E_::L_::Nil = Enum(UInt())

    // definition of directions, OH means one-hot encoding
    val NORTH_OH = UInt("b10000")
    val EAST_OH = UInt("b01000")
    val SOUTH_OH = UInt("b00100")
    val WEST_OH = UInt("b00010")
    val LOCAL_OH = UInt("b00001")

    val NORTH_ = OHToUInt(UInt("b10000"))
    val EAST_ = OHToUInt(UInt("b01000"))
    val SOUTH_ = OHToUInt(UInt("b00100"))
    val WEST_ = OHToUInt(UInt("b00010"))
    val LOCAL_ = OHToUInt(UInt("b00002"))

    val NORTH_INT = OHToUInt(UInt("b10000")).litValue()
    val EAST_INT = OHToUInt(UInt("b01000")).litValue()
    val SOUTH_INT = OHToUInt(UInt("b00100")).litValue()
    val WEST_INT = OHToUInt(UInt("b00010")).litValue()
    val LOCAL_INT = OHToUInt(UInt("b00002")).litValue()

}

}

