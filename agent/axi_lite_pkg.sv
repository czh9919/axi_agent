package axi_lite_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Basic parameters (can be overridden via type parameters if needed)
  parameter int AXI_LITE_ADDR_WIDTH = 32;
  parameter int AXI_LITE_DATA_WIDTH = 32;

  typedef enum {AXI_LITE_READ, AXI_LITE_WRITE} axi_lite_cmd_e;

  // Include class definitions
  `include "axi_lite_config.svh"
  `include "axi_lite_trans.svh"
  `include "axi_lite_master_sequencer.svh"
  `include "axi_lite_slave_sequencer.svh"
  `include "axi_lite_master_driver.svh"
  `include "axi_lite_slave_driver.svh"
  `include "axi_lite_protocol_checker.svh"
  `include "axi_lite_cov.svh"
  `include "axi_lite_monitor.svh"
  `include "axi_lite_master_agent.svh"
  `include "axi_lite_slave_agent.svh"

endpackage : axi_lite_pkg

