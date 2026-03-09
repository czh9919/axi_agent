// ------------------------------------------------------------
// Industrial-style protocol checker (assertion-like checks in SV code)
// ------------------------------------------------------------
class axi_lite_protocol_checker extends uvm_component;
  `uvm_component_utils(axi_lite_protocol_checker)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Basic handshake checks for write
  virtual task check_write_handshake(virtual axi_lite_if vif);
    // Here we just check that valid/ready were both high on clk edge,
    // more complex temporal checks can be added as SVA in future.
    if (!(vif.AWVALID && vif.AWREADY))
      `uvm_error(get_type_name(), "Write address handshake violation (AW)")
    if (!(vif.WVALID && vif.WREADY))
      `uvm_error(get_type_name(), "Write data handshake violation (W)")
    if (!(vif.BVALID && vif.BREADY))
      `uvm_error(get_type_name(), "Write response handshake violation (B)")
  endtask

  // Basic handshake checks for read
  virtual task check_read_handshake(virtual axi_lite_if vif);
    // if (!(vif.ARVALID && vif.ARREADY))
    //   `uvm_error(get_type_name(), "Read address handshake violation (AR)")
    if (!(vif.RVALID && vif.RREADY))
      `uvm_error(get_type_name(), "Read data handshake violation (R)")
  endtask
endclass : axi_lite_protocol_checker