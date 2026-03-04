`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import axi_lite_pkg::*;

module top_tb;

  // Clock and reset
  logic ACLK;
  logic ARESETn;

  // AXI-Lite interface instance
  axi_lite_if #(
    .ADDR_WIDTH(AXI_LITE_ADDR_WIDTH),
    .DATA_WIDTH(AXI_LITE_DATA_WIDTH)
  ) axi_if (
    .ACLK   (ACLK),
    .ARESETn(ARESETn)
  );

  // DUT instances: master & slave
  axi_lite_master #(
    .ADDR_WIDTH(AXI_LITE_ADDR_WIDTH),
    .DATA_WIDTH(AXI_LITE_DATA_WIDTH)
  ) u_master (
    .ACLK   (ACLK),
    .ARESETn(ARESETn),
    .AWADDR (axi_if.AWADDR),
    .AWVALID(axi_if.AWVALID),
    .AWREADY(axi_if.AWREADY),
    .WDATA  (axi_if.WDATA),
    .WSTRB  (axi_if.WSTRB),
    .WVALID (axi_if.WVALID),
    .WREADY (axi_if.WREADY),
    .BRESP  (axi_if.BRESP),
    .BVALID (axi_if.BVALID),
    .BREADY (axi_if.BREADY),
    .ARADDR (axi_if.ARADDR),
    .ARVALID(axi_if.ARVALID),
    .ARREADY(axi_if.ARREADY),
    .RDATA  (axi_if.RDATA),
    .RRESP  (axi_if.RRESP),
    .RVALID (axi_if.RVALID),
    .RREADY (axi_if.RREADY)
  );

  axi_lite_slave #(
    .ADDR_WIDTH(AXI_LITE_ADDR_WIDTH),
    .DATA_WIDTH(AXI_LITE_DATA_WIDTH)
  ) u_slave (
    .ACLK   (ACLK),
    .ARESETn(ARESETn),
    .AWADDR (axi_if.AWADDR),
    .AWVALID(axi_if.AWVALID),
    .AWREADY(axi_if.AWREADY),
    .WDATA  (axi_if.WDATA),
    .WSTRB  (axi_if.WSTRB),
    .WVALID (axi_if.WVALID),
    .WREADY (axi_if.WREADY),
    .BRESP  (axi_if.BRESP),
    .BVALID (axi_if.BVALID),
    .BREADY (axi_if.BREADY),
    .ARADDR (axi_if.ARADDR),
    .ARVALID(axi_if.ARVALID),
    .ARREADY(axi_if.ARREADY),
    .RDATA  (axi_if.RDATA),
    .RRESP  (axi_if.RRESP),
    .RVALID (axi_if.RVALID),
    .RREADY (axi_if.RREADY)
  );

  // Clock generation
  initial begin
    ACLK = 0;
    forever #5ns ACLK = ~ACLK;
  end

  // Reset sequence
  initial begin
    ARESETn = 0;
    #50ns;
    ARESETn = 1;
  end

  // Connect virtual interfaces
  initial begin
    // Master agent uses master modport
    virtual axi_lite_if #(AXI_LITE_ADDR_WIDTH, AXI_LITE_DATA_WIDTH) m_vif = axi_if;
    virtual axi_lite_if #(AXI_LITE_ADDR_WIDTH, AXI_LITE_DATA_WIDTH) s_vif = axi_if;

    // For multiple instances, you can set them with different paths and configs
    uvm_config_db#(virtual axi_lite_if#(AXI_LITE_ADDR_WIDTH,AXI_LITE_DATA_WIDTH))::set(
      null, "uvm_test_top.m_env.m_master_agt", "vif", m_vif);
    uvm_config_db#(virtual axi_lite_if#(AXI_LITE_ADDR_WIDTH,AXI_LITE_DATA_WIDTH))::set(
      null, "uvm_test_top.m_env.m_slave_agt", "vif", s_vif);
  end

  // Run UVM test
  initial begin
    run_test("axi_lite_base_test");
  end

endmodule

