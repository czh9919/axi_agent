// ------------------------------------------------------------
// Slave Agent (industrial-style, error response supported)
// ------------------------------------------------------------
class axi_lite_slave_agent extends uvm_agent;
  `uvm_component_utils(axi_lite_slave_agent)

  axi_lite_config         cfg;
  axi_lite_slave_sequencer seqr;
  axi_lite_slave_driver    drv;
  axi_lite_monitor         mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "axi_lite_config not found for slave agent")

    // For industrial-style slave, we usually run active to respond to master
    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = axi_lite_slave_sequencer::type_id::create("seqr", this);
      drv  = axi_lite_slave_driver   ::type_id::create("drv",  this);
      uvm_config_db#(axi_lite_config)::set(this, "drv", "cfg", cfg);
    end

    mon  = axi_lite_monitor::type_id::create("mon", this);
    uvm_config_db#(axi_lite_config)::set(this, "mon", "cfg", cfg);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass : axi_lite_slave_agent