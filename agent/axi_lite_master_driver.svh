// ------------------------------------------------------------
// Master Driver
// ------------------------------------------------------------
class axi_lite_master_driver extends uvm_driver #(axi_lite_trans);
  `uvm_component_utils(axi_lite_master_driver)

  axi_lite_config m_cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", m_cfg))
      `uvm_fatal(get_type_name(), "axi_lite_config not found for master driver")
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_trans tr;
    forever begin
      seq_item_port.get_next_item(tr);
      if (tr.cmd == AXI_LITE_WRITE)
        drive_write(tr);
      else
        drive_read(tr);
      seq_item_port.item_done();
    end
  endtask

  task drive_write(axi_lite_trans tr);
    // Wait for reset deassertion
    while(m_cfg.vif.ARESETn == 0)
        @(posedge m_cfg.vif.ACLK);

    // Simple single-beat write
    @(posedge m_cfg.vif.ACLK);
    // Address and data can be driven in parallel for AXI-Lite
    m_cfg.vif.AWADDR  <= tr.addr;
    m_cfg.vif.AWVALID <= 1'b1;
    m_cfg.vif.WDATA   <= tr.data;
    m_cfg.vif.WSTRB   <= tr.strb;
    m_cfg.vif.WVALID  <= 1'b1;
    // Handshake
    do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.AWREADY);
    m_cfg.vif.AWVALID <= 1'b0;

    do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.WREADY);
    m_cfg.vif.WVALID <= 1'b0;

    // Wait for response
    m_cfg.vif.BREADY <= 1'b1;
    do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.BVALID);
    tr.resp = m_cfg.vif.BRESP;
    m_cfg.vif.BREADY <= 1'b0;
  endtask

  task drive_read(axi_lite_trans tr);
    @(posedge m_cfg.vif.ACLK);
    m_cfg.vif.ARADDR  <= tr.addr;
    m_cfg.vif.ARVALID <= 1'b1;
    // Address handshake
    do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.ARREADY);
    m_cfg.vif.ARVALID <= 1'b0;

    // Data phase
    m_cfg.vif.RREADY <= 1'b1;
    do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.RVALID);
    tr.data = m_cfg.vif.RDATA;
    tr.resp = m_cfg.vif.RRESP;
    m_cfg.vif.RREADY <= 1'b0;
  endtask
endclass : axi_lite_master_driver