// Simple synthesizable AXI-Lite master RTL
module axi_lite_master #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input  logic ACLK,
  input  logic ARESETn,

  // AXI-Lite write address channel
  output logic [ADDR_WIDTH-1:0] AWADDR,
  output logic                   AWVALID,
  input  logic                   AWREADY,

  // AXI-Lite write data channel
  output logic [DATA_WIDTH-1:0] WDATA,
  output logic [(DATA_WIDTH/8)-1:0] WSTRB,
  output logic                   WVALID,
  input  logic                   WREADY,

  // AXI-Lite write response channel
  input  logic [1:0]             BRESP,
  input  logic                   BVALID,
  output logic                   BREADY,

  // AXI-Lite read address channel
  output logic [ADDR_WIDTH-1:0] ARADDR,
  output logic                   ARVALID,
  input  logic                   ARREADY,

  // AXI-Lite read data channel
  input  logic [DATA_WIDTH-1:0] RDATA,
  input  logic [1:0]             RRESP,
  input  logic                   RVALID,
  output logic                   RREADY
);

  // For this demo master, we simply idle and let UVM driver drive the bus via interface,
  // so this module is essentially a pass-through shell.
  // In an SoC scenario, this would be replaced by a real CPU or master IP.

  // Tie-offs (UVM side will drive via interface, so these are unused)
  assign AWADDR  = '0;
  assign AWVALID = 1'b0;
  assign WDATA   = '0;
  assign WSTRB   = '0;
  assign WVALID  = 1'b0;
  assign BREADY  = 1'b0;
  assign ARADDR  = '0;
  assign ARVALID = 1'b0;
  assign RREADY  = 1'b0;

endmodule

