import uvm_pkg::*;
`include "uvm_macros.svh"
import axi_lite_pkg::*;

class axi_lite_env extends uvm_env;
  `uvm_component_utils(axi_lite_env)

  axi_lite_master_agent m_master_agt;
  axi_lite_slave_agent  m_slave_agt;

  // Placeholders for multiple instances (e.g., several masters/slaves)
  // can be extended as arrays in future.

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_master_agt = axi_lite_master_agent::type_id::create("m_master_agt", this);
    m_slave_agt  = axi_lite_slave_agent ::type_id::create("m_slave_agt",  this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Scoreboard or subscriber can be connected to m_master_agt.mon.ap / m_slave_agt.mon.ap here.
  endfunction
endclass

