// ------------------------------------------------------------
// Configuration object
// ------------------------------------------------------------
class axi_lite_config extends uvm_object;
  `uvm_object_utils(axi_lite_config)

  // Active / passive
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Virtual interface handle (master modport for master agent, slave for slave agent)
  virtual interface axi_lite_if #(AXI_LITE_ADDR_WIDTH, AXI_LITE_DATA_WIDTH) vif;

  // Allow multiple instances by ID
  string agent_name;
  int    agent_id;

  // Protocol check enable
  bit enable_protocol_check = 1;

  // Future extension: full AXI options reserved
  bit enable_burst      = 0;
  bit enable_prot_bits  = 0;

  function new(string name="axi_lite_config");
    super.new(name);
    uvm_config_db#(virtual axi_lite_if#(AXI_LITE_ADDR_WIDTH,AXI_LITE_DATA_WIDTH))::get(
      null, "uvm_test_top.m_env.m_master_agt", "vif", vif);
  endfunction
endclass : axi_lite_config