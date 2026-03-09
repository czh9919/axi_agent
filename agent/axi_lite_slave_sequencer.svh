// ------------------------------------------------------------
// Slave Sequencer (for programmable slave behavior)
// ------------------------------------------------------------
class axi_lite_slave_sequencer extends uvm_sequencer #(axi_lite_trans);
  `uvm_component_utils(axi_lite_slave_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : axi_lite_slave_sequencer