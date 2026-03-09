// ------------------------------------------------------------
// Master Sequencer
// ------------------------------------------------------------
class axi_lite_master_sequencer extends uvm_sequencer #(axi_lite_trans);
  `uvm_component_utils(axi_lite_master_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : axi_lite_master_sequencer