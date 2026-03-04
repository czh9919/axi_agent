import uvm_pkg::*;
`include "uvm_macros.svh"
import axi_lite_pkg::*;

class axi_lite_base_test extends uvm_test;
  `uvm_component_utils(axi_lite_base_test)

  axi_lite_env          m_env;
  axi_lite_config       m_master_cfg;
  axi_lite_config       m_slave_cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_env = axi_lite_env::type_id::create("m_env", this);

    // Master config
    m_master_cfg = axi_lite_config::type_id::create("m_master_cfg");
    m_master_cfg.is_active = UVM_ACTIVE;
    m_master_cfg.agent_name = "master";
    m_master_cfg.agent_id   = 0;
    uvm_config_db#(axi_lite_config)::set(this,
                                         "m_env.m_master_agt",
                                         "cfg",
                                         m_master_cfg);

    // Slave config
    m_slave_cfg = axi_lite_config::type_id::create("m_slave_cfg");
    m_slave_cfg.is_active = UVM_ACTIVE;
    m_slave_cfg.agent_name = "slave";
    m_slave_cfg.agent_id   = 0;
    uvm_config_db#(axi_lite_config)::set(this,
                                         "m_env.m_slave_agt",
                                         "cfg",
                                         m_slave_cfg);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi_lite_smoke_seq smoke;
    phase.raise_objection(this);

    // Run a smoke sequence on master sequencer
    smoke = axi_lite_smoke_seq::type_id::create("smoke");
    smoke.start(m_env.m_master_agt.seqr);

    #1000ns;
    phase.drop_objection(this);
  endtask
endclass

