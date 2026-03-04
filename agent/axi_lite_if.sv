// AXI-Lite interface definition with modports for master/slave and monitor
interface axi_lite_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input  logic ACLK,
  input  logic ARESETn
);

  // Write address channel
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic                   AWVALID;
  logic                   AWREADY;

  // Write data channel
  logic [DATA_WIDTH-1:0] WDATA;
  logic [(DATA_WIDTH/8)-1:0] WSTRB;
  logic                   WVALID;
  logic                   WREADY;

  // Write response channel
  logic [1:0]             BRESP;
  logic                   BVALID;
  logic                   BREADY;

  // Read address channel
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic                   ARVALID;
  logic                   ARREADY;

  // Read data channel
  logic [DATA_WIDTH-1:0] RDATA;
  logic [1:0]             RRESP;
  logic                   RVALID;
  logic                   RREADY;

  // Master modport
  modport master (
    input  ACLK, ARESETn,
    output AWADDR, AWVALID,
    input  AWREADY,
    output WDATA, WSTRB, WVALID,
    input  WREADY,
    input  BRESP, BVALID,
    output BREADY,
    output ARADDR, ARVALID,
    input  ARREADY,
    input  RDATA, RRESP, RVALID,
    output RREADY
  );

  // Slave modport
  modport slave (
    input  ACLK, ARESETn,
    input  AWADDR, AWVALID,
    output AWREADY,
    input  WDATA, WSTRB, WVALID,
    output WREADY,
    output BRESP, BVALID,
    input  BREADY,
    input  ARADDR, ARVALID,
    output ARREADY,
    output RDATA, RRESP, RVALID,
    input  RREADY
  );

  // Monitor modport (all signals input)
  modport monitor (
    input ACLK, ARESETn,
    input AWADDR, AWVALID, AWREADY,
    input WDATA, WSTRB, WVALID, WREADY,
    input BRESP, BVALID, BREADY,
    input ARADDR, ARVALID, ARREADY,
    input RDATA, RRESP, RVALID, RREADY
  );

endinterface : axi_lite_if

