

/* Write Address Channel */
typedef 2 AWID_BITS;
typedef 10 AWADDR_BITS;
typedef 10 AWLEN_BITS;
typedef 10 AWSIZE_BITS;
typedef 4 AWBURST_BITS;
typedef 2 AWLOCK_BITS;
typedef 2 AWCACHE_BITS;
typedef 2 AWPROT_BITS;
typedef 2 AWQOS_BITS;
typedef 2 AWREGION_BITS;
typedef 4 AWUSER_BITS;

typedef Bit#(AWID_BITS) AWID;
typedef Bit#(AWADDR_BITS) AWADDR;
typedef Bit#(AWLEN_BITS) AWLEN;
typedef Bit#(AWSIZE_BITS) AWSIZE;
typedef Bit#(AWBURST_BITS) AWBURST;
typedef Bit#(AWLOCK_BITS) AWLOCK;
typedef Bit#(AWCACHE_BITS) AWCACHE;
typedef Bit#(AWPROT_BITS) AWPROT;
typedef Bit#(AWQOS_BITS) AWQOS;
typedef Bit#(AWREGION_BITS) AWREGION;
typedef Bit#(AWUSER_BITS) AWUSER;

typedef struct {
  AWID    awid;
  AWADDR  awaddr;
  AWLEN   awlen;
  AWSIZE awsize;
  AWBURST awburst;
  AWLOCK awlock;
  AWCACHE awcache;
  AWPROT awprot;
  AWQOS awqos;
  AWREGION awregion;
  AWUSER awuser;
} AXI_WriteAddr deriving(Bits, Eq);

/* Write Data Channel */

typedef 2 WID_BITS;
typedef 32 WDATA_BITS;
typedef TAdd#(1, TDiv#(WDATA_BITS, 8)) WSTRB_BITS;
typedef 1 WLAST_BITS;
typedef 4 WUSER_BITS;

typedef Bit#(WID_BITS) WID;
typedef Bit#(WDATA_BITS) WDATA;
typedef Bit#(WSTRB_BITS) WSTRB;
typedef Bit#(WLAST_BITS) WLAST;
typedef Bit#(WUSER_BITS) WUSER;


typedef struct {
  WID wid;
  WDATA wdata;
  WSTRB wstrb;
  WLAST wlast;
  WUSER wuser;
} AXI_WriteData deriving(Bits, Eq);

/* Write Response Channel */

typedef 2 BID_BITS;
typedef 1 BRESP_BITS;
typedef 4 BUSER_BITS;


typedef Bit#(BID_BITS) BID;
typedef Bit#(BRESP_BITS) BRESP;
typedef Bit#(BUSER_BITS) BUSER;

typedef struct {
  BID bid;
  BRESP bresp;
  BUSER buser;
} AXI_WriteResponse deriving (Bits, Eq);

/* Read Address Channel */

typedef 2 ARID_BITS;
typedef 8 ARADDR_BITS;
typedef 4 ARLEN_BITS;
typedef 4 ARSIZE_BITS;
typedef 6 ARBURST_BITS;
typedef 2 ARLOCK_BITS;
typedef 4 ARCACHE_BITS;
typedef 2 ARPROT_BITS;
typedef 2 ARQOS_BITS;
typedef 3 ARREGION_BITS;
typedef 4 ARUSER_BITS;

typedef Bit#(ARID_BITS) ARID;
typedef Bit#(ARADDR_BITS) ARADDR;
typedef Bit#(ARLEN_BITS) ARLEN;
typedef Bit#(ARSIZE_BITS) ARSIZE;
typedef Bit#(ARBURST_BITS) ARBURST;
typedef Bit#(ARLOCK_BITS) ARLOCK;
typedef Bit#(ARCACHE_BITS) ARCACHE;
typedef Bit#(ARPROT_BITS) ARPROT;
typedef Bit#(ARQOS_BITS) ARQOS;
typedef Bit#(ARREGION_BITS) ARREGION;
typedef Bit#(ARUSER_BITS) ARUSER;

typedef struct {
  ARID arid;
  ARADDR araddr;
  ARLEN arlen;
  ARSIZE arsize;
  ARBURST arburst;
  ARLOCK arlock;
  ARCACHE arcache;
  ARPROT arprot;
  ARQOS arqos;
  ARREGION arregion;
  ARUSER aruser;
} AXI_ReadAddress deriving (Bits, Eq);

/* Read Data Channel */

typedef 2 RID_BITS;
typedef 32 RDATA_BITS;
typedef 2 RRESP_BITS;
typedef 1 RLAST_BITS;
typedef 4 RUSER_BITS;

typedef Bit#(RID_BITS) RID;
typedef Bit#(RDATA_BITS) RDATA;
typedef Bit#(RRESP_BITS) RRESP;
typedef Bit#(RLAST_BITS) RLAST;
typedef Bit#(RUSER_BITS) RUSER;

typedef struct {
  RID rid;
  RDATA rdata;
  RRESP rresp;
  RLAST rlast;
  RUSER ruser;
} AXI_ReadData deriving (Bits, Eq);


